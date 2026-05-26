export type { APIGatewayProxyResult } from 'aws-lambda'

export const POWERTOOLS_NAMESPACE = 'GalaxyMorph' as const

export type ClassificationStatus =
  | 'QUEUED'
  | 'PROCESSING'
  | 'COMPLETED'
  | 'FAILED'

export interface ClassificationResult {
  predictedClass: string
  confidence: number
  probabilities: Record<string, number>
}

export interface KafkaResultMessage {
  jobId: string
  clientId: string
  imageKey: string
  status: 'SUCCESS' | 'FAILED'
  classification?: ClassificationResult
  errorMessage?: string
}

export interface ImageRef {
  key: string
}

export interface JobRecord {
  pk: string
  sk: string
  entityType: string
  jobId: string
  userId: string
  imageCount: number
  status: ClassificationStatus
  processedCount: number
  createdAt: string
  images: string[]
}
