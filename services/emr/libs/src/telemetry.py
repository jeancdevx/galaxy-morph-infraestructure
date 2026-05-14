"""Telemetry helpers shared by EMR jobs."""

from __future__ import annotations

import json
import time
from dataclasses import dataclass


@dataclass
class BatchTelemetry:
    batch_id: int
    records: int
    success: int
    failed: int
    elapsed_seconds: float

    @property
    def throughput_rps(self) -> float:
        if self.elapsed_seconds <= 0:
            return 0.0
        return self.records / self.elapsed_seconds


def now_seconds() -> float:
    return time.perf_counter()


def log_batch_telemetry(metric: BatchTelemetry) -> None:
    payload = {
        "metricType": "streaming_batch",
        "batchId": metric.batch_id,
        "records": metric.records,
        "success": metric.success,
        "failed": metric.failed,
        "elapsedSeconds": round(metric.elapsed_seconds, 3),
        "throughputRps": round(metric.throughput_rps, 3),
    }
    print(json.dumps(payload))
