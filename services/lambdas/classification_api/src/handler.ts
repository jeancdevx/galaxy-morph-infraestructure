import { MetricUnit } from '@aws-lambda-powertools/metrics'
import {
  type APIGatewayProxyEvent,
  type APIGatewayProxyResult
} from 'aws-lambda'

import { jsonResponse } from '@galaxy-morph/shared'

import { logger, metrics } from './lib/powertools.js'
import { handleHistory } from './services/history.service.js'

export const handler = async (
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> => {
  logger.appendKeys({ path: event.path, method: event.httpMethod })

  try {
    if (
      event.httpMethod === 'GET' &&
      event.path.endsWith('/classifications/history')
    ) {
      return await handleHistory(event)
    }

    return jsonResponse(404, { message: 'Not found' })
  } catch (err) {
    logger.error('Classification API error', { error: err })
    metrics.addMetric('ClassificationApiError', MetricUnit.Count, 1)
    return jsonResponse(500, { message: 'Internal server error' })
  } finally {
    metrics.publishStoredMetrics()
  }
}
