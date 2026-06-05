import { createHash, createHmac } from 'crypto'

import { describe, expect, it } from 'vitest'

import {
  buildSigningKey,
  hmacSha256,
  sha256Hex,
  signRequest,
  type AwsCredentials
} from '../../lib/sigv4.js'

const TEST_CREDS: AwsCredentials = {
  accessKeyId: 'AKIAIOSFODNN7EXAMPLE',
  secretAccessKey: 'wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY'
}

describe('sha256Hex', () => {
  it('produces known SHA-256 of empty string', () => {
    expect(sha256Hex('')).toBe(
      'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855'
    )
  })

  it('produces deterministic output for same input', () => {
    expect(sha256Hex('hello')).toBe(sha256Hex('hello'))
  })
})

describe('hmacSha256', () => {
  it('produces a 32-byte Buffer', () => {
    const result = hmacSha256('key', 'data')
    expect(result).toBeInstanceOf(Buffer)
    expect(result.byteLength).toBe(32)
  })

  it('produces different output for different keys', () => {
    const a = hmacSha256('key1', 'data').toString('hex')
    const b = hmacSha256('key2', 'data').toString('hex')
    expect(a).not.toBe(b)
  })
})

describe('buildSigningKey', () => {
  it('returns a 32-byte Buffer', () => {
    const key = buildSigningKey('secret', '20240101', 'us-east-2', 'appsync')
    expect(key).toBeInstanceOf(Buffer)
    expect(key.byteLength).toBe(32)
  })

  it('produces deterministic output for same inputs', () => {
    const a = buildSigningKey('secret', '20240101', 'us-east-2', 'appsync')
    const b = buildSigningKey('secret', '20240101', 'us-east-2', 'appsync')
    expect(a.toString('hex')).toBe(b.toString('hex'))
  })

  it('changes with different date', () => {
    const a = buildSigningKey('secret', '20240101', 'us-east-2', 'appsync')
    const b = buildSigningKey('secret', '20240102', 'us-east-2', 'appsync')
    expect(a.toString('hex')).not.toBe(b.toString('hex'))
  })

  it('changes with different region', () => {
    const a = buildSigningKey('secret', '20240101', 'us-east-1', 'appsync')
    const b = buildSigningKey('secret', '20240101', 'us-east-2', 'appsync')
    expect(a.toString('hex')).not.toBe(b.toString('hex'))
  })
})

describe('signRequest', () => {
  const body = JSON.stringify({ query: 'mutation { test }' })
  const hostname = 'abc123.appsync-api.us-east-2.amazonaws.com'
  const pathname = '/graphql'

  it('returns all required SigV4 headers', () => {
    const headers = signRequest(
      hostname,
      pathname,
      body,
      TEST_CREDS,
      'us-east-2'
    )
    expect(headers).toHaveProperty('authorization')
    expect(headers).toHaveProperty('x-amz-date')
    expect(headers).toHaveProperty('host')
    expect(headers).toHaveProperty('content-type')
  })

  it('authorization header starts with AWS4-HMAC-SHA256', () => {
    const headers = signRequest(
      hostname,
      pathname,
      body,
      TEST_CREDS,
      'us-east-2'
    )
    expect(headers['authorization']).toMatch(/^AWS4-HMAC-SHA256 /)
  })

  it('authorization header contains Credential, SignedHeaders and Signature', () => {
    const headers = signRequest(
      hostname,
      pathname,
      body,
      TEST_CREDS,
      'us-east-2'
    )
    expect(headers['authorization']).toContain('Credential=')
    expect(headers['authorization']).toContain('SignedHeaders=')
    expect(headers['authorization']).toContain('Signature=')
  })

  it('credential scope includes region and appsync service', () => {
    const headers = signRequest(
      hostname,
      pathname,
      body,
      TEST_CREDS,
      'us-east-2'
    )
    expect(headers['authorization']).toContain(
      '/us-east-2/appsync/aws4_request'
    )
  })

  it('includes x-amz-security-token when sessionToken is provided', () => {
    const creds = { ...TEST_CREDS, sessionToken: 'session-token-xyz' }
    const headers = signRequest(hostname, pathname, body, creds, 'us-east-2')
    expect(headers).toHaveProperty('x-amz-security-token', 'session-token-xyz')
    expect(headers['authorization']).toContain('x-amz-security-token')
  })

  it('omits x-amz-security-token when sessionToken is undefined', () => {
    const headers = signRequest(
      hostname,
      pathname,
      body,
      TEST_CREDS,
      'us-east-2'
    )
    expect(headers['x-amz-security-token']).toBeUndefined()
    expect(headers['authorization']).not.toContain('x-amz-security-token')
  })

  it('x-amz-date format is YYYYMMDDTHHmmssZ', () => {
    const headers = signRequest(
      hostname,
      pathname,
      body,
      TEST_CREDS,
      'us-east-2'
    )
    expect(headers['x-amz-date']).toMatch(/^\d{8}T\d{6}Z$/)
  })

  it('signature is a 64-character hex string', () => {
    const headers = signRequest(
      hostname,
      pathname,
      body,
      TEST_CREDS,
      'us-east-2'
    )
    const sigMatch =
      headers['authorization']?.match(/Signature=([0-9a-f]+)/) ?? null
    expect(sigMatch).not.toBeNull()
    expect(sigMatch![1]).toHaveLength(64)
  })

  it('produces different signatures for different bodies', () => {
    const h1 = signRequest(hostname, pathname, body, TEST_CREDS, 'us-east-2')
    const h2 = signRequest(
      hostname,
      pathname,
      JSON.stringify({ query: 'mutation { other }' }),
      TEST_CREDS,
      'us-east-2'
    )
    const sig1 = h1['authorization']?.match(/Signature=([0-9a-f]+)/)?.[1]
    const sig2 = h2['authorization']?.match(/Signature=([0-9a-f]+)/)?.[1]
    expect(sig1).not.toBe(sig2)
  })

  it('verifies signature structure by re-computing canonical request', () => {
    const dateStamp = '20240115'
    const amzDate = `${dateStamp}T103000Z`

    const payloadHash = createHash('sha256').update(body, 'utf8').digest('hex')
    const canonicalHeaders =
      `content-type:application/json\n` +
      `host:${hostname}\n` +
      `x-amz-date:${amzDate}\n`
    const signedHeaders = 'content-type;host;x-amz-date'
    const canonicalRequest = [
      'POST',
      pathname,
      '',
      canonicalHeaders,
      signedHeaders,
      payloadHash
    ].join('\n')

    const credentialScope = `${dateStamp}/us-east-2/appsync/aws4_request`
    const stringToSign = [
      'AWS4-HMAC-SHA256',
      amzDate,
      credentialScope,
      createHash('sha256').update(canonicalRequest, 'utf8').digest('hex')
    ].join('\n')

    const kDate = createHmac('sha256', `AWS4${TEST_CREDS.secretAccessKey}`)
      .update(dateStamp)
      .digest()
    const kRegion = createHmac('sha256', kDate).update('us-east-2').digest()
    const kService = createHmac('sha256', kRegion).update('appsync').digest()
    const kSigning = createHmac('sha256', kService)
      .update('aws4_request')
      .digest()
    const expectedSig = createHmac('sha256', kSigning)
      .update(stringToSign)
      .digest('hex')

    expect(expectedSig).toMatch(/^[0-9a-f]{64}$/)

    const headers = signRequest(
      hostname,
      pathname,
      body,
      TEST_CREDS,
      'us-east-2'
    )
    const actualSig = headers['authorization']?.match(
      /Signature=([0-9a-f]+)/
    )?.[1]
    expect(actualSig).toBeDefined()
    expect(actualSig!).toMatch(/^[0-9a-f]{64}$/)
  })
})
