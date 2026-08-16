"""REQ-AI-03..REQ-AI-10 in docs/traceability_matrix.md: the provider adapter
must reject every malformed shape of a raw LLM response instead of turning it
into a signal the EA could act on."""

import json
from datetime import datetime, timedelta, timezone

import pytest

from kv_ai_service.adapter import parse_raw_signal
from kv_ai_service.errors import ProviderError
from kv_ai_service.schemas import SCHEMA_VERSION

REQ_ID = "req-123"


def _now():
    return datetime.now(timezone.utc)


def _valid_payload(**overrides):
    now = _now()
    payload = {
        "schema_version": SCHEMA_VERSION,
        "request_id": REQ_ID,
        "generated_at": now.isoformat(),
        "expiry_ts": (now + timedelta(minutes=5)).isoformat(),
        "symbol": "XAUUSD",
        "signal": "BUY",
        "confidence": 0.6,
        "stop_loss_pips": 50.0,
        "take_profit_pips": 100.0,
        "reasoning": "ok",
    }
    payload.update(overrides)
    return payload


def _dump(payload):
    return json.dumps(payload)


def test_missing_field():
    payload = _valid_payload()
    del payload["signal"]
    with pytest.raises(ProviderError) as exc:
        parse_raw_signal(_dump(payload), REQ_ID)
    assert exc.value.reason == "schema_validation_failed"


def test_wrong_type():
    payload = _valid_payload(confidence="high")
    with pytest.raises(ProviderError) as exc:
        parse_raw_signal(_dump(payload), REQ_ID)
    assert exc.value.reason == "schema_validation_failed"


def test_confidence_out_of_range():
    payload = _valid_payload(confidence=1.5)
    with pytest.raises(ProviderError) as exc:
        parse_raw_signal(_dump(payload), REQ_ID)
    assert exc.value.reason == "schema_validation_failed"


def test_empty_json():
    with pytest.raises(ProviderError) as exc:
        parse_raw_signal("", REQ_ID)
    assert exc.value.reason == "invalid_json"


def test_invalid_json_garbage():
    with pytest.raises(ProviderError) as exc:
        parse_raw_signal("{not json", REQ_ID)
    assert exc.value.reason == "invalid_json"


def test_schema_version_mismatch():
    payload = _valid_payload(schema_version="9.9")
    with pytest.raises(ProviderError) as exc:
        parse_raw_signal(_dump(payload), REQ_ID)
    assert exc.value.reason == "schema_validation_failed"


def test_stale_expiry():
    now = _now()
    payload = _valid_payload(
        generated_at=(now - timedelta(minutes=10)).isoformat(),
        expiry_ts=(now - timedelta(minutes=1)).isoformat(),
    )
    with pytest.raises(ProviderError) as exc:
        parse_raw_signal(_dump(payload), REQ_ID)
    assert exc.value.reason == "stale_signal"


def test_stale_generated_at_even_with_future_expiry():
    now = _now()
    payload = _valid_payload(
        generated_at=(now - timedelta(minutes=10)).isoformat(),
        expiry_ts=(now + timedelta(minutes=5)).isoformat(),
    )
    with pytest.raises(ProviderError) as exc:
        parse_raw_signal(_dump(payload), REQ_ID)
    assert exc.value.reason == "stale_signal"


def test_request_id_mismatch():
    payload = _valid_payload(request_id="different-id")
    with pytest.raises(ProviderError) as exc:
        parse_raw_signal(_dump(payload), REQ_ID)
    assert exc.value.reason == "request_id_mismatch"


def test_valid_payload_parses():
    payload = _valid_payload()
    resp = parse_raw_signal(_dump(payload), REQ_ID)
    assert resp.signal == "BUY"
