import { DynamoDBClient } from '@aws-sdk/client-dynamodb'
import { SQSClient } from '@aws-sdk/client-sqs'
import { DynamoDBDocumentClient } from '@aws-sdk/lib-dynamodb'

import { tracer } from './powertools.js'

const ddbClient = tracer.captureAWSv3Client(new DynamoDBClient({}))
export const ddb = DynamoDBDocumentClient.from(ddbClient)
export const sqs = tracer.captureAWSv3Client(new SQSClient({}))

export const JOBS_TABLE = process.env.JOBS_TABLE_NAME!
export const QUEUE_URL = process.env.INGESTION_QUEUE_URL!
export const MAX_PUBLIC_IMAGES_PER_DAY = 10
export const SQS_BATCH_SIZE = 10
