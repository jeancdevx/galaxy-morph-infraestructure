import { type KafkaResultMessage } from '@galaxy-morph/shared'

import { APPSYNC_URL, AWS_REGION } from '../lib/clients.js'
import { signRequest, type AwsCredentials } from '../lib/sigv4.js'

const NOTIFY_MUTATION = `
  mutation NotifyClassification($input: ClassificationResultInput!) {
    notifyClassification(input: $input) {
      jobId
      clientId
      imageKey
      status
      classification {
        predictedClass
        confidence
        probabilities
      }
      errorMessage
    }
  }
`

function buildMutationVariables(message: KafkaResultMessage) {
  return {
    input: {
      jobId: message.jobId,
      clientId: message.clientId,
      imageKey: message.imageKey,
      status: message.status,
      ...(message.classification && {
        classification: {
          predictedClass: message.classification.predictedClass,
          confidence: message.classification.confidence,
          probabilities: JSON.stringify(message.classification.probabilities)
        }
      }),
      ...(message.errorMessage && { errorMessage: message.errorMessage })
    }
  }
}

export async function callAppSyncMutation(
  message: KafkaResultMessage
): Promise<void> {
  const body = JSON.stringify({
    query: NOTIFY_MUTATION,
    variables: buildMutationVariables(message)
  })

  const url = new URL(APPSYNC_URL)

  const credentials: AwsCredentials = {
    accessKeyId: process.env.AWS_ACCESS_KEY_ID!,
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY!,
    sessionToken: process.env.AWS_SESSION_TOKEN
  }

  const headers = signRequest(
    url.hostname,
    url.pathname,
    body,
    credentials,
    AWS_REGION
  )

  const response = await fetch(APPSYNC_URL, { method: 'POST', headers, body })

  if (!response.ok) {
    const text = await response.text()
    throw new Error(`AppSync mutation failed: ${response.status} ${text}`)
  }

  const json = (await response.json()) as {
    errors?: Array<{ message: string }>
  }

  if (json.errors && json.errors.length > 0) {
    throw new Error(
      `AppSync errors: ${json.errors.map(e => e.message).join(', ')}`
    )
  }
}
