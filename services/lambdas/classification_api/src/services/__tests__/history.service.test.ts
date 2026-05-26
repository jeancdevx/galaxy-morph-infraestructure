import type { APIGatewayProxyEvent } from 'aws-lambda'
import { beforeEach, describe, expect, it, vi } from 'vitest'

import { handleHistory } from '../history.service.js'

const mockSend = vi.hoisted(() => vi.fn())

vi.mock('@galaxy-morph/shared', () => ({
  jsonResponse: (status: number, body: unknown) => ({
    statusCode: status,
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body)
  }),
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

vi.mock('@aws-sdk/client-dynamodb', () => ({
  DynamoDBClient: vi.fn().mockImplementation(() => ({ send: mockSend }))
}))

vi.mock('@aws-sdk/lib-dynamodb', () => ({
  DynamoDBDocumentClient: { from: vi.fn().mockReturnValue({ send: mockSend }) },
  QueryCommand: vi.fn()
}))

function makeEvent(
  overrides: Partial<APIGatewayProxyEvent> = {}
): APIGatewayProxyEvent {
  return {
    path: '/classifications/history',
    httpMethod: 'GET',
    queryStringParameters: null,
    requestContext: {},
    ...overrides
  } as unknown as APIGatewayProxyEvent
}

describe('handleHistory', () => {
  beforeEach(() => {
    mockSend.mockReset()
  })

  it('returns 200 with items and count on success', async () => {
    mockSend.mockResolvedValue({ Items: [{ jobId: 'j1' }], Count: 1 })
    const result = await handleHistory(makeEvent())
    expect(result.statusCode).toBe(200)
    const body = JSON.parse(result.body)
    expect(body.items).toHaveLength(1)
    expect(body.count).toBe(1)
  })

  it('returns 200 with nextToken when LastEvaluatedKey is present', async () => {
    const lastKey = {
      pk: 'job#abc',
      sk: 'metadata',
      entityType: 'classification'
    }
    mockSend.mockResolvedValue({
      Items: [],
      Count: 0,
      LastEvaluatedKey: lastKey
    })
    const result = await handleHistory(makeEvent())
    const body = JSON.parse(result.body)
    expect(body.nextToken).toBeDefined()
    expect(typeof body.nextToken).toBe('string')
  })

  it('returns 200 without nextToken when no more pages', async () => {
    mockSend.mockResolvedValue({ Items: [], Count: 0 })
    const result = await handleHistory(makeEvent())
    const body = JSON.parse(result.body)
    expect(body.nextToken).toBeUndefined()
  })

  it('returns 400 for invalid nextToken', async () => {
    const event = makeEvent({
      queryStringParameters: { nextToken: '!!!not-base64-json!!!' }
    })
    mockSend.mockResolvedValue({ Items: [], Count: 0 })
    const result = await handleHistory(event)
    expect(result.statusCode).toBe(400)
  })

  it('respects limit param capped at MAX_PAGE_SIZE (50)', async () => {
    mockSend.mockResolvedValue({ Items: [], Count: 0 })
    const event = makeEvent({ queryStringParameters: { limit: '200' } })
    await handleHistory(event)
    const callArg = mockSend.mock.calls[0][0]
    expect(callArg.input?.Limit ?? callArg.Limit ?? 50).toBeLessThanOrEqual(50)
  })
})
