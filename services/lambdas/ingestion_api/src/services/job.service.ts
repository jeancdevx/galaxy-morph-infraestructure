import { PutCommand } from '@aws-sdk/lib-dynamodb'

import { type ClassificationStatus, type ImageRef } from '@galaxy-morph/shared'

import { ddb, JOBS_TABLE } from '../lib/clients.js'

export interface CreateJobParams {
  jobId: string
  userId: string
  imageCount: number
  images: ImageRef[]
  createdAt: string
}

export async function createJob(params: CreateJobParams): Promise<void> {
  const { jobId, userId, imageCount, images, createdAt } = params

  await ddb.send(
    new PutCommand({
      TableName: JOBS_TABLE,
      Item: {
        pk: `job#${jobId}`,
        sk: 'metadata',
        entityType: 'classification',
        jobId,
        userId,
        imageCount,
        status: 'QUEUED' as ClassificationStatus,
        processedCount: 0,
        createdAt,
        images: images.map(img => img.key)
      }
    })
  )
}
