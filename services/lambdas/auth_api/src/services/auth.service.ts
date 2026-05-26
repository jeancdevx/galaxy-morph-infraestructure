import { MetricUnit } from '@aws-lambda-powertools/metrics'
import type { CognitoIdentityProviderServiceException } from '@aws-sdk/client-cognito-identity-provider'
import {
  InitiateAuthCommand,
  SignUpCommand
} from '@aws-sdk/client-cognito-identity-provider'
import { type APIGatewayProxyResult } from 'aws-lambda'

import { jsonResponse } from '@galaxy-morph/shared'

import { CLIENT_ID, cognito } from '../lib/clients.js'
import { logger, metrics } from '../lib/powertools.js'

export interface AuthBody {
  email: string
  password: string
}

export const COGNITO_ERROR_MAP: Record<string, [number, string]> = {
  UsernameExistsException: [409, 'Email already registered'],
  InvalidPasswordException: [400, ''],
  NotAuthorizedException: [401, 'Invalid credentials'],
  UserNotConfirmedException: [403, 'Please confirm your email first'],
  UserNotFoundException: [401, 'Invalid credentials'],
  InvalidParameterException: [400, '']
}

export async function handleSignUp(
  body: AuthBody
): Promise<APIGatewayProxyResult> {
  await cognito.send(
    new SignUpCommand({
      ClientId: CLIENT_ID,
      Username: body.email,
      Password: body.password,
      UserAttributes: [{ Name: 'email', Value: body.email }]
    })
  )

  metrics.addMetric('SignUpSuccess', MetricUnit.Count, 1)
  return jsonResponse(201, {
    message: 'User registered. Check your email to confirm your account.'
  })
}

export async function handleSignIn(
  body: AuthBody
): Promise<APIGatewayProxyResult> {
  const result = await cognito.send(
    new InitiateAuthCommand({
      AuthFlow: 'USER_PASSWORD_AUTH',
      ClientId: CLIENT_ID,
      AuthParameters: {
        USERNAME: body.email,
        PASSWORD: body.password
      }
    })
  )

  const tokens = result.AuthenticationResult!
  metrics.addMetric('SignInSuccess', MetricUnit.Count, 1)

  return jsonResponse(200, {
    accessToken: tokens.AccessToken,
    idToken: tokens.IdToken,
    refreshToken: tokens.RefreshToken,
    expiresIn: tokens.ExpiresIn,
    tokenType: tokens.TokenType
  })
}

export function mapCognitoError(
  err: unknown
): APIGatewayProxyResult | undefined {
  const cognitoErr = err as CognitoIdentityProviderServiceException
  const mapped = COGNITO_ERROR_MAP[cognitoErr.name ?? '']
  if (!mapped) return undefined

  const [status, defaultMsg] = mapped
  const message = defaultMsg !== '' ? defaultMsg : cognitoErr.message
  metrics.addMetric('AuthClientError', MetricUnit.Count, 1)
  logger.warn('Cognito client error', { name: cognitoErr.name, status })
  return jsonResponse(status, { message })
}
