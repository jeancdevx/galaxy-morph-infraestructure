import { Logger } from '@aws-lambda-powertools/logger';
import { Tracer } from '@aws-lambda-powertools/tracer';
import { Metrics, MetricUnit } from '@aws-lambda-powertools/metrics';
import {
  CognitoIdentityProviderClient,
  InitiateAuthCommand,
  SignUpCommand,
  type CognitoIdentityProviderServiceException,
} from '@aws-sdk/client-cognito-identity-provider';
import type { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';

const SERVICE_NAME = 'auth-api';

const logger = new Logger({ serviceName: SERVICE_NAME });
const tracer = new Tracer({ serviceName: SERVICE_NAME });
const metrics = new Metrics({ namespace: 'GalaxyMorph', serviceName: SERVICE_NAME });

const cognito = tracer.captureAWSv3Client(new CognitoIdentityProviderClient({}));

const CLIENT_ID = process.env.CLIENT_ID!;

interface AuthBody {
  email: string;
  password: string;
}

function jsonResponse(statusCode: number, body: unknown): APIGatewayProxyResult {
  return {
    statusCode,
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  };
}

async function handleSignUp(body: AuthBody): Promise<APIGatewayProxyResult> {
  await cognito.send(
    new SignUpCommand({
      ClientId: CLIENT_ID,
      Username: body.email,
      Password: body.password,
      UserAttributes: [{ Name: 'email', Value: body.email }],
    }),
  );

  metrics.addMetric('SignUpSuccess', MetricUnit.Count, 1);
  return jsonResponse(201, {
    message: 'User registered. Check your email to confirm your account.',
  });
}

async function handleSignIn(body: AuthBody): Promise<APIGatewayProxyResult> {
  const result = await cognito.send(
    new InitiateAuthCommand({
      AuthFlow: 'USER_PASSWORD_AUTH',
      ClientId: CLIENT_ID,
      AuthParameters: {
        USERNAME: body.email,
        PASSWORD: body.password,
      },
    }),
  );

  const tokens = result.AuthenticationResult!;
  metrics.addMetric('SignInSuccess', MetricUnit.Count, 1);

  return jsonResponse(200, {
    accessToken: tokens.AccessToken,
    idToken: tokens.IdToken,
    refreshToken: tokens.RefreshToken,
    expiresIn: tokens.ExpiresIn,
    tokenType: tokens.TokenType,
  });
}

const COGNITO_ERROR_MAP: Record<string, [number, string]> = {
  UsernameExistsException: [409, 'Email already registered'],
  InvalidPasswordException: [400, ''],
  NotAuthorizedException: [401, 'Invalid credentials'],
  UserNotConfirmedException: [403, 'Please confirm your email first'],
  UserNotFoundException: [401, 'Invalid credentials'],
  InvalidParameterException: [400, ''],
};

export const handler = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  logger.appendKeys({ path: event.path, method: event.httpMethod });

  try {
    const rawBody = JSON.parse(event.body ?? '{}') as Partial<AuthBody>;

    if (!rawBody.email || !rawBody.password) {
      return jsonResponse(400, { message: 'email and password are required' });
    }

    const body: AuthBody = { email: rawBody.email, password: rawBody.password };

    if (event.path.endsWith('/signup')) return await handleSignUp(body);
    if (event.path.endsWith('/signin')) return await handleSignIn(body);

    return jsonResponse(404, { message: 'Not found' });
  } catch (err) {
    logger.error('Auth handler error', { error: err });

    const cognitoErr = err as CognitoIdentityProviderServiceException;
    const mapped = COGNITO_ERROR_MAP[cognitoErr.name ?? ''];
    if (mapped) {
      const [status, defaultMsg] = mapped;
      const message = defaultMsg !== '' ? defaultMsg : cognitoErr.message;
      metrics.addMetric('AuthClientError', MetricUnit.Count, 1);
      return jsonResponse(status, { message });
    }

    metrics.addMetric('AuthServerError', MetricUnit.Count, 1);
    return jsonResponse(500, { message: 'Internal server error' });
  } finally {
    metrics.publishStoredMetrics();
  }
};
