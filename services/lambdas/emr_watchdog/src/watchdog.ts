import { MetricUnit } from '@aws-lambda-powertools/metrics'
import type { EventBridgeEvent } from 'aws-lambda'

import { logger, metrics } from './lib/powertools.js'
import { startStreamingJob } from './services/emr.service.js'

interface EMRJobStateDetail {
  applicationId: string
  jobRunId: string
  state: string
  stateDetails: string
}

export const handler = async (
  event: EventBridgeEvent<
    'EMR Serverless Job Run State Change',
    EMRJobStateDetail
  >
): Promise<{ failedJobRunId: string; newJobRunId: string }> => {
  const { jobRunId: failedJobRunId, state, stateDetails } = event.detail
  logger.info('EMR job failed, restarting', {
    failedJobRunId,
    state,
    stateDetails
  })

  const newJobRunId = await startStreamingJob()

  logger.info('EMR streaming job restarted', { failedJobRunId, newJobRunId })
  metrics.addMetric('JobRestarted', MetricUnit.Count, 1)
  metrics.publishStoredMetrics()

  return { failedJobRunId, newJobRunId }
}
