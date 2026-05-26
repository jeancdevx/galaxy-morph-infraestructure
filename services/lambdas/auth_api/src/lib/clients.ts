import { CognitoIdentityProviderClient } from '@aws-sdk/client-cognito-identity-provider'

import { tracer } from './powertools.js'

export const cognito = tracer.captureAWSv3Client(
  new CognitoIdentityProviderClient({})
)

export const CLIENT_ID = process.env.CLIENT_ID!
