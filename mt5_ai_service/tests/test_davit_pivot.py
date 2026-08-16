import pytest

from kv_ai_service.davit_pivot import calc_pivot


def test_classic_pivot_known_values():
    levels = calc_pivot(high=110.0, low=90.0, close=100.0)

    assert levels.pp == pytest.approx(100.0)
    assert levels.r1 == pytest.approx(110.0)
    assert levels.s1 == pytest.approx(90.0)
    assert levels.r2 == pytest.approx(120.0)
    assert levels.s2 == pytest.approx(80.0)
    assert levels.r3 == pytest.approx(130.0)
    assert levels.s3 == pytest.approx(70.0)


def test_fibonacci_pivot_known_values():
    levels = calc_pivot(high=110.0, low=90.0, close=100.0)

    assert levels.fib_r1 == pytest.approx(107.64)
    assert levels.fib_r2 == pytest.approx(112.36)
    assert levels.fib_r3 == pytest.approx(120.0)
    assert levels.fib_s1 == pytest.approx(92.36)
    assert levels.fib_s2 == pytest.approx(87.64)
    assert levels.fib_s3 == pytest.approx(80.0)


def test_rejects_high_below_low():
    with pytest.raises(ValueError):
        calc_pivot(high=89.0, low=90.0, close=89.5)


def test_flat_week_all_levels_equal_pivot():
    levels = calc_pivot(high=100.0, low=100.0, close=100.0)

    assert levels.pp == pytest.approx(100.0)
    assert levels.r1 == pytest.approx(100.0)
    assert levels.s1 == pytest.approx(100.0)
    assert levels.fib_r3 == pytest.approx(100.0)
    assert levels.fib_s3 == pytest.approx(100.0)
