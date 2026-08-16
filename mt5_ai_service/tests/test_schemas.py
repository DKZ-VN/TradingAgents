from datetime import datetime, timedelta, timezone

import pytest
from pydantic import ValidationError

from kv_ai_service.schemas import (
    SCHEMA_VERSION,
    OhlcBar,
    OpenPosition,
    SignalRequest,
    SignalResponse,
)


def _now():
    return datetime.now(timezone.utc)


def test_signal_request_round_trip():
    req = SignalRequest(
        schema_version=SCHEMA_VERSION,
        request_id="11111111-1111-1111-1111-111111111111",
        symbol="XAUUSD",
        timeframe="H1",
        as_of=_now(),
        ohlc_window=[OhlcBar(t=_now(), o=1.0, h=2.0, low=0.5, c=1.5, v=100.0)],
        open_position=OpenPosition(side="NONE", volume=0.0, entry_price=0.0),
    )
    dumped = req.model_dump(by_alias=True)
    assert dumped["ohlc_window"][0]["l"] == 0.5

    restored = SignalRequest.model_validate(dumped)
    assert restored.symbol == "XAUUSD"
    assert restored.ohlc_window[0].low == 0.5


def test_signal_response_round_trip():
    now = _now()
    resp = SignalResponse(
        schema_version=SCHEMA_VERSION,
        request_id="req-1",
        generated_at=now,
        expiry_ts=now + timedelta(minutes=5),
        symbol="XAUUSD",
        signal="BUY",
        confidence=0.75,
        stop_loss_pips=50.0,
        take_profit_pips=100.0,
        reasoning="test",
    )
    assert resp.model_dump()["signal"] == "BUY"


def test_signal_response_rejects_bad_signal_value():
    now = _now()
    with pytest.raises(ValidationError):
        SignalResponse(
            schema_version=SCHEMA_VERSION,
            request_id="req-1",
            generated_at=now,
            expiry_ts=now + timedelta(minutes=5),
            symbol="XAUUSD",
            signal="MAYBE",
            confidence=0.5,
            stop_loss_pips=0.0,
            take_profit_pips=0.0,
        )


def test_signal_response_rejects_confidence_out_of_range():
    now = _now()
    with pytest.raises(ValidationError):
        SignalResponse(
            schema_version=SCHEMA_VERSION,
            request_id="req-1",
            generated_at=now,
            expiry_ts=now + timedelta(minutes=5),
            symbol="XAUUSD",
            signal="BUY",
            confidence=1.2,
            stop_loss_pips=0.0,
            take_profit_pips=0.0,
        )
