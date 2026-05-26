import { randomUUID } from 'crypto'

import { PutObjectCommand } from '@aws-sdk/client-s3'
import { getSignedUrl } from '@aws-sdk/s3-request-presigner'

import {
  IMAGES_BUCKET,
  MAX_IMAGES_PER_REQUEST,
  PRESIGNED_URL_EXPIRES_SECONDS,
  s3
} from '../lib/clients.js'

export interface ImageInput {
  filename: string
  contentType: string
}

export interface PresignedUpload {
  key: string
  uploadUrl: string
  expiresIn: number
}

export async function generatePresignedUrls(
  userId: string,
  images: Partial<ImageInput>[]
): Promise<PresignedUpload[]> {
  if (images.length > MAX_IMAGES_PER_REQUEST) {
    throw Object.assign(
      new Error(`Maximum ${MAX_IMAGES_PER_REQUEST} images per request`),
      { statusCode: 400 }
    )
  }

  const batchId = randomUUID()

  return Promise.all(
    images.map(async img => {
      if (!img.filename || !img.contentType) {
        throw new Error('Each image must have filename and contentType')
      }

      const key = `galaxies/${userId}/${batchId}/${img.filename}`

      const command = new PutObjectCommand({
        Bucket: IMAGES_BUCKET,
        Key: key,
        ContentType: img.contentType
      })

      const uploadUrl = await getSignedUrl(s3, command, {
        expiresIn: PRESIGNED_URL_EXPIRES_SECONDS
      })

      return { key, uploadUrl, expiresIn: PRESIGNED_URL_EXPIRES_SECONDS }
    })
  )
}
