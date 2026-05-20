import { Logger } from '@aws-lambda-powertools/logger';
import { Tracer } from '@aws-lambda-powertools/tracer';
import { Metrics, MetricUnit } from '@aws-lambda-powertools/metrics';
import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import type { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { randomUUID } from 'crypto';

const SERVICE_NAME = 'upload-api';

const logger = new Logger({ serviceName: SERVICE_NAME });
const tracer = new Tracer({ serviceName: SERVICE_NAME });
const metrics = new Metrics({ namespace: 'GalaxyMorph', serviceName: SERVICE_NAME });

const s3 = tracer.captureAWSv3Client(new S3Client({}));

const IMAGES_BUCKET = process.env.IMAGES_BUCKET_NAME!;
const PRESIGNED_URL_EXPIRES_SECONDS = 3600;
const MAX_IMAGES_PER_REQUEST = 20;

interface ImageInput {
  filename: string;
  contentType: string;
}

interface PresignedUpload {
  key: string;
  uploadUrl: string;
  expiresIn: number;
}

function jsonResponse(statusCode: number, body: unknown): APIGatewayProxyResult {
  return {
    statusCode,
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  };
}

export const handler = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  logger.appendKeys({ path: event.path, method: event.httpMethod });

  try {
    const body = JSON.parse(event.body ?? '{}') as { images?: Partial<ImageInput>[] };

    if (!Array.isArray(body.images) || body.images.length === 0) {
      return jsonResponse(400, { message: 'images array is required and must not be empty' });
    }

    if (body.images.length > MAX_IMAGES_PER_REQUEST) {
      return jsonResponse(400, {
        message: `Maximum ${MAX_IMAGES_PER_REQUEST} images per request`,
      });
    }

    const userId = event.requestContext.authorizer?.claims?.['sub'] as string;
    const batchId = randomUUID();

    const uploads: PresignedUpload[] = await Promise.all(
      body.images.map(async (img) => {
        if (!img.filename || !img.contentType) {
          throw new Error('Each image must have filename and contentType');
        }

        const key = `galaxies/${userId}/${batchId}/${img.filename}`;

        const command = new PutObjectCommand({
          Bucket: IMAGES_BUCKET,
          Key: key,
          ContentType: img.contentType,
        });

        const uploadUrl = await getSignedUrl(s3, command, {
          expiresIn: PRESIGNED_URL_EXPIRES_SECONDS,
        });

        return { key, uploadUrl, expiresIn: PRESIGNED_URL_EXPIRES_SECONDS };
      }),
    );

    metrics.addMetric('PresignedUrlsGenerated', MetricUnit.Count, uploads.length);

    return jsonResponse(200, { uploads });
  } catch (err) {
    const error = err as Error;

    if (error.message.includes('filename') || error.message.includes('contentType')) {
      return jsonResponse(400, { message: error.message });
    }

    logger.error('Upload API error', { error });
    metrics.addMetric('UploadApiError', MetricUnit.Count, 1);
    return jsonResponse(500, { message: 'Internal server error' });
  } finally {
    metrics.publishStoredMetrics();
  }
};
