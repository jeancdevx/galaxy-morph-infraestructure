import { MetricUnit } from '@aws-lambda-powertools/metrics'
import {
  type APIGatewayProxyEvent,
  type APIGatewayProxyResult
} from 'aws-lambda'

import { jsonResponse } from '@galaxy-morph/shared'

import { logger, metrics } from './lib/powertools.js'
import {
  generatePresignedUrls,
  type ImageInput
} from './services/presign.service.js'

export const handler = async (
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> => {
  logger.appendKeys({ path: event.path, method: event.httpMethod })

  try {
    const body = JSON.parse(event.body ?? '{}') as {
      images?: Partial<ImageInput>[]
    }

    if (!Array.isArray(body.images) || body.images.length === 0) {
      return jsonResponse(400, {
        message: 'images array is required and must not be empty'
      })
    }

    const userId = event.requestContext.authorizer?.claims?.['sub'] as string
    const uploads = await generatePresignedUrls(userId, body.images)

    metrics.addMetric(
      'PresignedUrlsGenerated',
      MetricUnit.Count,
      uploads.length
    )

    return jsonResponse(200, { uploads })
  } catch (err) {
    const error = err as Error & { statusCode?: number }

    if (
      error.statusCode === 400 ||
      error.message.includes('filename') ||
      error.message.includes('contentType') ||
      error.message.includes('Maximum')
    ) {
      return jsonResponse(400, { message: error.message })
    }

    logger.error('Upload API error', { error })
    metrics.addMetric('UploadApiError', MetricUnit.Count, 1)
    return jsonResponse(500, { message: 'Internal server error' })
  } finally {
    metrics.publishStoredMetrics()
  }
}
