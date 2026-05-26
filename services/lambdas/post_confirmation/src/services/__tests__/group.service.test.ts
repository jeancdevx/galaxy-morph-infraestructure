import { beforeEach, describe, expect, it, vi } from 'vitest'

import { addUserToDefaultGroup } from '../group.service.js'

const mockSend = vi.hoisted(() => vi.fn())

vi.mock('@galaxy-morph/shared', () => ({
  POWERTOOLS_NAMESPACE: 'GalaxyMorph'
}))

vi.mock('@aws-lambda-powertools/logger', () => ({
  Logger: vi.fn().mockImplementation(() => ({
    info: vi.fn(),
    error: vi.fn()
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
  AdminAddUserToGroupCommand: vi.fn()
}))

describe('addUserToDefaultGroup', () => {
  beforeEach(() => {
    mockSend.mockReset()
  })

  it('calls AdminAddUserToGroupCommand with correct params', async () => {
    mockSend.mockResolvedValue({})
    await addUserToDefaultGroup('us-east-2_abc', 'user123')
    expect(mockSend).toHaveBeenCalledOnce()
  })

  it('re-throws errors from Cognito', async () => {
    mockSend.mockRejectedValue(new Error('Cognito unavailable'))
    await expect(
      addUserToDefaultGroup('us-east-2_abc', 'user123')
    ).rejects.toThrow('Cognito unavailable')
  })
})

describe('handler (trigger routing)', () => {
  beforeEach(() => {
    mockSend.mockReset()
  })

  it('skips processing for non-ConfirmSignUp trigger sources', async () => {
    const { handler } = await import('../../handler.js')
    const event = {
      triggerSource: 'PostConfirmation_ConfirmForgotPassword',
      userPoolId: 'pool-1',
      userName: 'user-1'
    }
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const result = await handler(event as any)
    expect(mockSend).not.toHaveBeenCalled()
    expect(result).toEqual(event)
  })

  it('assigns user to public-user group on ConfirmSignUp', async () => {
    mockSend.mockResolvedValue({})
    const { handler } = await import('../../handler.js')
    const event = {
      triggerSource: 'PostConfirmation_ConfirmSignUp',
      userPoolId: 'pool-1',
      userName: 'user-1'
    }
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    await handler(event as any)
    expect(mockSend).toHaveBeenCalledOnce()
  })
})
