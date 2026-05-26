import { S3Client } from '@aws-sdk/client-s3'

import { tracer } from './powertools.js'

export const s3 = tracer.captureAWSv3Client(new S3Client({}))

export const IMAGES_BUCKET = process.env.IMAGES_BUCKET_NAME!
export const PRESIGNED_URL_EXPIRES_SECONDS = 3600
export const MAX_IMAGES_PER_REQUEST = 20
