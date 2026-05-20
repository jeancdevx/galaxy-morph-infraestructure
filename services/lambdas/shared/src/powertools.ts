import { Logger } from '@aws-lambda-powertools/logger';
import { Tracer } from '@aws-lambda-powertools/tracer';
import { Metrics } from '@aws-lambda-powertools/metrics';

export interface Powertools {
  logger: Logger;
  tracer: Tracer;
  metrics: Metrics;
}

export function createPowertools(serviceName: string): Powertools {
  return {
    logger: new Logger({ serviceName }),
    tracer: new Tracer({ serviceName }),
    metrics: new Metrics({ namespace: 'GalaxyMorph', serviceName }),
  };
}
