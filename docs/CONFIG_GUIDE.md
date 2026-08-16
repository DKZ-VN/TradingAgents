# Hướng dẫn cấu hình — KV_AI_MT5_EA

## 1. Cài đặt EA vào MT5 (máy chạy thật, không phải CI)
1. Copy `mt5_ea/Experts/KV_AI/`, `mt5_ea/Include/KV_AI/`, `mt5_ea/Indicators/KV_AI/` vào đúng thư mục tương ứng trong Data Folder của MT5 (`File → Open Data Folder → MQL5\Experts`, `MQL5\Include`, `MQL5\Indicators`).
2. Mở MetaEditor, biên dịch lại `KV_AI_EA.mq5` tại chỗ (F7) để chắc chắn khớp bản build MT5 của bạn (build có thể khác build trên CI).

## 2. Bắt buộc: cho phép WebRequest tới AI service
EA gọi AI service qua `WebRequest()`. MT5 chặn mọi URL chưa được khai báo thủ công — **không thể tự động hoá bước này từ xa**:
1. MT5 → `Tools → Options → Expert Advisors`.
2. Tick "Allow WebRequest for listed URL".
3. Thêm đúng URL đang cấu hình ở `InpAiServiceUrl` (mặc định `http://127.0.0.1:8765`).
4. Bấm OK, khởi động lại EA (gỡ và gắn lại vào chart).

## 3. Chạy AI service
```
cd mt5_ai_service
pip install -e ".[dev]"
uvicorn kv_ai_service.app:app --host 127.0.0.1 --port 8765
```
Service phải chạy TRƯỚC khi gắn EA vào chart, và tiếp tục chạy trong suốt phiên giao dịch.

## 4. Tham số EA quan trọng cần rà trước khi chạy thật
Xem bảng đầy đủ tại `KV_AI_MT5_EA_SPEC_v1.1.md` §11. Tối thiểu rà lại:
- `InpSignalMode` — chọn DAVIT_ONLY/AI_ONLY/COMBINED.
- `InpMaxRiskPerTradePct`, `InpMaxTotalRiskPct`, `InpMaxMarginUsagePct` — chỉnh theo khẩu vị rủi ro thật, KHÔNG để mặc định demo nếu chạy tài khoản live.
- `InpMagicNumber` — đổi nếu chạy nhiều EA trên cùng tài khoản để tránh xung đột.

## 5. Forward-test demo (bắt buộc trước khi lên live)
Đây là bước **chủ dự án phải tự thực hiện** (agent không có quyền điều khiển máy tính vật lý/MT5 terminal thật):
1. Mở tài khoản demo tại broker cung cấp XAUUSD.
2. Gắn EA + AI service như hướng dẫn trên, chạy tối thiểu thời lượng quy định trong `RELEASE_CHECKLIST.md`.
3. Xuất báo cáo (`Toolbox → Trade → Report`) + log Journal/Experts, đính kèm vào `RELEASE_CHECKLIST.md` làm bằng chứng.
