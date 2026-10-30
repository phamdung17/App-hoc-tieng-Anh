# app/core/config/

## Mục đích
Đọc cấu hình triển khai một lần, validate kiểu/giá trị và cung cấp settings cho app. Không để mỗi module tự đọc `os.environ` hoặc tự có default khác nhau.

## File dự kiến
- `settings.py`: Pydantic Settings; `Settings` duy nhất cho cấu hình app.
- `__init__.py`: export factory/object settings nếu cần.

## Nhóm biến môi trường
- App: `APP_ENV`, `DEBUG`, `API_V1_PREFIX`, `CORS_ORIGINS`, `LOG_LEVEL`.
- PostgreSQL: `DATABASE_URL`, pool size/timeout nếu cần.
- Redis/ARQ: `REDIS_URL`.
- Auth: `JWT_SECRET_KEY`, `JWT_ALGORITHM`, access TTL 15 phút, refresh TTL 30 ngày; secret đủ mạnh và khác nhau theo môi trường.
- Storage: endpoint, bucket `scans-private`/`content-public`, credentials, presign TTL.
- Email: Resend API key hoặc SMTP host/user/password/from address.
- FCM: đường dẫn/credential server-side; tuyệt đối không đặt Firebase server key vào Flutter.
- Detector: URL nội bộ và timeout khoảng 30 giây.
- AI safety: quota scan/user 10 mỗi ngày và ngân sách toàn hệ thống.

## Quy tắc triển khai
- Có `backend/.env.example` chỉ chứa tên biến và giá trị placeholder; `.env` thật nằm trong `.gitignore`.
- Production lấy secrets từ secret manager/environment, không fallback sang key mẫu.
- Fail fast khi thiếu cấu hình bắt buộc lúc khởi động; không log secrets trong repr/trace.
- Parse URL, số phút/giới hạn, timezone và CORS thành kiểu có validation.
- Tách dev/test/prod bằng environment, không sửa source code để đổi môi trường.

README này mô tả cấu hình cần có; hiện chưa tạo settings.py hoặc file secrets.
