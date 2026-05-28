import { EMRServerlessClient } from '@aws-sdk/client-emr-serverless'
import { SSMClient } from '@aws-sdk/client-ssm'

import { tracer } from './powertools.js'

export const emr = tracer.captureAWSv3Client(new EMRServerlessClient({}))
export const ssm = tracer.captureAWSv3Client(new SSMClient({}))

export const EMR_APPLICATION_ID = process.env.EMR_APPLICATION_ID!
export const EMR_EXECUTION_ROLE_ARN = process.env.EMR_EXECUTION_ROLE_ARN!
export const CHECKPOINTS_BUCKET = process.env.CHECKPOINTS_BUCKET!
export const ARTIFACT_S3_PREFIX = process.env.ARTIFACT_S3_PREFIX!
export const MSK_BOOTSTRAP_SERVERS = process.env.MSK_BOOTSTRAP_SERVERS!
export const SAGEMAKER_ENDPOINT_NAME = process.env.SAGEMAKER_ENDPOINT_NAME ?? ''
export const IMAGES_BUCKET = process.env.IMAGES_BUCKET!
export const INFERENCE_MODE = process.env.INFERENCE_MODE ?? 'sagemaker'
export const KAFKA_INGESTION_TOPIC =
  process.env.KAFKA_INGESTION_TOPIC ?? 'galaxy.ingestion'
export const KAFKA_RESULTS_TOPIC =
  process.env.KAFKA_RESULTS_TOPIC ?? 'galaxy.results'
export const KAFKA_GROUP_ID =
  process.env.KAFKA_GROUP_ID ?? 'galaxy-morph-emr-streaming'
export const TRIGGER_INTERVAL_SECONDS =
  process.env.TRIGGER_INTERVAL_SECONDS ?? '5'
export const INFERENCE_RETRIES = process.env.INFERENCE_RETRIES ?? '3'
export const SSM_JOB_RUN_ID_PARAMETER = process.env.SSM_JOB_RUN_ID_PARAMETER!
export const NAME_PREFIX = process.env.NAME_PREFIX ?? 'galaxy-morph'
