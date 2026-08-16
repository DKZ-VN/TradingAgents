# Release Checklist — KV_AI_MT5_EA

Không được đánh dấu "Đạt" nếu chưa có bằng chứng (log/artifact/link CI run) đính kèm ở cột Bằng chứng. Xem `traceability_matrix.md` cho chi tiết từng test case.

| Gate | Đạt? | Bằng chứng |
|---|---|---|
| MetaEditor: 0 error, 0 warning | ☐ | |
| Không thiếu include / indicator handle / buffer mapping | ☐ | |
| Toàn bộ Python unit/integration test pass | ☐ | |
| JSON schema + provider adapter pass malformed-response test | ☐ | |
| Davit weekly rollover / stale data / wrong-week test pass | ☐ | |
| Mọi volume mode tuân thủ stop-risk/margin/total-risk cap | ☐ | |
| Disconnect / timeout / restart / duplicate-order test pass | ☐ | |
| Rule-only backtest chạy hết, không lỗi runtime | ☐ | |
| AI-replay backtest chạy hết, không lỗi runtime | ☐ | |
| Real-tick out-of-sample report đã sinh ra | ☐ | |
| Demo forward-test evidence đính kèm | ☐ | Cần chủ dự án tự chạy trên MT5 terminal thật (xem spec §12.4) |
| Không còn defect Critical/High mở | ☐ | |
| Không có test nào bị xoá/làm yếu/skip để "cho qua" | ☐ | |

**Trạng thái tổng thể dự án: CHƯA ĐỦ ĐIỀU KIỆN RELEASE — đang ở Milestone 0/10.**
