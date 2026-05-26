import { MetricUnit } from '@aws-lambda-powertools/metrics'
import { type PostConfirmationTriggerEvent } from 'aws-lambda'

import { DEFAULT_GROUP } from './lib/clients.js'
import { logger, metrics } from './lib/powertools.js'
import { addUserToDefaultGroup } from './services/group.service.js'

export const handler = async (
  event: PostConfirmationTriggerEvent
): Promise<PostConfirmationTriggerEvent> => {
  if (event.triggerSource !== 'PostConfirmation_ConfirmSignUp') {
    return event
  }

  const { userPoolId, userName } = event

  logger.info('Assigning user to default group', {
    userName,
    group: DEFAULT_GROUP
  })

  await addUserToDefaultGroup(userPoolId, userName)

  metrics.addMetric('UserAssignedToGroup', MetricUnit.Count, 1)
  metrics.publishStoredMetrics()

  logger.info('User assigned successfully', { userName, group: DEFAULT_GROUP })

  return event
}
