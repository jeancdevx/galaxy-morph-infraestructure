import { CognitoIdentityProviderClient } from '@aws-sdk/client-cognito-identity-provider'

export const cognito = new CognitoIdentityProviderClient({})

export const DEFAULT_GROUP = 'public-user'
