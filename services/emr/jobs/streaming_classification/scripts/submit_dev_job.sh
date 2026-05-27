#!/usr/bin/env bash
# Submit a pre-built artifact to EMR Serverless as a streaming job.
#
# Prerequisites:
#   1. Terraform applied — S3 buckets, IAM role and EMR Serverless app must exist.
#   2. Artifact uploaded — run `make upload` from the job directory first.
#
# Usage:
#   INFERENCE_MODE=stub ./scripts/submit_dev_job.sh
#   INFERENCE_MODE=sagemaker SAGEMAKER_ENDPOINT_NAME=<name> ./scripts/submit_dev_job.sh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../../.." && pwd)"
DEV_TF_DIR="$ROOT_DIR/iac/environments/dev"

AWS_REGION="${AWS_REGION:-us-east-2}"
AWS_PROFILE="${AWS_PROFILE:-default}"
INFERENCE_MODE="${INFERENCE_MODE:-sagemaker}"
SAGEMAKER_ENDPOINT_NAME="${SAGEMAKER_ENDPOINT_NAME:-}"
IMAGES_BUCKET="${IMAGES_BUCKET:-galaxy-morph-images}"
CHECKPOINT_S3_URI="${CHECKPOINT_S3_URI:-s3://galaxy-morph-checkpoints/streaming-classification/}"
TRIGGER_INTERVAL_SECONDS="${TRIGGER_INTERVAL_SECONDS:-5}"
INFERENCE_RETRIES="${INFERENCE_RETRIES:-3}"
CHECKPOINTS_BUCKET="${CHECKPOINTS_BUCKET:-galaxy-morph-checkpoints}"
ARTIFACT_S3_PREFIX="${ARTIFACT_S3_PREFIX:-emr/jobs/streaming_classification/latest}"

# Read infrastructure values from Terraform state
APP_ID="$(cd "$DEV_TF_DIR" && terraform output -raw emr_serverless_application_id)"
ROLE_ARN="$(cd "$DEV_TF_DIR" && terraform output -raw emr_serverless_execution_role_arn)"
BROKERS="$(cd "$DEV_TF_DIR" && terraform output -raw data_layer_msk_bootstrap_brokers_sasl_iam)"

# Auto-resolve SAGEMAKER_ENDPOINT_NAME from Terraform when not provided
if [[ "$INFERENCE_MODE" == "sagemaker" && -z "$SAGEMAKER_ENDPOINT_NAME" ]]; then
  SAGEMAKER_ENDPOINT_NAME="$(cd "$DEV_TF_DIR" && terraform output -raw sagemaker_endpoint_name 2>/dev/null || true)"
  if [[ -z "$SAGEMAKER_ENDPOINT_NAME" ]]; then
    echo "ERROR: SAGEMAKER_ENDPOINT_NAME not found in Terraform outputs. Deploy SageMaker endpoint first or pass it explicitly." >&2
    exit 1
  fi
  echo "INFO: Using SageMaker endpoint from Terraform: $SAGEMAKER_ENDPOINT_NAME"
fi

ENTRY_POINT="s3://${CHECKPOINTS_BUCKET}/${ARTIFACT_S3_PREFIX}/main_streaming.py"
PY_FILES="s3://${CHECKPOINTS_BUCKET}/${ARTIFACT_S3_PREFIX}/deps.zip"

SPARK_PARAMS="--py-files ${PY_FILES}"
SPARK_PARAMS+=" --packages org.apache.spark:spark-sql-kafka-0-10_2.12:3.5.0,software.amazon.msk:aws-msk-iam-auth:1.1.9"

# Keep at least 2 executors alive between micro-batches so Spark does not
# release them back to EMR after each batch completes (DRA default idle
# timeout is 60 s, which causes the add/remove cycling visible in Spark UI).
SPARK_PARAMS+=" --conf spark.dynamicAllocation.minExecutors=2"
SPARK_PARAMS+=" --conf spark.dynamicAllocation.maxExecutors=24"
SPARK_PARAMS+=" --conf spark.dynamicAllocation.executorIdleTimeout=300"
SPARK_PARAMS+=" --conf spark.dynamicAllocation.shuffleTracking.enabled=true"

# Match executor/driver resources to the pre-warmed initial_capacity config
# (4 vCPU / 8 GB per executor) so EMR reuses pre-warmed workers instead of
# provisioning new ones on first batch.
SPARK_PARAMS+=" --conf spark.executor.cores=4"
SPARK_PARAMS+=" --conf spark.executor.memory=6g"
SPARK_PARAMS+=" --conf spark.executor.memoryOverhead=2g"
SPARK_PARAMS+=" --conf spark.driver.cores=2"
SPARK_PARAMS+=" --conf spark.driver.memory=3g"
SPARK_PARAMS+=" --conf spark.driver.memoryOverhead=1g"

# Pass config as spark.app.* Spark conf properties.
# main_streaming.py reads these via SparkConf and injects them into os.environ
# before importing config.py — the EMR-native pattern for PySpark jobs.
SPARK_PARAMS+=" --conf spark.app.aws_region=${AWS_REGION}"
SPARK_PARAMS+=" --conf spark.app.kafka_bootstrap_servers=${BROKERS}"
SPARK_PARAMS+=" --conf spark.app.kafka_ingestion_topic=galaxy.ingestion"
SPARK_PARAMS+=" --conf spark.app.kafka_results_topic=galaxy.results"
SPARK_PARAMS+=" --conf spark.app.kafka_group_id=galaxy-morph-emr-streaming"
SPARK_PARAMS+=" --conf spark.app.images_bucket=${IMAGES_BUCKET}"
SPARK_PARAMS+=" --conf spark.app.inference_mode=${INFERENCE_MODE}"
SPARK_PARAMS+=" --conf spark.app.checkpoint_s3_uri=${CHECKPOINT_S3_URI}"
SPARK_PARAMS+=" --conf spark.app.trigger_interval_seconds=${TRIGGER_INTERVAL_SECONDS}"
SPARK_PARAMS+=" --conf spark.app.inference_retries=${INFERENCE_RETRIES}"
if [[ -n "${SAGEMAKER_ENDPOINT_NAME}" ]]; then
  SPARK_PARAMS+=" --conf spark.app.sagemaker_endpoint_name=${SAGEMAKER_ENDPOINT_NAME}"
fi

TIMESTAMP="$(date +%Y%m%d-%H%M%S)"

JOB_ID="$(aws emr-serverless start-job-run \
  --application-id "$APP_ID" \
  --execution-role-arn "$ROLE_ARN" \
  --name "streaming-classification-${TIMESTAMP}" \
  --job-driver "{\"sparkSubmit\":{\"entryPoint\":\"$ENTRY_POINT\",\"sparkSubmitParameters\":\"$SPARK_PARAMS\"}}" \
  --configuration-overrides "{\"monitoringConfiguration\":{\"cloudWatchLoggingConfiguration\":{\"enabled\":true},\"s3MonitoringConfiguration\":{\"logUri\":\"s3://${CHECKPOINTS_BUCKET}/emr-serverless/logs/\"}}}" \
  --execution-timeout-minutes 0 \
  --tags project=galaxy-morph,env=dev,component=streaming-classification \
  --profile "$AWS_PROFILE" \
  --region "$AWS_REGION" \
  --query 'jobRunId' \
  --output text
)"

echo "applicationId=$APP_ID"
echo "jobRunId=$JOB_ID"
