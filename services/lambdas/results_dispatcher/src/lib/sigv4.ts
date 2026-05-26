import { createHash, createHmac } from 'crypto'

export function sha256Hex(data: string): string {
  return createHash('sha256').update(data, 'utf8').digest('hex')
}

export function hmacSha256(key: Buffer | string, data: string): Buffer {
  return createHmac('sha256', key).update(data, 'utf8').digest()
}

export function buildSigningKey(
  secretKey: string,
  date: string,
  region: string,
  service: string
): Buffer {
  const kDate = hmacSha256(`AWS4${secretKey}`, date)
  const kRegion = hmacSha256(kDate, region)
  const kService = hmacSha256(kRegion, service)
  return hmacSha256(kService, 'aws4_request')
}

export interface AwsCredentials {
  accessKeyId: string
  secretAccessKey: string
  sessionToken?: string
}

export function signRequest(
  hostname: string,
  pathname: string,
  body: string,
  credentials: AwsCredentials,
  region: string
): Record<string, string> {
  const now = new Date()
  const amzDate = now
    .toISOString()
    .replace(/[:-]/g, '')
    .replace(/\.\d{3}/, '')
  const dateStamp = amzDate.slice(0, 8)
  const contentType = 'application/json'
  const service = 'appsync'

  const canonicalHeaders =
    `content-type:${contentType}\n` +
    `host:${hostname}\n` +
    `x-amz-date:${amzDate}\n` +
    (credentials.sessionToken
      ? `x-amz-security-token:${credentials.sessionToken}\n`
      : '')

  const signedHeaders =
    'content-type;host;x-amz-date' +
    (credentials.sessionToken ? ';x-amz-security-token' : '')

  const payloadHash = sha256Hex(body)
  const canonicalRequest = [
    'POST',
    pathname,
    '',
    canonicalHeaders,
    signedHeaders,
    payloadHash
  ].join('\n')

  const credentialScope = `${dateStamp}/${region}/${service}/aws4_request`
  const stringToSign = [
    'AWS4-HMAC-SHA256',
    amzDate,
    credentialScope,
    sha256Hex(canonicalRequest)
  ].join('\n')

  const signingKey = buildSigningKey(
    credentials.secretAccessKey,
    dateStamp,
    region,
    service
  )
  const signature = createHmac('sha256', signingKey)
    .update(stringToSign, 'utf8')
    .digest('hex')

  const authHeader =
    `AWS4-HMAC-SHA256 Credential=${credentials.accessKeyId}/${credentialScope}, ` +
    `SignedHeaders=${signedHeaders}, Signature=${signature}`

  const headers: Record<string, string> = {
    'content-type': contentType,
    host: hostname,
    'x-amz-date': amzDate,
    authorization: authHeader
  }

  if (credentials.sessionToken) {
    headers['x-amz-security-token'] = credentials.sessionToken
  }

  return headers
}
