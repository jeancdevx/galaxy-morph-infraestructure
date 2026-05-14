"""Core pipeline logic for streaming classification job."""

from __future__ import annotations

import json
import os
import sys
from typing import Any
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from pyspark.sql import DataFrame

CURRENT_DIR = os.path.dirname(os.path.abspath(__file__))
LIBS_SRC = os.path.abspath(os.path.join(CURRENT_DIR, "../../../libs/src"))

if LIBS_SRC not in sys.path:
    sys.path.insert(0, LIBS_SRC)

from retry_utils import retry_with_backoff
from telemetry import BatchTelemetry, log_batch_telemetry, now_seconds

try:
    from .config import IMAGES_BUCKET, INFERENCE_MODE, INFERENCE_RETRIES, SAGEMAKER_ENDPOINT_NAME
except ImportError:
    from config import IMAGES_BUCKET, INFERENCE_MODE, INFERENCE_RETRIES, SAGEMAKER_ENDPOINT_NAME


def _s3_client(region: str):
    import boto3

    return boto3.client("s3", region_name=region)


def _sagemaker_runtime_client(region: str):
    import boto3

    return boto3.client("sagemaker-runtime", region_name=region)


def parse_record(value: str) -> dict[str, Any]:
    payload = json.loads(value)
    required = ["jobId", "clientId", "imageKey"]
    missing = [k for k in required if k not in payload]
    if missing:
        raise ValueError(f"Missing required payload keys: {missing}")
    return payload


def _stub_classification(payload: dict[str, Any]) -> dict[str, Any]:
    image_key = payload["imageKey"]
    score_seed = sum(ord(ch) for ch in image_key) % 100
    label = "spiral" if score_seed % 2 == 0 else "elliptical"
    confidence = round(0.5 + (score_seed / 200), 3)
    return {
        "model": "q6-stub-classifier",
        "label": label,
        "confidence": confidence,
    }


def classify_record(payload: dict[str, Any], region: str) -> dict[str, Any]:
    if INFERENCE_MODE == "stub":
        inference_result = _stub_classification(payload)
        return {
            "jobId": payload["jobId"],
            "clientId": payload["clientId"],
            "imageKey": payload["imageKey"],
            "status": "SUCCESS",
            "classification": inference_result,
            "inferenceMode": "stub",
        }

    if INFERENCE_MODE != "sagemaker":
        raise ValueError(f"Unsupported INFERENCE_MODE: {INFERENCE_MODE}")

    if not SAGEMAKER_ENDPOINT_NAME:
        raise ValueError("SAGEMAKER_ENDPOINT_NAME is required when INFERENCE_MODE=sagemaker")

    s3 = _s3_client(region)
    sm_runtime = _sagemaker_runtime_client(region)

    image_obj = s3.get_object(Bucket=IMAGES_BUCKET, Key=payload["imageKey"])
    image_bytes = image_obj["Body"].read()

    def invoke() -> dict[str, Any]:
        response = sm_runtime.invoke_endpoint(
            EndpointName=SAGEMAKER_ENDPOINT_NAME,
            ContentType="application/octet-stream",
            Body=image_bytes,
        )
        body = response["Body"].read().decode("utf-8")
        return json.loads(body)

    inference_result = retry_with_backoff(invoke, attempts=INFERENCE_RETRIES)

    return {
        "jobId": payload["jobId"],
        "clientId": payload["clientId"],
        "imageKey": payload["imageKey"],
        "status": "SUCCESS",
        "classification": inference_result,
        "inferenceMode": "sagemaker",
    }


def process_batch(batch_df: "DataFrame", batch_id: int, region: str) -> None:
    if batch_df.rdd.isEmpty():
        return

    started = now_seconds()
    records = [row.value for row in batch_df.select("value").collect()]

    success = 0
    failed = 0
    output_rows: list[str] = []

    for raw in records:
        try:
            payload = parse_record(raw)
            result = classify_record(payload, region)
            output_rows.append(json.dumps(result))
            success += 1
        except Exception as err:  # noqa: BLE001
            failed += 1
            fallback = {
                "jobId": payload.get("jobId", "unknown") if "payload" in locals() else "unknown",
                "clientId": payload.get("clientId", "unknown") if "payload" in locals() else "unknown",
                "imageKey": payload.get("imageKey", "unknown") if "payload" in locals() else "unknown",
                "status": "ERROR",
                "error": str(err),
            }
            output_rows.append(json.dumps(fallback))

    spark = batch_df.sparkSession
    out_df = spark.createDataFrame([(row,) for row in output_rows], ["value"])

    (
        out_df.selectExpr("CAST(value AS STRING) AS value")
        .write.format("kafka")
        .option("kafka.bootstrap.servers", os.environ.get("KAFKA_BOOTSTRAP_SERVERS", ""))
        .option("topic", os.environ.get("KAFKA_RESULTS_TOPIC", "galaxy.results"))
        .option("kafka.security.protocol", "SASL_SSL")
        .option("kafka.sasl.mechanism", "AWS_MSK_IAM")
        .option(
            "kafka.sasl.jaas.config",
            "software.amazon.msk.auth.iam.IAMLoginModule required;",
        )
        .option(
            "kafka.sasl.client.callback.handler.class",
            "software.amazon.msk.auth.iam.IAMClientCallbackHandler",
        )
        .save()
    )

    elapsed = now_seconds() - started
    metric = BatchTelemetry(
        batch_id=batch_id,
        records=len(records),
        success=success,
        failed=failed,
        elapsed_seconds=elapsed,
    )
    log_batch_telemetry(metric)
