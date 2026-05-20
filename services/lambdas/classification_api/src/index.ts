import { Logger } from '@aws-lambda-powertools/logger';
import { Tracer } from '@aws-lambda-powertools/tracer';
import { Metrics, MetricUnit } from '@aws-lambda-powertools/metrics';
import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, QueryCommand } from '@aws-sdk/lib-dynamodb';
import type { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';

const SERVICE_NAME = 'classification-api';

const logger = new Logger({ serviceName: SERVICE_NAME });
const tracer = new Tracer({ serviceName: SERVICE_NAME });
const metrics = new Metrics({ namespace: 'GalaxyMorph', serviceName: SERVICE_NAME });

const ddbClient = tracer.captureAWSv3Client(new DynamoDBClient({}));
const ddb = DynamoDBDocumentClient.from(ddbClient);

const JOBS_TABLE = process.env.JOBS_TABLE_NAME!;
const COMMUNITY_GSI = 'entityType-createdAt-index';
const MAX_PAGE_SIZE = 50;

function jsonResponse(statusCode: number, body: unknown): APIGatewayProxyResult {
  return {
    statusCode,
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  };
}

async function handleHistory(event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> {
  const params = event.queryStringParameters ?? {};

  const limit = Math.min(Math.abs(Number(params.limit ?? MAX_PAGE_SIZE)), MAX_PAGE_SIZE);

  let lastKey: Record<string, unknown> | undefined;
  if (params.nextToken) {
    try {
      lastKey = JSON.parse(
        Buffer.from(params.nextToken, 'base64').toString('utf-8'),
      ) as Record<string, unknown>;
    } catch {
      return jsonResponse(400, { message: 'Invalid nextToken' });
    }
  }

  const result = await ddb.send(
    new QueryCommand({
      TableName: JOBS_TABLE,
      IndexName: COMMUNITY_GSI,
      KeyConditionExpression: 'entityType = :et',
      ExpressionAttributeValues: { ':et': 'classification' },
      ScanIndexForward: false, // newest first
      Limit: limit,
      ExclusiveStartKey: lastKey,
    }),
  );

  const nextToken = result.LastEvaluatedKey
    ? Buffer.from(JSON.stringify(result.LastEvaluatedKey)).toString('base64')
    : undefined;

  metrics.addMetric('CommunityHistoryFetched', MetricUnit.Count, 1);

  return jsonResponse(200, {
    items: result.Items ?? [],
    count: result.Count ?? 0,
    ...(nextToken ? { nextToken } : {}),
  });
}

export const handler = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  logger.appendKeys({ path: event.path, method: event.httpMethod });

  try {
    if (event.httpMethod === 'GET' && event.path.endsWith('/classifications/history')) {
      return await handleHistory(event);
    }

    return jsonResponse(404, { message: 'Not found' });
  } catch (err) {
    logger.error('Classification API error', { error: err });
    metrics.addMetric('ClassificationApiError', MetricUnit.Count, 1);
    return jsonResponse(500, { message: 'Internal server error' });
  } finally {
    metrics.publishStoredMetrics();
  }
};
