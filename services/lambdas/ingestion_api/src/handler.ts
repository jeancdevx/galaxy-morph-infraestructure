import { randomUUID } from 'crypto'

import { MetricUnit } from '@aws-lambda-powertools/metrics'
import {
  type APIGatewayProxyEvent,
  type APIGatewayProxyResult
} from 'aws-lambda'

import {
  jsonResponse,
  resolveCorsOrigin,
  type ImageRef
} from '@galaxy-morph/shared'

import { MAX_PUBLIC_IMAGES_PER_DAY } from './lib/clients.js'
import { logger, metrics } from './lib/powertools.js'
import { createJob } from './services/job.service.js'
import { checkAndIncrementQuota } from './services/quota.service.js'
import { sendToSqs } from './services/sqs.service.js'

export const handler = async (
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> => {
  logger.appendKeys({ path: event.path, method: event.httpMethod })
  const corsOrigin = resolveCorsOrigin(event)

  try {
    const claims = event.requestContext.authorizer?.claims ?? {}
    const userId = claims['sub'] as string
    const groupsClaim = (claims['cognito:groups'] as string | undefined) ?? ''
    const groups = groupsClaim.split(',').map(g => g.trim())
    const isPublicUser =
      groups.includes('public-user') && !groups.includes('scientist-user')

    const body = JSON.parse(event.body ?? '{}') as {
      images?: Partial<ImageRef>[]
    }

    if (!Array.isArray(body.images) || body.images.length === 0) {
      return jsonResponse(
        400,
        {
          message: 'images array is required and must not be empty'
        },
        corsOrigin
      )
    }

    const images = body.images as ImageRef[]

    if (images.some(img => !img.key)) {
      return jsonResponse(
        400,
        { message: 'Each image must have a key' },
        corsOrigin
      )
    }

    const expectedPrefix = `galaxies/${userId}/`
    if (images.some(img => !img.key.startsWith(expectedPrefix))) {
      return jsonResponse(
        403,
        {
          message: 'Forbidden: you can only classify images you uploaded'
        },
        corsOrigin
      )
    }

    const imageCount = images.length

    if (isPublicUser) {
      if (imageCount > MAX_PUBLIC_IMAGES_PER_DAY) {
        return jsonResponse(
          400,
          {
            message: `Public users can submit at most ${MAX_PUBLIC_IMAGES_PER_DAY} images per day`
          },
          corsOrigin
        )
      }

      const allowed = await checkAndIncrementQuota(userId, imageCount)
      if (!allowed) {
        metrics.addMetric('QuotaExceeded', MetricUnit.Count, 1)
        return jsonResponse(
          429,
          {
            message: `Daily quota exceeded. Public users are limited to ${MAX_PUBLIC_IMAGES_PER_DAY} images per day.`
          },
          corsOrigin
        )
      }
    }

    const jobId = randomUUID()
    const createdAt = new Date().toISOString()

    await createJob({ jobId, userId, imageCount, images, createdAt })
    await sendToSqs(jobId, userId, images)

    metrics.addMetric('JobCreated', MetricUnit.Count, 1)
    metrics.addMetric('ImagesEnqueued', MetricUnit.Count, imageCount)
    logger.info('Job created and enqueued', { jobId, imageCount, userId })

    return jsonResponse(
      202,
      { jobId, status: 'QUEUED', imageCount, createdAt },
      corsOrigin
    )
  } catch (err) {
    logger.error('Ingestion API error', { error: err })
    metrics.addMetric('IngestionApiError', MetricUnit.Count, 1)
    return jsonResponse(500, { message: 'Internal server error' }, corsOrigin)
  } finally {
    metrics.publishStoredMetrics()
  }
}
