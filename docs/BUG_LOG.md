# Bug Log — KV_AI_MT5_EA

Mọi lỗi phát hiện trong quá trình compile/test/review phải ghi lại đây, kể cả khi đã fix ngay, để giữ lịch sử. Không xoá dòng cũ.

| # | Ngày | Milestone | Mô tả | Mức độ | Nguyên nhân gốc | Cách khắc phục | Trạng thái |
|---|---|---|---|---|---|---|---|
| BUG-000 | 2026-08-16 | M0 | Chỉ báo "Davit Pivot" gốc chưa có sẵn (chủ dự án dùng mobile, chưa gửi được file) | Known limitation (không phải bug code) | Thiếu tài liệu nguồn | Dùng placeholder Pivot Classic/Fibonacci, tách interface `CalcPivot()` để thay sau (xem spec §12.1) | OPEN — chờ chủ dự án gửi file/định nghĩa Davit Pivot thật |
| BUG-001 | 2026-08-16 | M0 | Container agent không có MetaEditor/MetaTrader/Wine, không tải được mt5setup.exe qua proxy hiện tại (403) | Môi trường | Sandbox không có MT5 | Biên dịch chuyển sang CI Windows runner (GitHub Actions) | OPEN — chờ kết quả chạy CI thực tế lần đầu |
