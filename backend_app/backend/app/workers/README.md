# app/workers/

## Vai trò
ARQ tasks chạy ngoài HTTP request: reminder, guest cleanup, delayed account deletion, quota maintenance và xóa object storage.

## Cấu hình
Worker dùng cùng Settings/Redis và được chạy thành service/container riêng trong Compose. Job phải có timeout, retry/backoff, idempotency và logging có correlation.

## Jobs dự kiến
- Nhắc học mỗi 15 phút theo timezone; bỏ qua user đã hoạt động trong ngày.
- Dọn guest không hoạt động quá 30 ngày.
- Xóa hẳn user đã soft delete sau 30 ngày cùng tiến độ, tokens, ảnh private.
- Reset quota theo ngày bằng khóa date/timezone hoặc tạo daily row mới; không chạy reset gây race.

Job không import router hoặc phụ thuộc request context.
