from typing import Protocol

from ..schemas import SignalRequest


class RawSignalProvider(Protocol):
    """Produces raw (unvalidated) JSON text for a signal request.

    Implementations may raise any exception to signal an upstream failure
    (network error, non-2xx from the LLM API, etc); app.py maps that to a
    502 so the EA falls back to HOLD rather than crashing.
    """

    def generate_raw(self, request: SignalRequest) -> str: ...
