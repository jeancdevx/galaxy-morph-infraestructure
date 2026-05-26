import type { APIGatewayProxyResult } from 'aws-lambda'

export function jsonResponse(
  statusCode: number,
  body: unknown
): APIGatewayProxyResult {
  return {
    statusCode,
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body)
  }
}
