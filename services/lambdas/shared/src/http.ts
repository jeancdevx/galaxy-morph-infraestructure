import type { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda'

export function resolveCorsOrigin(event: APIGatewayProxyEvent): string {
  const allowed = (process.env.CORS_ALLOW_ORIGINS ?? '*')
    .split(',')
    .map(o => o.trim())
    .filter(Boolean)

  if (allowed.includes('*')) return '*'

  const requestOrigin = event.headers['origin'] ?? event.headers['Origin'] ?? ''
  return allowed.includes(requestOrigin) ? requestOrigin : (allowed[0] ?? '*')
}

export function withCors(
  response: APIGatewayProxyResult,
  corsOrigin: string
): APIGatewayProxyResult {
  return {
    ...response,
    headers: { ...response.headers, 'Access-Control-Allow-Origin': corsOrigin }
  }
}

export function jsonResponse(
  statusCode: number,
  body: unknown,
  corsOrigin?: string
): APIGatewayProxyResult {
  return {
    statusCode,
    headers: {
      'Content-Type': 'application/json',
      ...(corsOrigin ? { 'Access-Control-Allow-Origin': corsOrigin } : {})
    },
    body: JSON.stringify(body)
  }
}
