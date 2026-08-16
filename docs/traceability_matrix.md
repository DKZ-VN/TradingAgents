# Ma trận truy vết Requirement → Test (KV_AI_MT5_EA)

Nguồn: `docs/KV_AI_MT5_EA_SPEC_v1.1.md`. Cột **Trạng thái** chỉ được đánh `PASS` khi có log/artifact thật đính kèm (đường dẫn cụ thể); `TODO` = chưa implement; `BLOCKED` = không thể chạy, ghi rõ lý do.

| REQ ID | Yêu cầu (spec §) | Test case | Vị trí test | Trạng thái | Bằng chứng |
|---|---|---|---|---|---|
| REQ-BUILD-01 | EA biên dịch 0 error/0 warning (§10) | CI job `mql5-compile` | `.github/workflows/kv-ai-mt5.yml` | BLOCKED | Run `31922348133` fail ngay lập tức, không cấp runner (BUG-002 trong BUG_LOG.md) — cần chủ dự án kiểm tra Actions/billing settings của repo |
| REQ-SIG-01 | 3 chế độ tín hiệu DAVIT_ONLY/AI_ONLY/COMBINED (§1) | `Scripts/KV_AI/tests/test_signal_router.mq5` | M3 | TODO | — |
| REQ-SIG-02 | COMBINED chỉ vào lệnh khi 2 nguồn đồng thuận (§1) | test_signal_router.mq5 | M3 | TODO | — |
| REQ-PIVOT-01 | Pivot Davit placeholder tính đúng công thức Classic/Fibonacci (§12.1) | `mt5_ai_service/tests/test_davit_pivot.py` (đối chiếu song song với MQL5) | M1/M2 | TODO | — |
| REQ-PIVOT-02 | Interface CalcPivot() tách rời, hoán đổi không sửa EA (§12.1) | code review thủ công | M1 | TODO | — |
| REQ-AI-01 | Request JSON đúng schema §4.2 | `test_schemas.py` | M2 | TODO | — |
| REQ-AI-02 | Response JSON đúng schema §4.3 | `test_schemas.py` | M2 | TODO | — |
| REQ-AI-03 | Reject thiếu field | `test_malformed_responses.py::test_missing_field` | M2 | TODO | — |
| REQ-AI-04 | Reject sai kiểu dữ liệu | `test_malformed_responses.py::test_wrong_type` | M2 | TODO | — |
| REQ-AI-05 | Reject confidence ngoài [0,1] | `test_malformed_responses.py::test_confidence_out_of_range` | M2 | TODO | — |
| REQ-AI-06 | Reject JSON rỗng/không parse được | `test_malformed_responses.py::test_empty_or_invalid_json` | M2 | TODO | — |
| REQ-AI-07 | Reject HTTP 500 / lỗi provider | `test_malformed_responses.py::test_provider_5xx` | M2 | TODO | — |
| REQ-AI-08 | Reject timeout | `test_malformed_responses.py::test_timeout` | M2 | TODO | — |
| REQ-AI-09 | Reject expiry_ts đã qua (stale) | `test_malformed_responses.py::test_stale_expiry` | M2 | TODO | — |
| REQ-AI-10 | Reject schema_version không khớp | `test_malformed_responses.py::test_schema_version_mismatch` | M2 | TODO | — |
| REQ-AI-11 | EA fallback HOLD khi AI lỗi, không suy ra BUY/SELL (§4.4) | `test_signal_router.mq5::test_ai_error_fallback_hold` | M3 | TODO | — |
| REQ-RISK-01 | Stop-risk per-trade cap chặn lệnh vượt ngưỡng (§5.2.1) | `test_risk_manager.mq5::test_stop_risk_cap` | M4 | TODO | — |
| REQ-RISK-02 | Margin cap dùng OrderCalcMargin thực tế (§5.2.2) | `test_risk_manager.mq5::test_margin_cap` | M4 | TODO | — |
| REQ-RISK-03 | Total-risk cap tính đúng khi có nhiều vị thế mở (§5.2.3) | `test_risk_manager.mq5::test_total_risk_cap` | M4 | TODO | — |
| REQ-RISK-04 | Volume làm tròn theo VOLUME_STEP, kẹp MIN/MAX (§5.2.4) | `test_risk_manager.mq5::test_volume_rounding` | M4 | TODO | — |
| REQ-RISK-05 | FIXED_LOT vẫn bị chặn bởi risk caps | `test_risk_manager.mq5::test_fixed_lot_still_capped` | M4 | TODO | — |
| REQ-RISK-06 | RISK_PERCENT tính đúng công thức | `test_risk_manager.mq5::test_risk_percent_formula` | M4 | TODO | — |
| REQ-RISK-07 | Kelly-capped nhân đúng hệ số & dùng confidence AI | `test_risk_manager.mq5::test_kelly_capped` | M4 | TODO | — |
| REQ-ROLL-01 | Chặn mở lệnh trong cửa sổ rollover cuối tuần (§6) | `test_rollover_guard.mq5::test_weekend_freeze_window` | M5 | TODO | — |
| REQ-ROLL-02 | Phát hiện stale data (nến quá cũ) | `test_rollover_guard.mq5::test_stale_bar_detection` | M5 | TODO | — |
| REQ-ROLL-03 | Pivot tuần tính lại đúng thời điểm chuyển tuần | `test_rollover_guard.mq5::test_wrong_week_pivot_recalc` | M5 | TODO | — |
| REQ-ROLL-04 | Tuần có ngày lễ (thiếu phiên) không làm sai detect chuyển tuần | `test_rollover_guard.mq5::test_holiday_week_gap` | M5 | TODO | — |
| REQ-CONN-01 | Phát hiện mất kết nối, khoá lệnh mới, giữ vị thế | `test_order_guard.mq5::test_disconnect_blocks_new_orders` | M6 | TODO | — |
| REQ-CONN-02 | Retry có kiểm soát khi timeout/requote | `test_order_guard.mq5::test_retry_on_timeout` | M6 | TODO | — |
| REQ-CONN-03 | Không gửi trùng lệnh khi EA restart giữa chừng | `test_order_guard.mq5::test_no_duplicate_after_restart` | M6 | TODO | — |
| REQ-CONN-04 | OnInit đối chiếu state.json với PositionsGet/OrdersGet thực tế | `test_order_guard.mq5::test_reconcile_on_init` | M6 | TODO | — |
| REQ-BT-01 | Rule-only backtest chạy hết không lỗi runtime (§8) | Strategy Tester report | M7 | TODO | — |
| REQ-BT-02 | AI-replay backtest deterministic, không gọi HTTP thật | Strategy Tester report | M7 | TODO | — |
| REQ-BT-03 | Real-tick out-of-sample report được sinh ra | Strategy Tester report | M8 | TODO | — |
| REQ-FWD-01 | Bằng chứng forward-test demo (statement + log) | Do chủ dự án cung cấp | M9 | BLOCKED | Cần MT5 terminal thật trên máy/VPS chủ dự án — agent không tự chạy được |
| REQ-REVIEW-01 | Review độc lập cuối, không còn defect Critical/High | `docs/BUG_LOG.md` | M10 | TODO | — |

**Quy tắc cập nhật bảng này:** mỗi milestone hoàn tất phải cập nhật cột Trạng thái + Bằng chứng bằng đường dẫn log/artifact thật (đường dẫn file trong repo hoặc URL CI run), commit cùng lúc với code milestone đó. Không đánh PASS dựa trên suy luận.
