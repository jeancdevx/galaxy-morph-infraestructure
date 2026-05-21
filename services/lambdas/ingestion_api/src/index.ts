import { Logger } from '@aws-lambda-powertools/logger';
import { Tracer } from '@aws-lambda-powertools/tracer';
import { Metrics, MetricUnit } from '@aws-lambda-powertools/metrics';
import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, UpdateCommand, PutCommand } from '@aws-sdk/lib-dynamodb';
import { SQSClient, SendMessageBatchCommand } from '@aws-sdk/client-sqs';
import type { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { randomUUID } from 'crypto';

const SERVICE_NAME = 'ingestion-api';

const logger = new Logger({ serviceName: SERVICE_NAME });
const tracer = new Tracer({ serviceName: SERVICE_NAME });
const metrics = new Metrics({ namespace: 'GalaxyMorph', serviceName: SERVICE_NAME });

const ddbClient = tracer.captureAWSv3Client(new DynamoDBClient({}));
const ddb = DynamoDBDocumentClient.from(ddbClient);
const sqs = tracer.captureAWSv3Client(new SQSClient({}));

const JOBS_TABLE = process.env.JOBS_TABLE_NAME!;
const QUEUE_URL = process.env.INGESTION_QUEUE_URL!;
const MAX_PUBLIC_IMAGES_PER_DAY = 10;
const SQS_BATCH_SIZE = 10;

interface ImageRef {
  key: string;
}

function jsonResponse(statusCode: number, body: unknown): APIGatewayProxyResult {
  return {
    statusCode,
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  };
}

function endOfDayTtlSeconds(): number {
  const now = new Date();
  const endOfDay = new Date(
    Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate(), 23, 59, 59, 999),
  );
  return Math.floor(endOfDay.getTime() / 1000);
}

function chunk<T>(arr: T[], size: number): T[][] {
  const chunks: T[][] = [];
  for (let i = 0; i < arr.length; i += size) {
    chunks.push(arr.slice(i, i + size));
  }
  return chunks;
}

async function checkAndIncrementQuota(userId: string, imageCount: number): Promise<boolean> {
  const remaining = MAX_PUBLIC_IMAGES_PER_DAY - imageCount;

  if (remaining < 0) {
    // imageCount alone exceeds the limit
    return false;
  }

  try {
    await ddb.send(
      new UpdateCommand({
        TableName: JOBS_TABLE,
        Key: { pk: `quota#${userId}`, sk: 'DAILY' },
        UpdateExpression:
          'SET #count = if_not_exists(#count, :zero) + :n, #ttl = if_not_exists(#ttl, :ttl)',
        // Allow only if no existing count (first request today) OR existing count <= remaining
        ConditionExpression: 'attribute_not_exists(#count) OR #count <= :remaining',
        ExpressionAttributeNames: { '#count': 'count', '#ttl': 'ttl' },
        ExpressionAttributeValues: {
          ':zero': 0,
          ':n': imageCount,
          ':ttl': endOfDayTtlSeconds(),
          ':remaining': remaining,
        },
      }),
    );
    return true;
  } catch (err) {
    if ((err as Error).name === 'ConditionalCheckFailedException') {
      return false;
    }
    throw err;
  }
}

async function sendToSqs(jobId: string, userId: string, images: ImageRef[]): Promise<void> {
  const batches = chunk(images, SQS_BATCH_SIZE);

  for (const batch of batches) {
    await sqs.send(
      new SendMessageBatchCommand({
        QueueUrl: QUEUE_URL,
        Entries: batch.map((img, idx) => ({
          Id: `${jobId}-${idx}`,
          MessageBody: JSON.stringify({
            jobId,
            clientId: userId,
            imageKey: img.key,
          }),
        })),
      }),
    );
  }
}

export const handler = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  logger.appendKeys({ path: event.path, method: event.httpMethod });

  try {
    const claims = event.requestContext.authorizer?.claims ?? {};
    const userId = claims['sub'] as string;
    const groupsClaim = (claims['cognito:groups'] as string | undefined) ?? '';
    const groups = groupsClaim.split(',').map((g) => g.trim());
    const isPublicUser = groups.includes('public-user') && !groups.includes('scientist-user');

    const body = JSON.parse(event.body ?? '{}') as { images?: Partial<ImageRef>[] };

    if (!Array.isArray(body.images) || body.images.length === 0) {
      return jsonResponse(400, { message: 'images array is required and must not be empty' });
    }

    const images = body.images as ImageRef[];

    if (images.some((img) => !img.key)) {
      return jsonResponse(400, { message: 'Each image must have a key' });
    }

    const imageCount = images.length;

    // Quota check — only for public-user
    if (isPublicUser) {
      if (imageCount > MAX_PUBLIC_IMAGES_PER_DAY) {
        return jsonResponse(400, {
          message: `Public users can submit at most ${MAX_PUBLIC_IMAGES_PER_DAY} images per day`,
        });
      }

      const allowed = await checkAndIncrementQuota(userId, imageCount);
      if (!allowed) {
        metrics.addMetric('QuotaExceeded', MetricUnit.Count, 1);
        return jsonResponse(429, {
          message: `Daily quota exceeded. Public users are limited to ${MAX_PUBLIC_IMAGES_PER_DAY} images per day.`,
        });
      }
    }

    // Create job record in DynamoDB
    const jobId = randomUUID();
    const createdAt = new Date().toISOString();

    await ddb.send(
      new PutCommand({
        TableName: JOBS_TABLE,
        Item: {
          pk: `job#${jobId}`,
          sk: 'metadata',
          entityType: 'classification',
          jobId,
          userId,
          imageCount,
          status: 'QUEUED',
          processedCount: 0,
          createdAt,
          images: images.map((img) => img.key),
        },
      }),
    );

    // Enqueue one SQS message per image
    await sendToSqs(jobId, userId, images);

    metrics.addMetric('JobCreated', MetricUnit.Count, 1);
    metrics.addMetric('ImagesEnqueued', MetricUnit.Count, imageCount);

    logger.info('Job created and enqueued', { jobId, imageCount, userId });

    return jsonResponse(202, {
      jobId,
      status: 'QUEUED',
      imageCount,
      createdAt,
    });
  } catch (err) {
    logger.error('Ingestion API error', { error: err });
    metrics.addMetric('IngestionApiError', MetricUnit.Count, 1);
    return jsonResponse(500, { message: 'Internal server error' });
  } finally {
    metrics.publishStoredMetrics();
  }
};
