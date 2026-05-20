import { Logger } from '@aws-lambda-powertools/logger';
import { Metrics, MetricUnit } from '@aws-lambda-powertools/metrics';
import {
  CognitoIdentityProviderClient,
  AdminAddUserToGroupCommand,
} from '@aws-sdk/client-cognito-identity-provider';
import type { PostConfirmationTriggerEvent } from 'aws-lambda';

const SERVICE_NAME = 'post-confirmation';

const logger = new Logger({ serviceName: SERVICE_NAME });
const metrics = new Metrics({ namespace: 'GalaxyMorph', serviceName: SERVICE_NAME });

const cognito = new CognitoIdentityProviderClient({});

const DEFAULT_GROUP = 'public-user';

export const handler = async (
  event: PostConfirmationTriggerEvent,
): Promise<PostConfirmationTriggerEvent> => {
  if (event.triggerSource !== 'PostConfirmation_ConfirmSignUp') {
    return event;
  }

  const { userPoolId, userName } = event;

  logger.info('Assigning user to default group', { userName, group: DEFAULT_GROUP });

  await cognito.send(
    new AdminAddUserToGroupCommand({
      UserPoolId: userPoolId,
      Username: userName,
      GroupName: DEFAULT_GROUP,
    }),
  );

  metrics.addMetric('UserAssignedToGroup', MetricUnit.Count, 1);
  metrics.publishStoredMetrics();

  logger.info('User assigned successfully', { userName, group: DEFAULT_GROUP });

  return event;
};
