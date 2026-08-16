"""Integration tests for the FastAPI endpoint, including REQ-AI-07/08
(upstream provider 5xx and timeout must not leak a bad signal to the EA)."""

from datetime import datetime, timezone

from fastapi.testclient import TestClient

import kv_ai_service.app as app_module
from kv_ai_service.schemas import SCHEMA_VERSION

client = TestClient(app_module.app)


def _valid_request_body():
    now = datetime.now(timezone.utc).isoformat()
    return {
        "schema_version": SCHEMA_VERSION,
        "request_id": "abc-1",
        "symbol": "XAUUSD",
        "timeframe": "H1",
        "as_of": now,
        "ohlc_window": [{"t": now, "o": 1.0, "h": 2.0, "l": 0.5, "c": 1.5, "v": 10.0}],
        "open_position": {"side": "NONE", "volume": 0.0, "entry_price": 0.0},
    }


def test_health():
    resp = client.get("/v1/health")
    assert resp.status_code == 200
    assert resp.json() == {"status": "ok"}


def test_signal_happy_path_with_stub_provider():
    resp = client.post("/v1/signal", json=_valid_request_body())
    assert resp.status_code == 200
    body = resp.json()
    assert body["signal"] == "HOLD"
    assert body["request_id"] == "abc-1"


def test_signal_rejects_bad_request_schema_version():
    body = _valid_request_body()
    body["schema_version"] = "0.1"
    resp = client.post("/v1/signal", json=body)
    assert resp.status_code == 422


def test_signal_returns_502_on_malformed_provider_output(monkeypatch):
    class BrokenProvider:
        def generate_raw(self, request):
            return "{not json"

    monkeypatch.setattr(app_module, "_provider", BrokenProvider())
    resp = client.post("/v1/signal", json=_valid_request_body())
    assert resp.status_code == 502


def test_signal_returns_502_on_provider_exception(monkeypatch):
    class FailingProvider:
        def generate_raw(self, request):
            raise RuntimeError("upstream LLM API returned 500")

    monkeypatch.setattr(app_module, "_provider", FailingProvider())
    resp = client.post("/v1/signal", json=_valid_request_body())
    assert resp.status_code == 502


def test_signal_returns_504_on_provider_timeout(monkeypatch):
    class TimingOutProvider:
        def generate_raw(self, request):
            raise TimeoutError("upstream LLM API timed out")

    monkeypatch.setattr(app_module, "_provider", TimingOutProvider())
    resp = client.post("/v1/signal", json=_valid_request_body())
    assert resp.status_code == 504
