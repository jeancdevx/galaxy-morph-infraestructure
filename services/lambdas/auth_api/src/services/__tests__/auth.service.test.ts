import type { APIGatewayProxyEvent } from 'aws-lambda'
import { beforeEach, describe, expect, it, vi } from 'vitest'

import { handleSignIn, handleSignUp, mapCognitoError } from '../auth.service.js'

const mockSend = vi.hoisted(() => vi.fn())

vi.mock('@galaxy-morph/shared', () => ({
  jsonResponse: (status: number, body: unknown) => ({
    statusCode: status,
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body)
  }),
  resolveCorsOrigin: () => '*',
  withCors: (response: unknown) => response,
  POWERTOOLS_NAMESPACE: 'GalaxyMorph'
}))

vi.mock('@aws-lambda-powertools/logger', () => ({
  Logger: vi.fn().mockImplementation(() => ({
    appendKeys: vi.fn(),
    info: vi.fn(),
    warn: vi.fn(),
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

vi.mock('@aws-sdk/client-cognito-identity-provider', () => ({
  CognitoIdentityProviderClient: vi.fn().mockImplementation(() => ({
    send: mockSend
  })),
  SignUpCommand: vi.fn(),
  InitiateAuthCommand: vi.fn()
}))

function makeBody(email = 'test@example.com', password = 'Password1!') {
  return { email, password }
}

describe('handleSignUp', () => {
  beforeEach(() => {
    mockSend.mockReset()
  })

  it('returns 201 on success', async () => {
    mockSend.mockResolvedValue({})
    const result = await handleSignUp(makeBody())
    expect(result.statusCode).toBe(201)
    expect(JSON.parse(result.body)).toMatchObject({
      message: expect.any(String)
    })
  })

  it('propagates unexpected errors', async () => {
    mockSend.mockRejectedValue(new Error('network'))
    await expect(handleSignUp(makeBody())).rejects.toThrow('network')
  })
})

describe('handleSignIn', () => {
  beforeEach(() => {
    mockSend.mockReset()
  })

  it('returns 200 with tokens on success', async () => {
    mockSend.mockResolvedValue({
      AuthenticationResult: {
        AccessToken: 'acc',
        IdToken: 'id',
        RefreshToken: 'ref',
        ExpiresIn: 3600,
        TokenType: 'Bearer'
      }
    })
    const result = await handleSignIn(makeBody())
    expect(result.statusCode).toBe(200)
    const body = JSON.parse(result.body)
    expect(body).toMatchObject({ accessToken: 'acc', idToken: 'id' })
  })
})

describe('mapCognitoError', () => {
  it('maps UsernameExistsException to 409', () => {
    const err = Object.assign(new Error('exists'), {
      name: 'UsernameExistsException'
    })
    const result = mapCognitoError(err)
    expect(result?.statusCode).toBe(409)
  })

  it('maps NotAuthorizedException to 401', () => {
    const err = Object.assign(new Error('bad creds'), {
      name: 'NotAuthorizedException'
    })
    const result = mapCognitoError(err)
    expect(result?.statusCode).toBe(401)
  })

  it('returns undefined for unknown errors', () => {
    const err = Object.assign(new Error('boom'), { name: 'UnknownException' })
    expect(mapCognitoError(err)).toBeUndefined()
  })
})

describe('routing (handler integration)', () => {
  beforeEach(() => {
    mockSend.mockReset()
  })

  it('returns 400 when email is missing', async () => {
    const { handler } = await import('../../handler.js')
    const event = {
      path: '/auth/signup',
      httpMethod: 'POST',
      body: JSON.stringify({ password: 'pass' }),
      requestContext: {}
    } as unknown as APIGatewayProxyEvent

    mockSend.mockResolvedValue({})
    const result = await handler(event)
    expect(result.statusCode).toBe(400)
  })

  it('returns 404 for unknown path', async () => {
    const { handler } = await import('../../handler.js')
    const event = {
      path: '/auth/unknown',
      httpMethod: 'POST',
      body: JSON.stringify({ email: 'a@b.com', password: 'pass' }),
      requestContext: {}
    } as unknown as APIGatewayProxyEvent

    mockSend.mockResolvedValue({})
    const result = await handler(event)
    expect(result.statusCode).toBe(404)
  })
})
