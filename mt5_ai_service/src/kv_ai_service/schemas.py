"""EA <-> AI service JSON contract. Mirrors docs/KV_AI_MT5_EA_SPEC_v1.1.md ss 4.2/4.3.

Field names match the wire JSON keys from the spec exactly, except OhlcBar's
low price: the spec key is the single letter "l", which is an ambiguous
identifier in Python (looks like "1") - kept as an alias instead of the
Python attribute name.
"""

from __future__ import annotations

from datetime import datetime
from typing import Literal

from pydantic import BaseModel, Field

SCHEMA_VERSION = "1.0"

SignalSide = Literal["BUY", "SELL", "HOLD"]
PositionSide = Literal["NONE", "BUY", "SELL"]


class OhlcBar(BaseModel):
    model_config = {"populate_by_name": True}

    t: datetime
    o: float
    h: float
    low: float = Field(alias="l")
    c: float
    v: float = 0.0


class OpenPosition(BaseModel):
    side: PositionSide = "NONE"
    volume: float = 0.0
    entry_price: float = 0.0


class SignalRequest(BaseModel):
    schema_version: Literal[SCHEMA_VERSION]
    request_id: str
    symbol: str
    timeframe: str
    as_of: datetime
    ohlc_window: list[OhlcBar]
    open_position: OpenPosition = OpenPosition()


class SignalResponse(BaseModel):
    schema_version: Literal[SCHEMA_VERSION]
    request_id: str
    generated_at: datetime
    expiry_ts: datetime
    symbol: str
    signal: SignalSide
    confidence: float = Field(ge=0.0, le=1.0)
    stop_loss_pips: float = Field(ge=0.0)
    take_profit_pips: float = Field(ge=0.0)
    reasoning: str = ""
