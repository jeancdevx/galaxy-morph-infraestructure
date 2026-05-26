import { MetricUnit } from '@aws-lambda-powertools/metrics'
import { type MSKEvent } from 'aws-lambda'

import { type KafkaResultMessage } from '@galaxy-morph/shared'

import { logger, metrics } from './lib/powertools.js'
import { callAppSyncMutation } from './services/appsync.service.js'
import { updateJobProgress } from './services/job.service.js'

function decodeKafkaRecord(value: string): KafkaResultMessage {
  const decoded = Buffer.from(value, 'base64').toString('utf-8')
  return JSON.parse(decoded) as KafkaResultMessage
}

export const handler = async (event: MSKEvent): Promise<void> => {
  logger.info('MSK event received', {
    topicCount: Object.keys(event.records).length
  })

  const allMessages: KafkaResultMessage[] = []

  for (const [_topicPartition, records] of Object.entries(event.records)) {
    for (const record of records) {
      try {
        allMessages.push(decodeKafkaRecord(record.value))
      } catch (err) {
        logger.error('Failed to decode Kafka record', {
          offset: record.offset,
          error: err
        })
        metrics.addMetric('DecodeError', MetricUnit.Count, 1)
      }
    }
  }

  logger.info('Processing messages', { count: allMessages.length })

  const results = await Promise.allSettled(
    allMessages.map(async message => {
      logger.appendKeys({ jobId: message.jobId, imageKey: message.imageKey })

      await callAppSyncMutation(message)
      await updateJobProgress(message.jobId)

      metrics.addMetric('MessageProcessed', MetricUnit.Count, 1)
      logger.info('Message dispatched', {
        clientId: message.clientId,
        status: message.status
      })
    })
  )

  const failures = results.filter(r => r.status === 'rejected')

  if (failures.length > 0) {
    metrics.addMetric('DispatchError', MetricUnit.Count, failures.length)
    failures.forEach(f =>
      logger.error('Message dispatch failed', {
        reason: (f as PromiseRejectedResult).reason
      })
    )
    throw new Error(
      `${failures.length}/${allMessages.length} messages failed to dispatch`
    )
  }

  metrics.publishStoredMetrics()
}
