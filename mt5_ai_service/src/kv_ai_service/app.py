import logging

from fastapi import FastAPI, HTTPException

from .adapter import parse_raw_signal
from .errors import ProviderError
from .providers.stub_provider import StubProvider
from .schemas import SignalRequest, SignalResponse

logger = logging.getLogger("kv_ai_service")

app = FastAPI(title="kv-ai-service")
_provider = StubProvider()


@app.get("/v1/health")
def health() -> dict:
    return {"status": "ok"}


@app.post("/v1/signal", response_model=SignalResponse)
def signal(request: SignalRequest) -> SignalResponse:
    try:
        raw = _provider.generate_raw(request)
    except TimeoutError as exc:
        logger.error("provider timeout: %s", exc)
        raise HTTPException(status_code=504, detail="provider_timeout") from exc
    except Exception as exc:
        logger.error("provider error: %s", exc)
        raise HTTPException(status_code=502, detail="provider_error") from exc

    try:
        return parse_raw_signal(raw, expected_request_id=request.request_id)
    except ProviderError as exc:
        logger.error("malformed provider output: %s (%s)", exc.reason, exc.detail)
        raise HTTPException(status_code=502, detail=exc.reason) from exc
