# Backend – App học tiếng Anh + AI

Backend cung cấp REST API cho Flutter; chỉ Backend kết nối PostgreSQL, Redis, object storage và Gemini API.

## Stack
- FastAPI, Pydantic v2.
- PostgreSQL + SQLAlchemy 2.0 + Alembic.
- Redis cho rate limit/cache; ARQ worker.
- S3-compatible storage: `scans-private`, `content-public`.
- Gemini API (Google) gọi từ Backend để nhận diện vật thể và tạo thẻ từ có cấu trúc.
- Firebase Cloud Messaging và Resend/SMTP cho push/email.

## AI scan architecture
Không có container model YOLO hay detector tự host. API kiểm tra quyền/quota, xử lý ảnh, gọi Gemini qua `app/integrations/gemini/`, validate JSON bằng Pydantic, chuẩn hóa bounding box, dùng cache trong `words`, lưu scan và trả kết quả. Chỉ một Gemini call cho nhận diện và tạo thẻ từ; API key chỉ ở environment Backend.

## Cây thư mục
- `app/core/`: settings, security, dependencies, lỗi chuẩn.
- `app/modules/`: nghiệp vụ auth, users, content, learning, progress, scan, vocab, review, practice, notifications.
- `app/integrations/`: Gemini client, object storage, mailer, FCM.
- `app/workers/`: ARQ jobs nhắc học, dọn guest, xóa tài khoản/quota.
- `app/seed_data/`: words/course/exercise biên soạn sẵn; lesson không được tạo tự động lúc runtime.
- `alembic/`: migration PostgreSQL.
- `tests/`: unit, integration, fixtures.

## Quy tắc AI và dữ liệu
1. AI chỉ cho tài khoản thật đã xác minh email; enforcement ở `require_ai_user`, không chỉ ở Flutter.
2. Kiểm quota user 10 scan/ngày và system budget trước khi gọi; chỉ tính lượt khi scan thành công.
3. Seed catalog words được duyệt vẫn là dữ liệu nền. Nếu Gemini gặp lemma chưa có, backend validate rồi cache thẻ từ dùng chung trong `words`; nếu đã có thì dùng bản đã cache, không ghi đè.
4. AI chỉ tạo dữ liệu nhận diện/thẻ từ lúc scan theo prompt cố định; không sinh lessons/exercises.
5. Ảnh gửi sang Google Gemini. Cần nêu việc này trong privacy policy và kiểm tra điều khoản dữ liệu áp dụng cho gói API đang dùng.
6. Crop ảnh chỉ làm khi user lưu từ; ảnh scan private qua presigned URL 1 giờ.

## Chạy môi trường phát triển

Từ thư mục gốc repository:

```powershell
Copy-Item backend_app/backend/.env.example backend_app/backend/.env
docker compose up -d --build postgres redis
docker compose run --rm backend alembic upgrade head
docker compose up -d backend
docker compose ps
Invoke-RestMethod http://localhost:8000/health
```

Điền Gemini API key và cấu hình S3/R2 vào `.env` nếu cần thử API scan thật. Các thông tin dịch vụ để trống trong file local cho phép khởi động API, nhưng không thể gọi Gemini hoặc storage. `.env` không được commit.

## Trạng thái

Đã có code cho nền tảng FastAPI, auth, scan Gemini, users, vocab và các adapter storage/mailer/FCM. Migration đầu tiên nằm tại `alembic/versions/20261027_0001_initial_schema.py`. Cần chạy các lệnh phía trên và tests trong môi trường có Docker/Python để xác nhận schema và luồng backend hoạt động.
