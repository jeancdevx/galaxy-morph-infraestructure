"""Retry utilities shared by EMR jobs."""

from __future__ import annotations

import time
from typing import Callable, TypeVar

T = TypeVar("T")


def retry_with_backoff(
    fn: Callable[[], T],
    attempts: int = 3,
    initial_backoff_seconds: float = 0.25,
    max_backoff_seconds: float = 4.0,
) -> T:
    """Retry a call with exponential backoff.

    Raises the last exception if all attempts fail.
    """
    backoff = initial_backoff_seconds
    last_error: Exception | None = None

    for _ in range(attempts):
        try:
            return fn()
        except Exception as err:  # noqa: BLE001
            last_error = err
            time.sleep(backoff)
            backoff = min(backoff * 2, max_backoff_seconds)

    if last_error is not None:
        raise last_error

    raise RuntimeError("retry_with_backoff reached unexpected state")
