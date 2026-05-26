import { SendMessageBatchCommand } from '@aws-sdk/client-sqs'

import { type ImageRef } from '@galaxy-morph/shared'

import { QUEUE_URL, sqs, SQS_BATCH_SIZE } from '../lib/clients.js'
import { chunk } from '../lib/utils.js'

export async function sendToSqs(
  jobId: string,
  userId: string,
  images: ImageRef[]
): Promise<void> {
  const batches = chunk(images, SQS_BATCH_SIZE)

  for (const batch of batches) {
    await sqs.send(
      new SendMessageBatchCommand({
        QueueUrl: QUEUE_URL,
        Entries: batch.map((img, idx) => ({
          Id: `${jobId}-${idx}`,
          MessageBody: JSON.stringify({
            jobId,
            clientId: userId,
            imageKey: img.key
          })
        }))
      })
    )
  }
}
