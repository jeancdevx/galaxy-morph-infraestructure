import { AdminAddUserToGroupCommand } from '@aws-sdk/client-cognito-identity-provider'

import { cognito, DEFAULT_GROUP } from '../lib/clients.js'

export async function addUserToDefaultGroup(
  userPoolId: string,
  userName: string
): Promise<void> {
  await cognito.send(
    new AdminAddUserToGroupCommand({
      UserPoolId: userPoolId,
      Username: userName,
      GroupName: DEFAULT_GROUP
    })
  )
}
