"""Turns a provider's raw text output into a validated SignalResponse.

Enforces docs/KV_AI_MT5_EA_SPEC_v1.1.md ss 4.3/4.4: any malformed, stale, or
mismatched output becomes a ProviderError rather than a signal the EA could
act on. This is the "provider adapter" covered by the malformed-response
release gate.
"""

from __future__ import annotations

import json
from datetime import datetime, timezone

from pydantic import ValidationError

from .errors import ProviderError
from .schemas import SignalResponse

MAX_SIGNAL_AGE_SEC = 120


def parse_raw_signal(
    raw_text: str,
    expected_request_id: str,
    now: datetime | None = None,
) -> SignalResponse:
    now = now or datetime.now(timezone.utc)

    if not raw_text or not raw_text.strip():
        raise ProviderError("invalid_json", "empty response body")

    try:
        payload = json.loads(raw_text)
    except json.JSONDecodeError as exc:
        raise ProviderError("invalid_json", str(exc)) from exc

    try:
        response = SignalResponse.model_validate(payload)
    except ValidationError as exc:
        raise ProviderError("schema_validation_failed", str(exc)) from exc

    if response.request_id != expected_request_id:
        raise ProviderError(
            "request_id_mismatch",
            f"expected {expected_request_id}, got {response.request_id}",
        )

    if response.expiry_ts <= now:
        raise ProviderError("stale_signal", f"expiry_ts {response.expiry_ts} <= now {now}")

    age_sec = (now - response.generated_at).total_seconds()
    if age_sec > MAX_SIGNAL_AGE_SEC:
        raise ProviderError(
            "stale_signal",
            f"generated_at is {age_sec:.0f}s old, max {MAX_SIGNAL_AGE_SEC}s",
        )

    return response
