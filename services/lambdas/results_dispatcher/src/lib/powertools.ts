import { Logger } from '@aws-lambda-powertools/logger'
import { Metrics } from '@aws-lambda-powertools/metrics'
import { Tracer } from '@aws-lambda-powertools/tracer'

import { POWERTOOLS_NAMESPACE } from '@galaxy-morph/shared'

const SERVICE_NAME = 'results-dispatcher'

export const logger = new Logger({ serviceName: SERVICE_NAME })
export const tracer = new Tracer({ serviceName: SERVICE_NAME })
export const metrics = new Metrics({
  namespace: POWERTOOLS_NAMESPACE,
  serviceName: SERVICE_NAME
})
