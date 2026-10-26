# app/core/deps/

## Phạm vi
FastAPI dependency injection dùng chung cho database session và danh tính người gọi.

## Dependency dự kiến
- `get_db`: mở session theo request, commit/rollback/close đúng vòng đời.
- `current_user`: đọc Bearer access token, verify, lấy user còn hiệu lực; trả 401 nếu thiếu/sai/hết hạn.
- `optional_user`: chỉ tạo nếu endpoint thật sự cho guest chưa đăng nhập.
- `require_ai_user`: chặn guest bằng `AUTH_REQUIRED_FOR_AI`, chặn tài khoản chưa verified bằng `EMAIL_NOT_VERIFIED`.
- `get_redis`/settings provider: cung cấp kết nối đã cấu hình, không tạo kết nối mới mỗi lần gọi.

## Áp dụng
Gắn `require_ai_user` cho toàn bộ scan, user vocab và review endpoints theo tài liệu. Đừng chỉ ẩn UI hoặc chỉ kiểm tra ở một route con. Unit test cần bao phủ guest, unverified, verified và deleted user.
