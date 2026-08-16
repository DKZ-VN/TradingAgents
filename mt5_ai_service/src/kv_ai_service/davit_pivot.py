"""Placeholder pivot calculation, kept in lockstep with
mt5_ea/Include/KV_AI/PivotDavit.mqh so the EA and the AI-replay backtest
tooling agree on pivot levels.

PLACEHOLDER: not the real "Davit Pivot" (ForexFactory thread) formula yet -
see docs/KV_AI_MT5_EA_SPEC_v1.1.md section 12.1.
"""

from dataclasses import dataclass


@dataclass(frozen=True)
class PivotLevels:
    pp: float
    r1: float
    r2: float
    r3: float
    s1: float
    s2: float
    s3: float
    fib_r1: float
    fib_r2: float
    fib_r3: float
    fib_s1: float
    fib_s2: float
    fib_s3: float


def calc_pivot(high: float, low: float, close: float) -> PivotLevels:
    if high < low:
        raise ValueError(f"high ({high}) must be >= low ({low})")

    pivot = (high + low + close) / 3.0
    rng = high - low

    return PivotLevels(
        pp=pivot,
        r1=2.0 * pivot - low,
        s1=2.0 * pivot - high,
        r2=pivot + rng,
        s2=pivot - rng,
        r3=high + 2.0 * (pivot - low),
        s3=low - 2.0 * (high - pivot),
        fib_r1=pivot + 0.382 * rng,
        fib_r2=pivot + 0.618 * rng,
        fib_r3=pivot + 1.000 * rng,
        fib_s1=pivot - 0.382 * rng,
        fib_s2=pivot - 0.618 * rng,
        fib_s3=pivot - 1.000 * rng,
    )
