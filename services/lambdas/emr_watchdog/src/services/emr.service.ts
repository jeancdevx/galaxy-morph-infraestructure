import { StartJobRunCommand } from '@aws-sdk/client-emr-serverless'
import { PutParameterCommand } from '@aws-sdk/client-ssm'

import {
  ARTIFACT_S3_PREFIX,
  CHECKPOINTS_BUCKET,
  emr,
  EMR_APPLICATION_ID,
  EMR_EXECUTION_ROLE_ARN,
  IMAGES_BUCKET,
  INFERENCE_MODE,
  INFERENCE_RETRIES,
  KAFKA_GROUP_ID,
  KAFKA_INGESTION_TOPIC,
  KAFKA_RESULTS_TOPIC,
  MSK_BOOTSTRAP_SERVERS,
  NAME_PREFIX,
  SAGEMAKER_ENDPOINT_NAME,
  ssm,
  SSM_JOB_RUN_ID_PARAMETER,
  TRIGGER_INTERVAL_SECONDS
} from '../lib/clients.js'
import { logger } from '../lib/powertools.js'

export async function startStreamingJob(): Promise<string> {
  const checkpointUri = `s3://${CHECKPOINTS_BUCKET}/streaming-classification/`
  const entryPoint = `s3://${CHECKPOINTS_BUCKET}/${ARTIFACT_S3_PREFIX}/main_streaming.py`
  const pyFiles = `s3://${CHECKPOINTS_BUCKET}/${ARTIFACT_S3_PREFIX}/deps.zip`

  const sparkConf = [
    `--py-files ${pyFiles}`,
    '--packages org.apache.spark:spark-sql-kafka-0-10_2.12:3.5.0,software.amazon.msk:aws-msk-iam-auth:1.1.9',
    '--conf spark.dynamicAllocation.minExecutors=2',
    '--conf spark.dynamicAllocation.maxExecutors=24',
    '--conf spark.dynamicAllocation.executorIdleTimeout=300',
    '--conf spark.dynamicAllocation.shuffleTracking.enabled=true',
    '--conf spark.executor.cores=4',
    '--conf spark.executor.memory=6g',
    '--conf spark.executor.memoryOverhead=2g',
    '--conf spark.driver.cores=2',
    '--conf spark.driver.memory=3g',
    '--conf spark.driver.memoryOverhead=1g',
    `--conf spark.app.kafka_bootstrap_servers=${MSK_BOOTSTRAP_SERVERS}`,
    `--conf spark.app.kafka_ingestion_topic=${KAFKA_INGESTION_TOPIC}`,
    `--conf spark.app.kafka_results_topic=${KAFKA_RESULTS_TOPIC}`,
    `--conf spark.app.kafka_group_id=${KAFKA_GROUP_ID}`,
    `--conf spark.app.images_bucket=${IMAGES_BUCKET}`,
    `--conf spark.app.inference_mode=${INFERENCE_MODE}`,
    `--conf spark.app.checkpoint_s3_uri=${checkpointUri}`,
    `--conf spark.app.trigger_interval_seconds=${TRIGGER_INTERVAL_SECONDS}`,
    `--conf spark.app.inference_retries=${INFERENCE_RETRIES}`,
    ...(SAGEMAKER_ENDPOINT_NAME
      ? [`--conf spark.app.sagemaker_endpoint_name=${SAGEMAKER_ENDPOINT_NAME}`]
      : [])
  ].join(' ')

  const timestamp = new Date().toISOString().replace(/[:.]/g, '-')

  logger.info('Starting EMR Serverless streaming job', {
    applicationId: EMR_APPLICATION_ID
  })

  const { jobRunId } = await emr.send(
    new StartJobRunCommand({
      applicationId: EMR_APPLICATION_ID,
      executionRoleArn: EMR_EXECUTION_ROLE_ARN,
      name: `streaming-classification-${timestamp}`,
      jobDriver: {
        sparkSubmit: {
          entryPoint,
          sparkSubmitParameters: sparkConf
        }
      },
      configurationOverrides: {
        monitoringConfiguration: {
          cloudWatchLoggingConfiguration: { enabled: true },
          s3MonitoringConfiguration: {
            logUri: `s3://${CHECKPOINTS_BUCKET}/emr-serverless/logs/`
          }
        }
      },
      executionTimeoutMinutes: 10080,
      tags: { project: NAME_PREFIX, component: 'streaming-classification' }
    })
  )

  await ssm.send(
    new PutParameterCommand({
      Name: SSM_JOB_RUN_ID_PARAMETER,
      Value: jobRunId!,
      Type: 'String',
      Overwrite: true
    })
  )

  logger.info('EMR Serverless streaming job started', { jobRunId })
  return jobRunId!
}
