"""Runtime configuration for streaming_classification job."""

from __future__ import annotations

import os

AWS_REGION = os.environ.get("AWS_REGION", "us-east-2")
KAFKA_BOOTSTRAP_SERVERS = os.environ.get("KAFKA_BOOTSTRAP_SERVERS", "")
KAFKA_INGESTION_TOPIC = os.environ.get("KAFKA_INGESTION_TOPIC", "galaxy.ingestion")
KAFKA_RESULTS_TOPIC = os.environ.get("KAFKA_RESULTS_TOPIC", "galaxy.results")
KAFKA_GROUP_ID = os.environ.get("KAFKA_GROUP_ID", "galaxy-morph-emr-streaming")

IMAGES_BUCKET = os.environ.get("IMAGES_BUCKET", "galaxy-morph-images")
INFERENCE_MODE = os.environ.get("INFERENCE_MODE", "sagemaker").lower()
SAGEMAKER_ENDPOINT_NAME = os.environ.get("SAGEMAKER_ENDPOINT_NAME", "")

CHECKPOINT_S3_URI = os.environ.get(
    "CHECKPOINT_S3_URI",
    "s3://galaxy-morph-checkpoints/streaming-classification/",
)

_trigger_secs = os.environ.get("TRIGGER_INTERVAL_SECONDS", "5")
TRIGGER_INTERVAL = f"{_trigger_secs} seconds"
INFERENCE_RETRIES = int(os.environ.get("INFERENCE_RETRIES", "3"))
