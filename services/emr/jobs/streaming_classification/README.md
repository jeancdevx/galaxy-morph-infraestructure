# Streaming Classification Job (EMR Serverless)

Spark Structured Streaming job for Q6:
- Consumes `galaxy.ingestion` from MSK (IAM auth)
- Publishes classification results to `galaxy.results`
- Supports `INFERENCE_MODE=stub` (Q6 default) and `INFERENCE_MODE=sagemaker` (Q7)
- Emits throughput and latency telemetry per micro-batch

## Runtime Environment Variables
- `AWS_REGION`
- `KAFKA_BOOTSTRAP_SERVERS`
- `KAFKA_INGESTION_TOPIC`
- `KAFKA_RESULTS_TOPIC`
- `KAFKA_GROUP_ID`
- `IMAGES_BUCKET`
- `INFERENCE_MODE` (`stub` by default)
- `SAGEMAKER_ENDPOINT_NAME`
- `CHECKPOINT_S3_URI`
- `TRIGGER_INTERVAL`
- `INFERENCE_RETRIES`

## Q6 vs Q7 Inference Scope
- Q6 uses `INFERENCE_MODE=stub` to process real streaming events in dev without SageMaker.
- Q7 enables `INFERENCE_MODE=sagemaker` with endpoint provisioning and health metrics.

## Error Handling and Retries
- Inference calls use exponential backoff (`retry_with_backoff`) in `INFERENCE_MODE=sagemaker`
- On per-record failure, an `ERROR` payload is published to results topic
- Stream keeps running when individual records fail

## Preliminary SLO (Dev)
- Batch processing trigger: 5 seconds
- Target P95 end-to-end batch latency: <= 30 seconds in dev
- Target throughput baseline: >= 10 messages/sec sustained in dev smoke tests
