import json
from datetime import datetime, timedelta, timezone

from ..schemas import SCHEMA_VERSION, SignalRequest


class StubProvider:
    """Deterministic provider for tests/local dev when no real LLM is configured.

    Not a trading strategy - always emits HOLD with zero confidence, purely to
    exercise the request/response contract end-to-end. Swap for a real LLM
    provider (implementing RawSignalProvider) before demo/live use.
    """

    def generate_raw(self, request: SignalRequest) -> str:
        now = datetime.now(timezone.utc)
        payload = {
            "schema_version": SCHEMA_VERSION,
            "request_id": request.request_id,
            "generated_at": now.isoformat(),
            "expiry_ts": (now + timedelta(seconds=300)).isoformat(),
            "symbol": request.symbol,
            "signal": "HOLD",
            "confidence": 0.0,
            "stop_loss_pips": 0.0,
            "take_profit_pips": 0.0,
            "reasoning": "stub provider - no real signal source configured",
        }
        return json.dumps(payload)
