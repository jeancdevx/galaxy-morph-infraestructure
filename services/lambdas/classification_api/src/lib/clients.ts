import { DynamoDBClient } from '@aws-sdk/client-dynamodb'
import { DynamoDBDocumentClient } from '@aws-sdk/lib-dynamodb'

import { tracer } from './powertools.js'

const ddbClient = tracer.captureAWSv3Client(new DynamoDBClient({}))
export const ddb = DynamoDBDocumentClient.from(ddbClient)

export const JOBS_TABLE = process.env.JOBS_TABLE_NAME!
export const COMMUNITY_GSI = 'entityType-createdAt-index'
export const MAX_PAGE_SIZE = 50
