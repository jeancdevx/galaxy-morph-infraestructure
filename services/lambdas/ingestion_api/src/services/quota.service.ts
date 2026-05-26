import { UpdateCommand } from '@aws-sdk/lib-dynamodb'

import { ddb, JOBS_TABLE, MAX_PUBLIC_IMAGES_PER_DAY } from '../lib/clients.js'
import { endOfDayTtlSeconds } from '../lib/utils.js'

export async function checkAndIncrementQuota(
  userId: string,
  imageCount: number
): Promise<boolean> {
  const remaining = MAX_PUBLIC_IMAGES_PER_DAY - imageCount

  if (remaining < 0) {
    return false
  }

  try {
    await ddb.send(
      new UpdateCommand({
        TableName: JOBS_TABLE,
        Key: { pk: `quota#${userId}`, sk: 'DAILY' },
        UpdateExpression:
          'SET #count = if_not_exists(#count, :zero) + :n, #ttl = if_not_exists(#ttl, :ttl)',
        ConditionExpression:
          'attribute_not_exists(#count) OR #count <= :remaining',
        ExpressionAttributeNames: { '#count': 'count', '#ttl': 'ttl' },
        ExpressionAttributeValues: {
          ':zero': 0,
          ':n': imageCount,
          ':ttl': endOfDayTtlSeconds(),
          ':remaining': remaining
        }
      })
    )
    return true
  } catch (err) {
    if ((err as Error).name === 'ConditionalCheckFailedException') {
      return false
    }
    throw err
  }
}
