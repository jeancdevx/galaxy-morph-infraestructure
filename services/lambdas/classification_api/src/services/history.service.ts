import { MetricUnit } from '@aws-lambda-powertools/metrics'
import { QueryCommand } from '@aws-sdk/lib-dynamodb'
import {
  type APIGatewayProxyEvent,
  type APIGatewayProxyResult
} from 'aws-lambda'

import { jsonResponse } from '@galaxy-morph/shared'

import {
  COMMUNITY_GSI,
  ddb,
  JOBS_TABLE,
  MAX_PAGE_SIZE
} from '../lib/clients.js'
import { metrics } from '../lib/powertools.js'

export async function handleHistory(
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> {
  const params = event.queryStringParameters ?? {}
  const limit = Math.min(
    Math.abs(Number(params['limit'] ?? MAX_PAGE_SIZE)),
    MAX_PAGE_SIZE
  )

  let lastKey: Record<string, unknown> | undefined
  if (params['nextToken']) {
    try {
      lastKey = JSON.parse(
        Buffer.from(params['nextToken'], 'base64').toString('utf-8')
      ) as Record<string, unknown>
    } catch {
      return jsonResponse(400, { message: 'Invalid nextToken' })
    }
  }

  const result = await ddb.send(
    new QueryCommand({
      TableName: JOBS_TABLE,
      IndexName: COMMUNITY_GSI,
      KeyConditionExpression: 'entityType = :et',
      ExpressionAttributeValues: { ':et': 'classification' },
      ScanIndexForward: false,
      Limit: limit,
      ExclusiveStartKey: lastKey
    })
  )

  const nextToken = result.LastEvaluatedKey
    ? Buffer.from(JSON.stringify(result.LastEvaluatedKey)).toString('base64')
    : undefined

  metrics.addMetric('CommunityHistoryFetched', MetricUnit.Count, 1)

  return jsonResponse(200, {
    items: result.Items ?? [],
    count: result.Count ?? 0,
    ...(nextToken ? { nextToken } : {})
  })
}
