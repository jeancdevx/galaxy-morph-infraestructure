import { DynamoDBClient } from '@aws-sdk/client-dynamodb'
import { DynamoDBDocumentClient } from '@aws-sdk/lib-dynamodb'

import { tracer } from './powertools.js'

const ddbClient = tracer.captureAWSv3Client(new DynamoDBClient({}))
export const ddb = DynamoDBDocumentClient.from(ddbClient)

export const JOBS_TABLE = process.env.JOBS_TABLE_NAME!
export const APPSYNC_URL = process.env.APPSYNC_GRAPHQL_URL!
export const AWS_REGION = process.env.AWS_REGION!
