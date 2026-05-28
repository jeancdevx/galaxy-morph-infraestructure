import { MetricUnit } from '@aws-lambda-powertools/metrics'
import type { EventBridgeEvent } from 'aws-lambda'

import { logger, metrics } from './lib/powertools.js'
import { startStreamingJob } from './services/emr.service.js'

interface SageMakerEndpointStateDetail {
  EndpointName: string
  EndpointStatus: string
}

export const handler = async (
  event: EventBridgeEvent<
    'SageMaker Endpoint State Change',
    SageMakerEndpointStateDetail
  >
): Promise<{ jobRunId: string }> => {
  logger.info('SageMaker endpoint reached IN_SERVICE', { detail: event.detail })

  const jobRunId = await startStreamingJob()

  logger.info('EMR streaming job launched', { jobRunId })
  metrics.addMetric('JobLaunched', MetricUnit.Count, 1)
  metrics.publishStoredMetrics()

  return { jobRunId }
}
