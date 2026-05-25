import { Logger } from '@aws-lambda-powertools/logger';
import { Tracer } from '@aws-lambda-powertools/tracer';
import { Metrics, MetricUnit } from '@aws-lambda-powertools/metrics';
import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, UpdateCommand } from '@aws-sdk/lib-dynamodb';
import { createHash, createHmac } from 'crypto';
import type { MSKEvent } from 'aws-lambda';

const SERVICE_NAME = 'results-dispatcher';

const logger = new Logger({ serviceName: SERVICE_NAME });
const tracer = new Tracer({ serviceName: SERVICE_NAME });
const metrics = new Metrics({ namespace: 'GalaxyMorph', serviceName: SERVICE_NAME });

const ddbClient = tracer.captureAWSv3Client(new DynamoDBClient({}));
const ddb = DynamoDBDocumentClient.from(ddbClient);

const JOBS_TABLE = process.env.JOBS_TABLE_NAME!;
const APPSYNC_URL = process.env.APPSYNC_GRAPHQL_URL!;
const AWS_REGION = process.env.AWS_REGION!;

interface Classification {
  predictedClass: string;
  confidence: number;
  probabilities: Record<string, number>;
}

interface KafkaResultMessage {
  jobId: string;
  clientId: string;
  imageKey: string;
  status: 'SUCCESS' | 'FAILED';
  classification?: Classification;
  errorMessage?: string;
}

function sha256Hex(data: string): string {
  return createHash('sha256').update(data, 'utf8').digest('hex');
}

function hmacSha256(key: Buffer | string, data: string): Buffer {
  return createHmac('sha256', key).update(data, 'utf8').digest();
}

function buildSigningKey(secretKey: string, date: string, region: string, service: string): Buffer {
  const kDate = hmacSha256(`AWS4${secretKey}`, date);
  const kRegion = hmacSha256(kDate, region);
  const kService = hmacSha256(kRegion, service);
  return hmacSha256(kService, 'aws4_request');
}

function signAppSyncRequest(
  hostname: string,
  pathname: string,
  body: string,
  credentials: { accessKeyId: string; secretAccessKey: string; sessionToken?: string },
  region: string,
): Record<string, string> {
  const now = new Date();
  const amzDate = now.toISOString().replace(/[:-]/g, '').replace(/\.\d{3}/, '');
  const dateStamp = amzDate.slice(0, 8);
  const contentType = 'application/json';
  const service = 'appsync';

  const canonicalHeaders =
    `content-type:${contentType}\n` +
    `host:${hostname}\n` +
    `x-amz-date:${amzDate}\n` +
    (credentials.sessionToken ? `x-amz-security-token:${credentials.sessionToken}\n` : '');

  const signedHeaders =
    'content-type;host;x-amz-date' +
    (credentials.sessionToken ? ';x-amz-security-token' : '');

  const payloadHash = sha256Hex(body);
  const canonicalRequest = [
    'POST',
    pathname,
    '',
    canonicalHeaders,
    signedHeaders,
    payloadHash,
  ].join('\n');

  const credentialScope = `${dateStamp}/${region}/${service}/aws4_request`;
  const stringToSign = [
    'AWS4-HMAC-SHA256',
    amzDate,
    credentialScope,
    sha256Hex(canonicalRequest),
  ].join('\n');

  const signingKey = buildSigningKey(credentials.secretAccessKey, dateStamp, region, service);
  const signature = createHmac('sha256', signingKey).update(stringToSign, 'utf8').digest('hex');

  const authHeader =
    `AWS4-HMAC-SHA256 Credential=${credentials.accessKeyId}/${credentialScope}, ` +
    `SignedHeaders=${signedHeaders}, Signature=${signature}`;

  const headers: Record<string, string> = {
    'content-type': contentType,
    host: hostname,
    'x-amz-date': amzDate,
    authorization: authHeader,
  };
  if (credentials.sessionToken) {
    headers['x-amz-security-token'] = credentials.sessionToken;
  }
  return headers;
}

async function callAppSyncMutation(message: KafkaResultMessage): Promise<void> {
  const mutation = `
    mutation NotifyClassification($input: ClassificationResultInput!) {
      notifyClassification(input: $input) {
        jobId
        clientId
        imageKey
        status
        classification {
          predictedClass
          confidence
          probabilities
        }
        errorMessage
      }
    }
  `;

  const variables = {
    input: {
      jobId: message.jobId,
      clientId: message.clientId,
      imageKey: message.imageKey,
      status: message.status,
      ...(message.classification && {
        classification: {
          predictedClass: message.classification.predictedClass,
          confidence: message.classification.confidence,
          probabilities: JSON.stringify(message.classification.probabilities),
        },
      }),
      ...(message.errorMessage && { errorMessage: message.errorMessage }),
    },
  };

  const body = JSON.stringify({ query: mutation, variables });
  const url = new URL(APPSYNC_URL);

  const credentials = {
    accessKeyId: process.env.AWS_ACCESS_KEY_ID!,
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY!,
    sessionToken: process.env.AWS_SESSION_TOKEN,
  };

  const headers = signAppSyncRequest(url.hostname, url.pathname, body, credentials, AWS_REGION);

  const response = await fetch(APPSYNC_URL, {
    method: 'POST',
    headers,
    body,
  });

  if (!response.ok) {
    const text = await response.text();
    throw new Error(`AppSync mutation failed: ${response.status} ${text}`);
  }

  const json = (await response.json()) as { errors?: Array<{ message: string }> };
  if (json.errors && json.errors.length > 0) {
    throw new Error(`AppSync errors: ${json.errors.map((e) => e.message).join(', ')}`);
  }
}

async function updateJobProgress(
  jobId: string,
  status: 'SUCCESS' | 'FAILED',
): Promise<void> {
  const result = await ddb.send(
    new UpdateCommand({
      TableName: JOBS_TABLE,
      Key: { pk: `job#${jobId}`, sk: 'metadata' },
      UpdateExpression:
        'SET processedCount = if_not_exists(processedCount, :zero) + :one, #updatedAt = :now',
      ExpressionAttributeNames: { '#updatedAt': 'updatedAt' },
      ExpressionAttributeValues: {
        ':one': 1,
        ':zero': 0,
        ':now': new Date().toISOString(),
      },
      ReturnValues: 'ALL_NEW',
    }),
  );

  const item = result.Attributes;
  if (!item) return;

  const processedCount: number = item['processedCount'] as number;
  const imageCount: number = item['imageCount'] as number;

  if (processedCount >= imageCount) {
    await ddb.send(
      new UpdateCommand({
        TableName: JOBS_TABLE,
        Key: { pk: `job#${jobId}`, sk: 'metadata' },
        UpdateExpression: 'SET #status = :completed, completedAt = :now',
        ConditionExpression: '#status <> :completed',
        ExpressionAttributeNames: { '#status': 'status' },
        ExpressionAttributeValues: {
          ':completed': 'COMPLETED',
          ':now': new Date().toISOString(),
        },
      }),
    ).catch((err) => {
      if ((err as Error).name !== 'ConditionalCheckFailedException') {
        throw err;
      }
    });
  }
}

export const handler = async (event: MSKEvent): Promise<void> => {
  logger.info('MSK event received', { topicCount: Object.keys(event.records).length });

  const allMessages: KafkaResultMessage[] = [];

  for (const [_topicPartition, records] of Object.entries(event.records)) {
    for (const record of records) {
      try {
        const decoded = Buffer.from(record.value, 'base64').toString('utf-8');
        const message = JSON.parse(decoded) as KafkaResultMessage;
        allMessages.push(message);
      } catch (err) {
        logger.error('Failed to decode Kafka record', {
          offset: record.offset,
          error: err,
        });
        metrics.addMetric('DecodeError', MetricUnit.Count, 1);
      }
    }
  }

  logger.info('Processing messages', { count: allMessages.length });

  const results = await Promise.allSettled(
    allMessages.map(async (message) => {
      logger.appendKeys({ jobId: message.jobId, imageKey: message.imageKey });

      await callAppSyncMutation(message);
      await updateJobProgress(message.jobId, message.status);

      metrics.addMetric('MessageProcessed', MetricUnit.Count, 1);
      logger.info('Message dispatched', { clientId: message.clientId, status: message.status });
    }),
  );

  const failures = results.filter((r) => r.status === 'rejected');
  if (failures.length > 0) {
    metrics.addMetric('DispatchError', MetricUnit.Count, failures.length);
    failures.forEach((f) =>
      logger.error('Message dispatch failed', {
        reason: (f as PromiseRejectedResult).reason,
      }),
    );
    throw new Error(`${failures.length}/${allMessages.length} messages failed to dispatch`);
  }

  metrics.publishStoredMetrics();
};
