"""Core pipeline logic for streaming classification job."""

from __future__ import annotations

import json
import os
import sys
from typing import Any, Iterator
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from pyspark.sql import DataFrame

CURRENT_DIR = os.path.dirname(os.path.abspath(__file__))
LIBS_SRC = os.path.abspath(os.path.join(CURRENT_DIR, "../../../libs/src"))

if LIBS_SRC not in sys.path:
    sys.path.insert(0, LIBS_SRC)

from retry_utils import retry_with_backoff
from telemetry import BatchTelemetry, log_batch_telemetry, now_seconds

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


def classify_record(
    payload: dict[str, Any],
    region: str,
    inference_mode: str,
    sagemaker_endpoint_name: str,
    images_bucket: str,
    inference_retries: int,
    s3_client: Any,
    sm_runtime_client: Any,
) -> dict[str, Any]:
    if inference_mode == "stub":
        inference_result = _stub_classification(payload)
        return {
            "jobId": payload["jobId"],
            "clientId": payload["clientId"],
            "imageKey": payload["imageKey"],
            "status": "SUCCESS",
            "classification": inference_result,
            "inferenceMode": "stub",
        }

    if inference_mode != "sagemaker":
        raise ValueError(f"Unsupported INFERENCE_MODE: {inference_mode}")

    if not sagemaker_endpoint_name:
        raise ValueError("SAGEMAKER_ENDPOINT_NAME is required when INFERENCE_MODE=sagemaker")

    image_obj = s3_client.get_object(Bucket=images_bucket, Key=payload["imageKey"])
    image_bytes = image_obj["Body"].read()

    def invoke() -> dict[str, Any]:
        response = sm_runtime_client.invoke_endpoint(
            EndpointName=sagemaker_endpoint_name,
            ContentType="application/octet-stream",
            Body=image_bytes,
        )
        body = response["Body"].read().decode("utf-8")
        return json.loads(body)

    inference_result = retry_with_backoff(invoke, attempts=inference_retries)

    # Normalize SageMaker response: rename "label" → "predictedClass"
    classification = {
        "predictedClass": inference_result["label"],
        "confidence": inference_result["confidence"],
        "probabilities": inference_result["probabilities"],
    }

    return {
        "jobId": payload["jobId"],
        "clientId": payload["clientId"],
        "imageKey": payload["imageKey"],
        "status": "SUCCESS",
        "classification": classification,
    }


def _make_partition_processor(
    region: str,
    success_acc: Any,
    failed_acc: Any,
    inference_mode: str,
    sagemaker_endpoint_name: str,
    images_bucket: str,
    inference_retries: int,
):
    """"
    Returns a closure that processes one Spark partition on the executor.

    Why a factory instead of a nested def?
    Spark serializes the closure to ship it to executors. A factory function
    makes the captured variables (region, accumulators) explicit and avoids
    Python late-binding issues with loop-captured variables.

    Each executor:
      1. Creates its own boto3 clients once per partition (not per record).
      2. Downloads images from S3.
      3. Calls SageMaker (or stub) per record.
      4. Increments accumulators for telemetry.
      5. Yields result JSON strings — no data returns to the driver.
    """
    def process_partition(partition: Iterator) -> Iterator[str]:
        s3 = _s3_client(region)
        sm_runtime = _sagemaker_runtime_client(region)
        for row in partition:
            raw = row.value
            try:
                payload = parse_record(raw)
                result = classify_record(
                    payload,
                    region,
                    inference_mode,
                    sagemaker_endpoint_name,
                    images_bucket,
                    inference_retries,
                    s3,
                    sm_runtime,
                )
                success_acc.add(1)
                yield json.dumps(result)
            except Exception as err:  # noqa: BLE001
                failed_acc.add(1)
                try:
                    p: dict[str, Any] = json.loads(raw) if isinstance(raw, str) else {}
                except Exception:
                    p = {}
                fallback = {
                    "jobId": p.get("jobId", "unknown"),
                    "clientId": p.get("clientId", "unknown"),
                    "imageKey": p.get("imageKey", "unknown"),
                    "status": "ERROR",
                    "error": str(err),
                }
                yield json.dumps(fallback)

    return process_partition


def process_batch(batch_df: "DataFrame", batch_id: int, region: str, inference_mode: str, sagemaker_endpoint_name: str, images_bucket: str, inference_retries: int) -> None:
    if batch_df.rdd.isEmpty():
        return

    started = now_seconds()
    spark = batch_df.sparkSession
    sc = spark.sparkContext

    success_acc = sc.accumulator(0)
    failed_acc = sc.accumulator(0)

    results_rdd = batch_df.rdd.mapPartitions(
        _make_partition_processor(region, success_acc, failed_acc, inference_mode, sagemaker_endpoint_name, images_bucket, inference_retries)
    )

    out_df = spark.createDataFrame(results_rdd.map(lambda v: (v,)), ["value"])

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

    # Accumulator values are final after the write action above completes.
    elapsed = now_seconds() - started
    metric = BatchTelemetry(
        batch_id=batch_id,
        records=success_acc.value + failed_acc.value,
        success=success_acc.value,
        failed=failed_acc.value,
        elapsed_seconds=elapsed,
    )
    log_batch_telemetry(metric)
