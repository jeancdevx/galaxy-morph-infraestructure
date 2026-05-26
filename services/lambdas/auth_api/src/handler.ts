import { MetricUnit } from '@aws-lambda-powertools/metrics'
import {
  type APIGatewayProxyEvent,
  type APIGatewayProxyResult
} from 'aws-lambda'

import { jsonResponse } from '@galaxy-morph/shared'

import { logger, metrics } from './lib/powertools.js'
import {
  handleSignIn,
  handleSignUp,
  mapCognitoError,
  type AuthBody
} from './services/auth.service.js'

export const handler = async (
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> => {
  logger.appendKeys({ path: event.path, method: event.httpMethod })

  try {
    const rawBody = JSON.parse(event.body ?? '{}') as Partial<AuthBody>

    if (!rawBody.email || !rawBody.password) {
      return jsonResponse(400, { message: 'email and password are required' })
    }

    const body: AuthBody = { email: rawBody.email, password: rawBody.password }

    if (event.path.endsWith('/signup')) return await handleSignUp(body)
    if (event.path.endsWith('/signin')) return await handleSignIn(body)

    return jsonResponse(404, { message: 'Not found' })
  } catch (err) {
    logger.error('Auth handler error', { error: err })

    const mapped = mapCognitoError(err)
    if (mapped) return mapped

    metrics.addMetric('AuthServerError', MetricUnit.Count, 1)
    return jsonResponse(500, { message: 'Internal server error' })
  } finally {
    metrics.publishStoredMetrics()
  }
}
