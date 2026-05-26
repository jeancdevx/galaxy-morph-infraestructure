import { UpdateCommand } from '@aws-sdk/lib-dynamodb'

import { ddb, JOBS_TABLE } from '../lib/clients.js'

export async function updateJobProgress(jobId: string): Promise<void> {
  const result = await ddb.send(
    new UpdateCommand({
      TableName: JOBS_TABLE,
      Key: { pk: `job#${jobId}`, sk: 'metadata' },
      UpdateExpression:
        'SET processedCount = if_not_exists(processedCount, :zero) + :one, #updatedAt = :now',
      ExpressionAttributeNames: { '#updatedAt': 'updatedAt' },
      ExpressionAttributeValues: {
        ':one': 1,
        ':zero': 0,
        ':now': new Date().toISOString()
      },
      ReturnValues: 'ALL_NEW'
    })
  )

  const item = result.Attributes
  if (!item) return

  const processedCount = item['processedCount'] as number
  const imageCount = item['imageCount'] as number

  if (processedCount >= imageCount) {
    await ddb
      .send(
        new UpdateCommand({
          TableName: JOBS_TABLE,
          Key: { pk: `job#${jobId}`, sk: 'metadata' },
          UpdateExpression: 'SET #status = :completed, completedAt = :now',
          ConditionExpression: '#status <> :completed',
          ExpressionAttributeNames: { '#status': 'status' },
          ExpressionAttributeValues: {
            ':completed': 'COMPLETED',
            ':now': new Date().toISOString()
          }
        })
      )
      .catch(err => {
        if ((err as Error).name !== 'ConditionalCheckFailedException') {
          throw err
        }
      })
  }
}
