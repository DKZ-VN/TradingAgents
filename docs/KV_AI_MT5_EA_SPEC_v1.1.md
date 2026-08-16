# KV_AI MT5 EA — Đặc tả kỹ thuật (SOURCE OF TRUTH)

- Mã dự án: `KV_AI_MT5_EA`
- Phiên bản đặc tả: v1.1
- Ngày tạo: 2026-08-16
- Tác giả: Claude (lead engineer) theo yêu cầu chủ dự án (Cowork session)
- Trạng thái: **DRAFT — đang triển khai Milestone 0**. Tài liệu này là nguồn chân lý duy nhất; mọi thay đổi hành vi hệ thống phải cập nhật tài liệu này trước hoặc cùng lúc với code.

> **Ghi chú xuất xứ:** Tài liệu này KHÔNG tồn tại trong repository trước phiên làm việc này. Repo gốc (`dkz-vn/tradingagents`) là framework Python/LangGraph đa tác tử LLM cho nghiên cứu cổ phiếu, không liên quan MQL5/MT5. Toàn bộ đặc tả dưới đây được xây mới từ đầu theo yêu cầu của chủ dự án, dựa trên khung yêu cầu (mandatory loop, release gates) do chủ dự án cung cấp, cộng với các quyết định đã chốt qua hỏi-đáp trực tiếp (xem mục 12).

---

## 1. Mục tiêu & phạm vi

Xây dựng một Expert Advisor (EA) cho MetaTrader 5, giao dịch cặp **XAUUSD (vàng)**, kết hợp:

1. **Tín hiệu kỹ thuật "Davit Pivot"** — chiến lược pivot dài hạn theo thread ForexFactory "Davit" (bản gốc chưa có sẵn trong repo — xem mục 12.1 về placeholder).
2. **Tín hiệu AI/LLM** — một service Python cục bộ phân tích dữ liệu giá/thị trường và trả tín hiệu giao dịch dạng JSON.

EA hỗ trợ 3 chế độ vận hành (input `ENUM_SIGNAL_MODE`):

| Mode | Hành vi |
|---|---|
| `DAVIT_ONLY` | Chỉ vào lệnh theo tín hiệu Davit Pivot |
| `AI_ONLY` | Chỉ vào lệnh theo tín hiệu AI/LLM |
| `COMBINED` | Chỉ vào lệnh khi cả hai nguồn đồng thuận hướng (BUY/BUY hoặc SELL/SELL); nếu lệch hướng → HOLD |

Ngoài EA, dự án bao gồm: chỉ báo phụ trợ (Indicator) vẽ pivot, Python AI service, bộ test 2 phía (MQL5 script test + Python pytest), CI biên dịch/test tự động, backtest, và tài liệu vận hành.

## 2. Kiến trúc tổng quan

```
                    ┌─────────────────────────────┐
                    │   MetaTrader 5 Terminal      │
                    │  ┌────────────────────────┐  │
                    │  │  KV_AI_EA.mq5           │  │
Chart tick / OnTimer│  │  - SignalRouter          │  │      HTTP GET/POST
        ──────────► │  │  - PivotDavit.mqh        │  │  ───────────────────►  ┌────────────────────┐
                    │  │  - AiSignalClient.mqh────┼──┼─── http://127.0.0.1: ─►│ kv_ai_service        │
                    │  │  - RiskManager.mqh        │  │   {PORT}/v1/signal    │ (FastAPI, Python)    │
                    │  │  - RolloverGuard.mqh      │  │  ◄───────────────────  │ - provider adapters   │
                    │  │  - OrderGuard.mqh         │  │      JSON signal       │ - JSON schema validate│
                    │  │  - JsonLite.mqh           │  │                        │ - malformed-response  │
                    │  └────────────────────────┘  │                        │   handling             │
                    └─────────────────────────────┘                        └────────────────────┘
```

- EA và AI service **luôn chạy trên cùng một máy** (localhost), tránh phụ thuộc mạng bên ngoài lúc giao dịch thật. AI service tự gọi ra ngoài (LLM API) khi cần sinh tín hiệu, EA không bao giờ gọi thẳng LLM.
- Giao tiếp qua HTTP local, không qua file, không qua socket thô — xem mục 4.
- Toàn bộ trạng thái cần sống sót qua restart (vị thế đang mở, tín hiệu gần nhất, thời điểm gửi lệnh) được EA lưu bằng `GlobalVariable` có tiền tố `KVAI_` + file trạng thái JSON trong `MQL5/Files/KV_AI/state.json`.

## 3. Cấu trúc mã nguồn

```
docs/
  KV_AI_MT5_EA_SPEC_v1.1.md   (tài liệu này)
  traceability_matrix.md      (ma trận requirement -> test)
  CONFIG_GUIDE.md             (hướng dẫn cấu hình MT5 + AI service)
  RELEASE_CHECKLIST.md        (checklist gate trước khi release)
  BUG_LOG.md                  (nhật ký lỗi phát hiện/khắc phục)
  CHANGE_HISTORY.md           (lịch sử thay đổi toàn dự án)

mt5_ea/
  Experts/KV_AI/KV_AI_EA.mq5          (EA chính)
  Include/KV_AI/
    PivotDavit.mqh                    (M1 — pivot placeholder, hoán đổi được)
    AiSignalClient.mqh                (M3 — gọi AI service qua WebRequest)
    SignalRouter.mqh                  (M3 — kết hợp Davit + AI theo mode)
    RiskManager.mqh                   (M4 — sizing & risk caps)
    RolloverGuard.mqh                 (M5 — rollover/stale/wrong-week)
    OrderGuard.mqh                    (M6 — reconnection/duplicate-order)
    JsonLite.mqh                      (parser JSON tối giản, tự viết — không phụ thuộc thư viện ngoài)
  Indicators/KV_AI/
    DavitPivotPlaceholder.mq5         (hiển thị pivot trên chart, vẽ để đối chiếu bằng mắt)
  Scripts/KV_AI/
    tests/*.mq5                       (script test chạy trong Strategy Tester / MetaEditor)

mt5_ai_service/
  src/kv_ai_service/
    app.py                            (FastAPI app, endpoint /v1/signal, /v1/health)
    schemas.py                        (pydantic: request/response, versioned)
    providers/                        (adapter cho từng LLM/nguồn tín hiệu)
    davit_pivot.py                    (tính pivot dùng chung để đối chiếu với MQL5 trong backtest)
  tests/                              (pytest: unit + integration + malformed-response)
  pyproject.toml

.github/workflows/
  kv-ai-mt5.yml                       (CI: compile MQL5 trên Windows runner + pytest AI service trên Ubuntu)
```

Lý do tách `mt5_ai_service` khỏi package `tradingagents` gốc: đây là hệ thống độc lập, vòng đời release/test riêng, tránh xung đột dependency với framework LLM đa tác tử hiện có trong repo.

## 4. Giao tiếp EA ⇄ AI service

### 4.1 Vận chuyển
- HTTP/1.1 nội bộ (`http://127.0.0.1:{AiServicePort}`), EA gọi bằng `WebRequest()`.
- **Giới hạn kỹ thuật MT5 quan trọng**: `WebRequest()` chỉ hoạt động với URL đã được người dùng thêm thủ công vào *Tools → Options → Expert Advisors → Allow WebRequest for listed URL*. Đây là thao tác chỉ thực hiện được trên máy chạy MT5 thật, **không thể tự động hoá từ xa** — được ghi rõ trong `CONFIG_GUIDE.md` là bước bắt buộc trước forward-test.
- Timeout gọi: 3000 ms (cấu hình `InpAiTimeoutMs`). Quá hạn → coi là "AI unavailable", `SignalRouter` fallback theo mục 4.4.

### 4.2 Request (EA → service)
```json
{
  "schema_version": "1.0",
  "request_id": "uuid-v4",
  "symbol": "XAUUSD",
  "timeframe": "H1",
  "as_of": "2026-08-16T08:00:00Z",
  "ohlc_window": [ { "t": "...", "o":0,"h":0,"l":0,"c":0,"v":0 }, ... ],
  "open_position": { "side": "NONE|BUY|SELL", "volume": 0.0, "entry_price": 0.0 }
}
```

### 4.3 Response (service → EA)
```json
{
  "schema_version": "1.0",
  "request_id": "uuid-v4-vay-lai",
  "generated_at": "2026-08-16T08:00:02Z",
  "expiry_ts": "2026-08-16T08:05:00Z",
  "symbol": "XAUUSD",
  "signal": "BUY|SELL|HOLD",
  "confidence": 0.0,
  "stop_loss_pips": 0.0,
  "take_profit_pips": 0.0,
  "reasoning": "chuỗi ngắn giải thích"
}
```

**Điều kiện hợp lệ (validate ở cả 2 phía — service dùng pydantic, EA dùng JsonLite + kiểm tra thủ công):**
- `schema_version` phải khớp phiên bản EA hỗ trợ, khác → reject.
- `request_id` response phải khớp request đã gửi (chống trả lời trễ/nhầm phiên).
- `signal` ∈ {BUY, SELL, HOLD}, thiếu hoặc giá trị lạ → reject.
- `confidence` ∈ [0,1].
- `expiry_ts` phải > thời điểm nhận; nếu response đến sau `expiry_ts` (trễ mạng) → coi như HOLD, không dùng tín hiệu cũ.
- `generated_at` không được cách hiện tại quá `InpMaxSignalAgeSec` (mặc định 120s) → chặn tín hiệu "stale".

### 4.4 Xử lý lỗi / malformed response
Khi request lỗi mạng, timeout, HTTP != 200, JSON không parse được, hoặc vi phạm bất kỳ điều kiện ở 4.3:
- AI signal coi như `HOLD` (không bao giờ suy ra BUY/SELL từ dữ liệu hỏng).
- Ghi log `OrderGuard`/`EA` mức ERROR kèm mã lỗi cụ thể (không throw exception làm crash EA).
- Trong `COMBINED` mode: nếu AI HOLD do lỗi → toàn bộ tín hiệu thành HOLD (không fallback âm thầm về `DAVIT_ONLY`), vì đó là thay đổi hành vi rủi ro ngầm — phải hiển thị cảnh báo trên chart.
- Test bắt buộc (mục 9.4): thiếu field, sai kiểu, `confidence` ngoài [0,1], JSON rỗng, HTTP 500, timeout, `expiry_ts` quá khứ, `schema_version` không khớp.

## 5. Quản lý rủi ro & khối lượng (RiskManager.mqh)

### 5.1 Volume modes (input `ENUM_VOLUME_MODE`)
| Mode | Công thức |
|---|---|
| `FIXED_LOT` | Khối lượng cố định `InpFixedLot`, vẫn phải qua toàn bộ cap bên dưới |
| `RISK_PERCENT` | `volume = (Equity * RiskPercent/100) / (StopLossPips * PipValue)` |
| `RISK_PERCENT_CAPPED_KELLY` | Như trên, nhân thêm hệ số Kelly-phân số `InpKellyFraction` (mặc định 0.5), dựa trên confidence trả về từ AI khi có, mặc định = 1.0 khi dùng `DAVIT_ONLY` |

### 5.2 Giới hạn bắt buộc (tất cả kiểm tra **trước khi** gửi lệnh, lệnh nào vi phạm bị chặn, không "cắt bớt cho vừa"):
1. **Stop-risk cap**: rủi ro của MỘT lệnh (khoảng cách SL × volume × giá trị pip) ≤ `InpMaxRiskPerTradePct` (mặc định 1.0%) equity.
2. **Margin cap**: margin cần cho lệnh mới + margin đang dùng ≤ `InpMaxMarginUsagePct` (mặc định 50%) của Free Margin + Margin hiện tại; dùng `OrderCalcMargin()` thực tế của symbol, không ước lượng tay.
3. **Total-risk cap**: tổng rủi ro (SL) của TẤT CẢ vị thế đang mở + lệnh mới ≤ `InpMaxTotalRiskPct` (mặc định 5.0%) equity.
4. Khối lượng làm tròn theo `SYMBOL_VOLUME_STEP`, kẹp trong `[SYMBOL_VOLUME_MIN, SYMBOL_VOLUME_MAX]`; nếu sau khi kẹp mà vượt cap ở trên → **không gửi lệnh**, log `RISK_BLOCKED`.

### 5.3 Test bắt buộc
- Mỗi cap có test buộc-vượt-ngưỡng (over-limit) và biên (đúng ngưỡng ± 1 step) — xem ma trận truy vết REQ-RISK-01..07.

## 6. Rollover cuối tuần / dữ liệu cũ / sai tuần (RolloverGuard.mqh)

- **Cấm mở lệnh mới** trong cửa sổ `[Friday 21:45 server time, Sunday 22:15 server time + InpPostRolloverFreezeMin]` (mặc định freeze 15 phút sau nến đầu tuần) — tránh spread giãn/gap đầu tuần.
- **Stale data**: nếu `TimeCurrent() - iTime(symbol, PERIOD_CURRENT, 0) > InpMaxBarAgeSec` (mặc định = 1.5 × chu kỳ nến) → không giao dịch, log `STALE_DATA`.
- **Wrong-week pivot**: pivot tuần phải được tính lại đúng vào nến đầu tiên của tuần mới (phát hiện qua `TimeDayOfWeek` chuyển từ 0→1 hoặc gap thời gian > 24h giữa 2 nến daily liên tiếp), dùng OHLC của **tuần trước đã đóng** — có test buộc "tuần thiếu 1 ngày do lễ" phải không tính sai.
- Tất cả nhánh trên có script test riêng mô phỏng lịch sử qua `CTestSeries` giả lập (M5.5).

## 7. Độ bền vững kết nối & chống trùng lệnh (OrderGuard.mqh)

- **Disconnect**: `OnTimer` (chu kỳ 5s) kiểm tra `TerminalInfoInteger(TERMINAL_CONNECTED)`; mất kết nối → khoá gửi lệnh mới, giữ nguyên vị thế, không hoảng loạn đóng lệnh.
- **Timeout gửi lệnh**: `OrderSend` timeout hoặc trả lỗi retcode tạm thời (`TRADE_RETCODE_REQUOTE`, `TRADE_RETCODE_TIMEOUT`, `TRADE_RETCODE_PRICE_CHANGED`) → retry tối đa `InpMaxRetry` (mặc định 3) với backoff, **cùng một `client_order_id`**.
- **Duplicate-order**: mỗi lệnh dự định gửi có `client_order_id = HASH(symbol, signal_bar_time, side)` lưu vào `state.json` NGAY TRƯỚC khi gọi `OrderSend` (không phải sau khi thành công) — nếu EA restart giữa chừng, khi khởi động lại sẽ đọc `state.json`, thấy `client_order_id` đã "pending/sent" cho đúng bar đó thì **không gửi lại**, chỉ đối chiếu với `PositionsTotal()`/`HistoryDealsTotal()` thực tế trên server để xác nhận lệnh đã khớp hay chưa rồi cập nhật state.
- **Restart**: `OnInit()` luôn đọc `state.json` + quét `PositionsGet`/`OrdersGet` hiện có trước khi coi bất kỳ bar nào là "chưa xử lý".

## 8. Backtest & Forward-test

| Loại | Mục đích | Công cụ |
|---|---|---|
| Rule-only backtest | Kiểm tra `DAVIT_ONLY` không lỗi runtime, khớp kỳ vọng risk cap | MT5 Strategy Tester (headless CLI trên CI Windows runner nếu khả thi — xem mục 10) |
| AI-replay backtest | Ghi lại response AI thật (hoặc file replay đã thu) rồi phát lại xác định (deterministic) trong Strategy Tester qua chế độ `InpReplayMode=true` đọc từ `Files/KV_AI/replay/*.json` thay vì gọi HTTP thật | MT5 Strategy Tester |
| Real-tick out-of-sample | Chạy trên dữ liệu tick thật (không phải OHLC nội suy) của một giai đoạn KHÔNG dùng để chỉnh tham số | MT5 Strategy Tester, mode "Every tick based on real ticks" |
| Demo forward-test | Chạy EA thật trên tài khoản demo broker, tối thiểu theo thời lượng trong `RELEASE_CHECKLIST.md`, thu log + statement | MT5 terminal thật trên máy/VPS của chủ dự án — **cần chủ dự án thực hiện, tôi không thể tự chạy vì cần MT5 terminal sống kết nối broker** |

## 9. Ma trận truy vết & release gates

Xem `docs/traceability_matrix.md` để ánh xạ đầy đủ requirement (REQ-*) ↔ test case ↔ trạng thái pass/fail thực tế (không suy diễn).

## 10. CI/CD — biên dịch & test tự động

- Job `mql5-compile` (windows-latest): tải & cài MetaTrader 5 headless (`mt5setup.exe /auto`), gọi `metaeditor64.exe /compile /include /log`, parse log, **fail job nếu có bất kỳ error hoặc warning nào**, đính kèm log làm artifact.
- Job `ai-service-tests` (ubuntu-latest): `pytest` cho `mt5_ai_service`, bao gồm test malformed-response, schema, provider adapter.
- Nếu job `mql5-compile` không tải được MT5 (mạng CI bị chặn, v.v.), pipeline phải **fail rõ ràng** kèm log, không được coi là "pass" hay bỏ qua.

## 11. Cấu hình & tham số (input EA — mặc định)

| Tham số | Mặc định | Ghi chú |
|---|---|---|
| `InpSymbol` | XAUUSD | |
| `InpSignalMode` | COMBINED | DAVIT_ONLY / AI_ONLY / COMBINED |
| `InpVolumeMode` | RISK_PERCENT | |
| `InpMaxRiskPerTradePct` | 1.0 | |
| `InpMaxTotalRiskPct` | 5.0 | |
| `InpMaxMarginUsagePct` | 50.0 | |
| `InpAiServiceUrl` | http://127.0.0.1:8765 | |
| `InpAiTimeoutMs` | 3000 | |
| `InpMaxSignalAgeSec` | 120 | |
| `InpMaxRetry` | 3 | |
| `InpMagicNumber` | 20260816 | |

Tất cả tham số có thể chỉnh trong MT5 mà không cần biên dịch lại — xem `CONFIG_GUIDE.md`.

## 12. Giả định, quyết định đã chốt và rủi ro đã biết

### 12.1 Chỉ báo "Davit Pivot" — PLACEHOLDER, chưa xác thực
Chủ dự án cho biết chỉ báo gốc nằm trong thread ForexFactory "Davit Pivot" nhưng chưa gửi được file (đang dùng mobile). **Không có định nghĩa chính thức**, nên `PivotDavit.mqh` (M1) tạm dùng công thức Pivot Point chuẩn (Classic + Fibonacci) tính theo tuần, gắn nhãn rõ `// PLACEHOLDER: chưa phải Davit Pivot gốc` và tách interface (`SPivotLevels` struct + `CalcPivot()`) để khi có file gốc chỉ cần thay nội dung hàm `CalcPivot()`, không đụng phần còn lại của EA. **Đây là rủi ro đã biết, ghi vào BUG_LOG.md, chặn gate "AI-replay/rule-only backtest" ở mức production thật cho tới khi thay bằng chỉ báo thật.**

### 12.2 Kiến trúc AI-EA
Chốt: Python HTTP service local (FastAPI), EA gọi qua `WebRequest()`. Yêu cầu cấu hình thủ công "Allow WebRequest" trên máy chạy thật — nằm ngoài khả năng tự động hoá từ xa của agent.

### 12.3 Symbol mặc định
Chốt: XAUUSD. Tham số margin/pip-value trong `RiskManager.mqh` dùng `SymbolInfoDouble` động (không hard-code), nên đổi symbol khác chỉ cần đổi `InpSymbol`.

### 12.4 Giới hạn môi trường thực thi của agent
- Không có MetaTrader/MetaEditor cài sẵn trong container hiện tại (Linux, không Wine) → biên dịch/backtest MQL5 bắt buộc chạy qua CI Windows runner (mục 10), không chạy được cục bộ trong phiên này.
- Không thể điều khiển máy tính vật lý của chủ dự án (không có computer-use) → forward-test demo (mục 8, dòng cuối) chủ dự án phải tự thực hiện, agent chỉ cung cấp EA đã build + hướng dẫn.
- Mọi lần báo "PASS" trong tài liệu/báo cáo dưới đây đều phải kèm log/artifact thật từ lệnh đã chạy; nếu chưa chạy được sẽ ghi rõ **BLOCKED** kèm lý do, không suy đoán.

## 13. Roadmap cải tiến (ngoài phạm vi bắt buộc của v1.1)

Các hạng mục dưới đây KHÔNG có trong yêu cầu gốc nhưng được đề xuất bổ sung để tăng an toàn vốn khi chạy tiền thật. Xếp theo mức ưu tiên; thêm vào các milestone sau M6 (chưa có REQ ID/test — sẽ gán khi bắt đầu implement để tránh đánh PASS khống):

1. **News/economic-calendar filter (ưu tiên cao nhất)** — chặn mở lệnh mới trong cửa sổ trước/sau các tin tác động mạnh tới vàng (NFP, FOMC, CPI...). Hiện tại risk cap tính đúng vẫn không chống được gap/slippage bất thường quanh các mốc tin này. Cần nguồn dữ liệu lịch kinh tế (ví dụ ForexFactory calendar) và một `NewsGuard.mqh` tương tự `RolloverGuard.mqh`.
2. **Kill-switch khẩn cấp** — cờ điều khiển từ xa (file hoặc `GlobalVariable`) để dừng giao dịch/đóng toàn bộ vị thế ngay lập tức mà không cần gỡ EA khỏi chart. Quan trọng cho vận hành tiền thật.
3. **Ghi log quyết định có cấu trúc** — AI service lưu mỗi tín hiệu (input request + raw provider output + response cuối) vào file/CSV/DB để audit sau này, thay vì chỉ dựa vào `Print()`/log MT5.
4. **Provider LLM thật** — `StubProvider` hiện tại luôn trả HOLD; cần triển khai `RawSignalProvider` thật gọi một LLM cụ thể trước khi demo/live có ý nghĩa.

## 14. Lịch sử thay đổi tài liệu

| Version | Ngày | Thay đổi |
|---|---|---|
| v1.1 | 2026-08-16 | Khởi tạo đặc tả từ đầu (repo trước đó không có tài liệu này) |
| v1.1 (bổ sung) | 2026-08-16 | Thêm mục 13 (Roadmap cải tiến): news filter, kill-switch, logging quyết định, provider LLM thật |
