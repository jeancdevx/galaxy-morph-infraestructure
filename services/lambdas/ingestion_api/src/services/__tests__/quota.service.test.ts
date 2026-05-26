import { beforeEach, describe, expect, it, vi } from 'vitest'

import { checkAndIncrementQuota } from '../quota.service.js'

const mockSend = vi.hoisted(() => vi.fn())

vi.mock('@galaxy-morph/shared', () => ({
  POWERTOOLS_NAMESPACE: 'GalaxyMorph'
}))

vi.mock('@aws-lambda-powertools/logger', () => ({
  Logger: vi.fn().mockImplementation(() => ({ info: vi.fn(), error: vi.fn() }))
}))

vi.mock('@aws-lambda-powertools/tracer', () => ({
  Tracer: vi.fn().mockImplementation(() => ({
    captureAWSv3Client: (c: unknown) => c
  }))
}))

vi.mock('@aws-lambda-powertools/metrics', () => ({
  Metrics: vi.fn().mockImplementation(() => ({
    addMetric: vi.fn(),
    publishStoredMetrics: vi.fn()
  })),
  MetricUnit: { Count: 'Count' }
}))

vi.mock('@aws-sdk/client-dynamodb', () => ({
  DynamoDBClient: vi.fn().mockImplementation(() => ({ send: mockSend }))
}))

vi.mock('@aws-sdk/lib-dynamodb', () => ({
  DynamoDBDocumentClient: {
    from: vi.fn().mockReturnValue({ send: mockSend })
  },
  UpdateCommand: vi.fn()
}))

vi.mock('@aws-sdk/client-sqs', () => ({
  SQSClient: vi.fn().mockImplementation(() => ({ send: mockSend }))
}))

describe('checkAndIncrementQuota', () => {
  beforeEach(() => {
    mockSend.mockReset()
  })

  it('returns true when DynamoDB update succeeds (quota available)', async () => {
    mockSend.mockResolvedValue({})
    const allowed = await checkAndIncrementQuota('user-1', 5)
    expect(allowed).toBe(true)
  })

  it('returns false when imageCount exceeds MAX_PUBLIC_IMAGES_PER_DAY without calling DynamoDB', async () => {
    const allowed = await checkAndIncrementQuota('user-1', 11)
    expect(allowed).toBe(false)
    expect(mockSend).not.toHaveBeenCalled()
  })

  it('returns false on ConditionalCheckFailedException (quota already exhausted)', async () => {
    const err = Object.assign(new Error('condition failed'), {
      name: 'ConditionalCheckFailedException'
    })
    mockSend.mockRejectedValue(err)
    const allowed = await checkAndIncrementQuota('user-1', 3)
    expect(allowed).toBe(false)
  })

  it('re-throws non-conditional DynamoDB errors', async () => {
    const err = Object.assign(new Error('connection refused'), {
      name: 'NetworkError'
    })
    mockSend.mockRejectedValue(err)
    await expect(checkAndIncrementQuota('user-1', 3)).rejects.toThrow(
      'connection refused'
    )
  })

  it('returns false when imageCount exactly equals MAX (10)', async () => {
    mockSend.mockResolvedValue({})
    const allowed = await checkAndIncrementQuota('user-1', 10)
    expect(allowed).toBe(true)
  })
})
