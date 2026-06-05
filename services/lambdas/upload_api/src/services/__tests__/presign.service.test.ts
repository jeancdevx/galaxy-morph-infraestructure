import { beforeEach, describe, expect, it, vi } from 'vitest'

import { generatePresignedUrls } from '../presign.service.js'

vi.mock('@galaxy-morph/shared', () => ({
  POWERTOOLS_NAMESPACE: 'GalaxyMorph'
}))

vi.mock('@aws-lambda-powertools/logger', () => ({
  Logger: vi.fn().mockImplementation(() => ({
    appendKeys: vi.fn(),
    error: vi.fn()
  }))
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

vi.mock('@aws-sdk/client-s3', () => ({
  S3Client: vi.fn().mockImplementation(() => ({})),
  PutObjectCommand: vi.fn()
}))

vi.mock('@aws-sdk/s3-request-presigner', () => ({
  getSignedUrl: vi.fn().mockResolvedValue('https://s3.example.com/presigned')
}))

describe('generatePresignedUrls', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('returns presigned uploads for valid inputs', async () => {
    const results = await generatePresignedUrls('user-1', [
      { filename: 'galaxy.jpg', contentType: 'image/jpeg' }
    ])
    expect(results).toHaveLength(1)
    expect(results[0]).toMatchObject({
      key: expect.stringContaining('galaxies/user-1/'),
      uploadUrl: 'https://s3.example.com/presigned',
      expiresIn: 3600
    })
  })

  it('throws 400 error when exceeding max images per request', async () => {
    const images = Array.from({ length: 21 }, (_, i) => ({
      filename: `img${i}.jpg`,
      contentType: 'image/jpeg'
    }))
    await expect(generatePresignedUrls('user-1', images)).rejects.toMatchObject(
      { statusCode: 400 }
    )
  })

  it('throws when filename is missing', async () => {
    await expect(
      generatePresignedUrls('user-1', [{ contentType: 'image/jpeg' }])
    ).rejects.toThrow('filename')
  })

  it('throws when contentType is missing', async () => {
    await expect(
      generatePresignedUrls('user-1', [{ filename: 'img.jpg' }])
    ).rejects.toThrow('contentType')
  })

  it('generates unique batchId per call (same user, different keys)', async () => {
    const firstResult = await generatePresignedUrls('user-1', [
      { filename: 'a.jpg', contentType: 'image/jpeg' }
    ])
    const secondResult = await generatePresignedUrls('user-1', [
      { filename: 'a.jpg', contentType: 'image/jpeg' }
    ])
    expect(firstResult[0]!.key).not.toBe(secondResult[0]!.key)
  })
})
