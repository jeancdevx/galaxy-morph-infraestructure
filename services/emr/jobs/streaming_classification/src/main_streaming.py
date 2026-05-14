"""Spark Structured Streaming entrypoint for galaxy morphology classification."""

from __future__ import annotations

import os

from pyspark.sql import SparkSession


def create_spark_session() -> SparkSession:
    spark = (
        SparkSession.builder.appName("galaxy-morph-streaming-classification")
        .config("spark.sql.streaming.forceDeleteTempCheckpointLocation", "true")
        .getOrCreate()
    )
    spark.sparkContext.setLogLevel("WARN")
    return spark


def _populate_env_from_spark_conf(spark: SparkSession) -> None:
    """Inject spark.app.* conf properties into os.environ.

    On EMR Serverless PySpark, spark.driverEnv.* confs are applied to the JVM
    process but do NOT propagate to the Python driver's os.environ.  Reading
    from SparkConf and writing into os.environ before importing config.py is
    the EMR-native pattern.  When running locally (docker-compose), os.environ
    is already populated by the container, so this is effectively a no-op.
    """
    conf_to_env = {
        "spark.app.aws_region":               "AWS_REGION",
        "spark.app.kafka_bootstrap_servers":  "KAFKA_BOOTSTRAP_SERVERS",
        "spark.app.kafka_ingestion_topic":    "KAFKA_INGESTION_TOPIC",
        "spark.app.kafka_results_topic":      "KAFKA_RESULTS_TOPIC",
        "spark.app.kafka_group_id":           "KAFKA_GROUP_ID",
        "spark.app.images_bucket":            "IMAGES_BUCKET",
        "spark.app.inference_mode":           "INFERENCE_MODE",
        "spark.app.sagemaker_endpoint_name":  "SAGEMAKER_ENDPOINT_NAME",
        "spark.app.checkpoint_s3_uri":        "CHECKPOINT_S3_URI",
        "spark.app.trigger_interval_seconds": "TRIGGER_INTERVAL_SECONDS",
        "spark.app.inference_retries":        "INFERENCE_RETRIES",
    }
    for conf_key, env_key in conf_to_env.items():
        try:
            val = spark.conf.get(conf_key)
            if val and not os.environ.get(env_key):
                os.environ[env_key] = val
        except Exception:  # noqa: BLE001
            pass


def main() -> None:
    spark = create_spark_session()

    # Populate os.environ BEFORE importing config/pipeline so module-level
    # os.environ.get() calls in those modules see the correct values.
    _populate_env_from_spark_conf(spark)

    # Lazy imports — must happen AFTER _populate_env_from_spark_conf so that
    # config.py reads the already-injected env vars.
    from config import (  # noqa: PLC0415
        AWS_REGION,
        CHECKPOINT_S3_URI,
        KAFKA_BOOTSTRAP_SERVERS,
        KAFKA_GROUP_ID,
        KAFKA_INGESTION_TOPIC,
        TRIGGER_INTERVAL,
    )
    from pipeline import process_batch  # noqa: PLC0415

    stream_df = (
        spark.readStream.format("kafka")
        .option("kafka.bootstrap.servers", KAFKA_BOOTSTRAP_SERVERS)
        .option("subscribe", KAFKA_INGESTION_TOPIC)
        .option("startingOffsets", "latest")
        .option("failOnDataLoss", "false")
        .option("kafka.group.id", KAFKA_GROUP_ID)
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
        .load()
        .selectExpr("CAST(value AS STRING) as value")
    )

    query = (
        stream_df.writeStream.foreachBatch(lambda df, bid: process_batch(df, bid, AWS_REGION))
        .option("checkpointLocation", CHECKPOINT_S3_URI)
        .trigger(processingTime=TRIGGER_INTERVAL)
        .start()
    )

    query.awaitTermination()


if __name__ == "__main__":
    main()
