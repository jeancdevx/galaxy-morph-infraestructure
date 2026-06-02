import { StartJobRunCommand } from '@aws-sdk/client-emr-serverless'
import { PutParameterCommand } from '@aws-sdk/client-ssm'
import { beforeEach, describe, expect, it, vi } from 'vitest'

import { startStreamingJob } from '../emr.service.js'

const mockSend = vi.hoisted(() => vi.fn())

vi.mock('../../lib/powertools.js', () => ({
  logger: { info: vi.fn(), error: vi.fn() },
  tracer: { captureAWSv3Client: (c: unknown) => c },
  metrics: { addMetric: vi.fn(), publishStoredMetrics: vi.fn() }
}))

vi.mock('../../lib/clients.js', () => ({
  emr: { send: mockSend },
  ssm: { send: mockSend },
  EMR_APPLICATION_ID: 'app-123',
  EMR_EXECUTION_ROLE_ARN: 'arn:aws:iam::123456789:role/emr-exec',
  CHECKPOINTS_BUCKET: 'my-checkpoints',
  ARTIFACT_S3_PREFIX: 'emr/jobs/streaming_classification/latest',
  MSK_BOOTSTRAP_SERVERS: 'boot-abc.kafka.us-east-2.amazonaws.com:9098',
  SAGEMAKER_ENDPOINT_NAME: 'galaxy-morph-dev-endpoint',
  IMAGES_BUCKET: 'my-images',
  INFERENCE_MODE: 'sagemaker',
  KAFKA_INGESTION_TOPIC: 'galaxy.ingestion',
  KAFKA_RESULTS_TOPIC: 'galaxy.results',
  KAFKA_GROUP_ID: 'galaxy-morph-emr-streaming',
  TRIGGER_INTERVAL_SECONDS: '5',
  INFERENCE_RETRIES: '3',
  SSM_JOB_RUN_ID_PARAMETER: '/galaxy-morph-dev/emr/current-job-run-id',
  NAME_PREFIX: 'galaxy-morph-dev'
}))

describe('startStreamingJob', () => {
  beforeEach(() => {
    mockSend.mockReset()
  })

  it('calls StartJobRunCommand and returns the jobRunId', async () => {
    mockSend
      .mockResolvedValueOnce({ jobRunId: 'jr-abc123' }) // EMR call
      .mockResolvedValueOnce({}) // SSM call

    const jobRunId = await startStreamingJob()

    expect(jobRunId).toBe('jr-abc123')
    expect(mockSend).toHaveBeenCalledTimes(2)

    const emrCall = mockSend.mock.calls[0][0]
    expect(emrCall).toBeInstanceOf(StartJobRunCommand)
    expect(emrCall.input.applicationId).toBe('app-123')
    expect(emrCall.input.executionTimeoutMinutes).toBe(10080)
  })

  it('persists the jobRunId to SSM', async () => {
    mockSend
      .mockResolvedValueOnce({ jobRunId: 'jr-xyz789' })
      .mockResolvedValueOnce({})

    await startStreamingJob()

    const ssmCall = mockSend.mock.calls[1][0]
    expect(ssmCall).toBeInstanceOf(PutParameterCommand)
    expect(ssmCall.input.Name).toBe('/galaxy-morph-dev/emr/current-job-run-id')
    expect(ssmCall.input.Value).toBe('jr-xyz789')
    expect(ssmCall.input.Overwrite).toBe(true)
  })

  it('includes sagemaker_endpoint_name in Spark conf when set', async () => {
    mockSend
      .mockResolvedValueOnce({ jobRunId: 'jr-sage' })
      .mockResolvedValueOnce({})

    await startStreamingJob()

    const emrCall = mockSend.mock.calls[0][0]
    const sparkParams: string =
      emrCall.input.jobDriver.sparkSubmit.sparkSubmitParameters
    expect(sparkParams).toContain(
      '--conf spark.app.sagemaker_endpoint_name=galaxy-morph-dev-endpoint'
    )
  })

  it('propagates EMR errors', async () => {
    mockSend.mockRejectedValueOnce(new Error('EMR throttled'))

    await expect(startStreamingJob()).rejects.toThrow('EMR throttled')
  })
})
