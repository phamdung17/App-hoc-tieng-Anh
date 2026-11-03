# HANDOFF REPORT — Explorer Backend

**Task**: Toàn diện kiểm tra, rà soát mã nguồn Backend FastAPI (`backend_app/backend/`)  
**Working Directory**: `d:\LapTrinhMoBa\do_an_moba\.agents\teamwork\explorer_backend\`  
**Target Report**: `d:\LapTrinhMoBa\do_an_moba\.agents\teamwork\explorer_backend\backend_audit.md`  
**Handoff Type**: Hard (Task complete)

---

## 1. Observation (Quan sát thực tế)

1. **Cấu trúc & Entrypoint Backend**:
   - `app/main.py`: Khởi tạo ứng dụng FastAPI (`create_app`), đăng ký middleware `CORSMiddleware`, vòng đời `lifespan` (init & close Redis pool), đăng ký 6 routers và 1 healthcheck endpoint:
     - `auth_router` (prefix: `/api/v1`)
     - `scan_router` (prefix: `/api/v1`)
     - `users_router` (prefix: `/api/v1`)
     - `vocab_router` (prefix: `/api/v1`)
     - `progress_router` (prefix: `/api/v1`)
     - `learning_router` (prefix: `/api/v1`)
     - `GET /health`
   - Tổng cộng: **22 endpoints hoạt động** trên 6 router modules và 1 system endpoint.
2. **Cơ sở dữ liệu & Migrations**:
   - 9 bảng SQLAlchemy ORM tại `app/core/models/`: `users`, `words`, `scans`, `scan_items`, `learning_paths`, `units`, `lessons`, `user_lesson_progress`, `user_daily_activities`.
   - 3 file migration Alembic tại `alembic/versions/`:
     - `0001_initial_schema.py`: `users`, `words`, `scans`, `scan_items`.
     - `0002_learning_tables.py`: `learning_paths`, `units`, `lessons`, `user_lesson_progress`.
     - `0003_progress_tables.py`: `user_daily_activities`.
3. **Google Social Auth & JWT**:
   - `app/modules/auth/service.py` (dòng 123–169): `login_with_google(id_token)` gọi HTTP GET đến `https://oauth2.googleapis.com/tokeninfo?id_token=...` qua `httpx.AsyncClient(timeout=10.0)`, giải mã email, họ tên, ảnh đại diện, kiểm tra `email_verified`, tạo mới user hoặc đăng nhập user có sẵn.
   - `app/core/security/jwt.py`: Cặp access token (15m) + refresh token (30d), token rotation đầy đủ qua `create_access_token` và `create_refresh_token`.
4. **AI Scan Đồ vật qua Gemini Vision API**:
   - `app/integrations/gemini/client.py`: `GeminiClient` gọi model `gemini-2.0-flash` bằng HTTP POST generateContent với base64 image data, temperature `0.1`, structured prompt yêu cầu trả JSON thuần túy gồm nhãn tiếng Anh, nghĩa tiếng Việt, IPA, loại từ, câu ví dụ và BoundingBox `[0..1]`. Hỗ trợ tự động retry 1 lần khi JSON hỏng, bắt lỗi HTTP 429, 500, timeout, và safety finishReason.
   - `app/modules/scan/service.py`: Pipeline 8 bước gồm kiểm tra `require_ai_user`, kiểm tra quota Redis (10 lượt/ngày/user), Pillow resize ảnh về tối đa 1280px, nén JPEG, upload S3 qua `boto3`, lọc confidence >= 0.5, deduplicate nhãn, tối đa 8 items, tra cứu catalog `words` (dùng lại hoặc lưu mới `is_ai_generated=True`), lưu Scan và ScanItem vào DB, hoàn trả quota nếu không có vật thể hoặc AI lỗi.
5. **Học tập (Learning) & Tiến độ (Progress) Disconnect**:
   - `app/modules/learning/service.py` (dòng 328–335): Khi user submit bài học đạt điểm >= 70 (`passed = score >= 70`), hàm `submit_lesson` chỉ cập nhật trực tiếp `update(User).values(xp_total=User.xp_total + xp_earned)`.
   - `app/modules/progress/service.py` (dòng 157–226): Hàm `ProgressService.record_activity` (upsert `UserDailyActivity`, tính chuỗi ngày học liên tục `streak_days`, cập nhật `last_activity_date`) **không bao giờ được gọi** trong toàn bộ backend (`grep_search` cho `record_activity` chỉ trả về duy nhất định nghĩa hàm trong `progress/service.py`).
6. **Lỗi cấu hình Alembic Runtime**:
   - `alembic/env.py` (dòng 39–41 và 80–87): Thay thế `postgresql+asyncpg://` thành `postgresql+psycopg2://` và gán vào `_sync_url`, nhưng sau đó lại truyền `_sync_url` vào `async_engine_from_config`, dẫn đến xung đột sync dialect với async engine.
7. **Các module chỉ có tài liệu thiết kế (Stub / Placeholder Modules)**:
   - `app/modules/review/`: Chỉ có `README.md` (chưa có Spaced Repetition SRS, Leitner box).
   - `app/modules/practice/`: Chỉ có `README.md` (chưa có luyện nhanh nghe/nói, hộp lỗi sai mistakes).
   - `app/modules/content/`: Chỉ có `README.md` (chưa có validator exercise tách riêng).
   - `app/modules/notifications/`: Chỉ có `README.md`.
   - `app/integrations/mailer/`: Chỉ có `README.md` (chưa kết nối Resend/SMTP, mã verify chỉ log debug).
   - `app/integrations/fcm/`: Chỉ có `README.md`.
   - `app/workers/`: Chỉ có `README.md` (chưa có worker ARQ chạy nền).
   - `app/seed_data/`: Chỉ có các thư mục con chứa `README.md` và `.gitkeep`, không có file dữ liệu seed thực tế.
8. **Kiểm tra cú pháp Python tĩnh**:
   - Chạy lệnh `python3.15.exe -m compileall -q app/ alembic/ tests/` đạt exit code 0, không có bất kỳ lỗi cú pháp nào.

---

## 2. Logic Chain (Chuỗi lập luận)

1. Từ **Quan sát 1 & 2**, Backend có kiến trúc phân tầng rõ ràng (FastAPI router -> Service -> Repository/ORM Models) với 22 endpoints và 9 bảng CSDL PostgreSQL.
2. Từ **Quan sát 3 & 4**, hai tính năng phức tạp nhất là Xác thực mạng xã hội Google (OAuth ID Token) và AI Scan nhận diện đồ vật (Google Gemini Vision API + Redis quota + Pillow image optimization) đã được triển khai bài bản, hoàn chỉnh và có error handling rất chi tiết.
3. Từ **Quan sát 5**, việc `submit_lesson` không gọi `record_activity` dẫn tới việc bảng `user_daily_activities` sẽ luôn trống rỗng, khiến tính năng streak và calendar biểu đồ hoạt động của user bị tê liệt nếu không nối hai hàm này lại với nhau.
4. Từ **Quan sát 6**, lệnh `alembic upgrade head` online sẽ bị lỗi dialect nếu chạy trực tiếp vì `async_engine_from_config` nhận chuỗi psycopg2. Cần sửa để dùng `settings.DATABASE_URL` trực tiếp.
5. Từ **Quan sát 7**, các phân hệ Review (Spaced Repetition), Practice (Luyện nhanh/Hộp lỗi sai), Worker và Mailer mới chỉ dừng ở mức thiết kế trong tài liệu `README.md`, chưa có code backend. Frontend hiện đang phải mock dữ liệu cho các màn hình này (`practice_hub_page.dart`).

---

## 3. Caveats (Khu vực chưa khảo sát & Giả định)

- Chưa chạy kết nối trực tiếp đến cụm PostgreSQL và Redis thật (do kiểm tra tĩnh read-only). Các hành vi của DB và Redis được phân tích thông qua code ORM, migrations và logic service.
- Chưa gửi request thật đến Google Gemini API bằng API key thật (do file `.env` hiện tại để trống `GEMINI_API_KEY`). Đã dựa trên 14 unit test cases mock httpx trong `test_gemini_client.py` để đánh giá tính đúng đắn của client.
- Giả định rằng Frontend sẽ gọi các API theo đúng Base URL `/api/v1` như đã cấu hình trong `AppConfig`.

---

## 4. Conclusion (Kết luận đánh giá)

- **Mức độ hoàn thiện tổng thể của Backend**: Đạt khoảng **70%** so với toàn bộ thiết kế kiến trúc đầy đủ; đạt khoảng **85%** đối với các luồng nghiệp vụ lõi (Core Flows) phục vụ kịch bản demo bảo vệ đồ án:
  1. *Luồng Auth*: Hoàn thiện 85% (Email/Pass + Google Sign-In + Token rotation mượt mà; chỉ thiếu gửi mail thật).
  2. *Luồng Scan AI*: Hoàn thiện 80% (Gemini 2.0 Flash prompt structured chuẩn, Redis quota, Pillow resize; cần lưu ý cấu hình S3 credentials).
  3. *Luồng Lộ trình học (Learning Path)*: Hoàn thiện 80% (Cấu trúc A1 -> Unit -> Lesson -> JSON content, logic mở khóa tuần tự và chấm điểm đạt yêu cầu).
  4. *Luồng Tiến độ (Progress)*: Hoàn thiện 50% (Cần 1 dòng code nối `record_activity` vào `submit_lesson` là hoạt động trọn vẹn).
  5. *Luồng Ôn tập (Review / SRS / Practice Hub)*: 0% (Chưa có Backend, Frontend đang mock hoàn toàn).

---

## 5. Verification Method (Phương pháp kiểm chứng độc lập)

1. **Kiểm tra cú pháp Python tĩnh**:
   ```powershell
   & "C:\Users\dungl\.local\bin\python3.15.exe" -m compileall -q "d:\LapTrinhMoBa\do_an_moba\backend_app\backend\app" "d:\LapTrinhMoBa\do_an_moba\backend_app\backend\alembic" "d:\LapTrinhMoBa\do_an_moba\backend_app\backend\tests"
   ```
   Kết quả kỳ vọng: Exit code 0, không có lỗi syntax.
2. **Kiểm tra sự tồn tại của các endpoints**:
   Mở và rà soát file `d:\LapTrinhMoBa\do_an_moba\backend_app\backend\app\main.py` và các router tương ứng trong `app/modules/*/router.py`.
3. **Kiểm tra lỗ hổng streak/progress**:
   Mở file `d:\LapTrinhMoBa\do_an_moba\backend_app\backend\app\modules\learning\service.py` tại dòng 328–355 để xác nhận không có lệnh gọi đến `record_activity` hoặc import `ProgressService`.
4. **Kiểm tra báo cáo chi tiết**:
   Mở file `d:\LapTrinhMoBa\do_an_moba\.agents\teamwork\explorer_backend\backend_audit.md`.
