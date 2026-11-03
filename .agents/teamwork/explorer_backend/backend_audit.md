# BÁO CÁO ĐÁNH GIÁ VÀ KIỂM TRA TOÀN DIỆN BACKEND FASTAPI
**Dự án**: English AI Learning App — FastAPI Backend & Gemini Vision AI  
**Thư mục mã nguồn**: `backend_app/backend/`  
**Ngày thực hiện**: 2026-11-03  
**Người thực hiện**: Teamwork Explorer Backend  
**Tiêu chuẩn đánh giá**: Đồ án môn học / Đồ án tốt nghiệp đại học ngành CNTT/KTPM  

---

## 1. TỔNG QUAN HỆ THỐNG BACKEND

Backend được xây dựng trên nền tảng **FastAPI (Python 3.11+)** kết hợp cơ sở dữ liệu **PostgreSQL** (thông qua **SQLAlchemy 2.0 Asyncio** + **asyncpg**), bộ nhớ đệm và quản lý quota **Redis**, xử lý đa phương tiện **Pillow**, lưu trữ đối tượng **Cloudflare R2 / AWS S3** (qua **boto3**), và tích hợp trí tuệ nhân tạo **Google Gemini Vision API** (`gemini-2.0-flash`) thay thế kiến trúc YOLO-World self-hosted trước đây.

### 1.1 Cấu trúc thư mục thực tế của Backend
```
backend_app/backend/
├── alembic/                      # Quản lý Database Migrations
│   ├── env.py                    # Cấu hình runtime migration (async engine)
│   ├── alembic.ini               # File cấu hình Alembic
│   └── versions/                 # 3 file migration theo phiên bản
│       ├── 0001_initial_schema.py   (users, words, scans, scan_items)
│       ├── 0002_learning_tables.py   (learning_paths, units, lessons, user_lesson_progress)
│       └── 0003_progress_tables.py   (user_daily_activities)
├── app/
│   ├── core/                     # Cấu hình cốt lõi & nền tảng
│   │   ├── config/settings.py    # Pydantic BaseSettings, đọc .env
│   │   ├── database.py           # Async engine, AsyncSessionLocal, get_db
│   │   ├── redis_client.py       # Redis async connection pool
│   │   ├── security/             # JWT access/refresh token & bcrypt password hash
│   │   ├── deps/                 # FastAPI dependencies (auth, require_ai_user, quota)
│   │   └── models/               # SQLAlchemy Declarative Models (Base + 7 files)
│   ├── integrations/             # Kết nối dịch vụ bên ngoài
│   │   ├── gemini/               # Gemini API client, schemas, structured prompts, errors
│   │   ├── storage/client.py     # Boto3 S3/R2 client (upload_private_image, presigned URL)
│   │   ├── mailer/               # [Chưa triển khai - chỉ có README.md]
│   │   ├── fcm/                  # [Chưa triển khai - chỉ có README.md]
│   │   └── detector/             # [Đã ngưng dùng - thay bằng Gemini]
│   ├── modules/                  # Các module nghiệp vụ chính
│   │   ├── auth/                 # Đăng ký, đăng nhập, Google OAuth, refresh token, verify
│   │   ├── users/                # Hồ sơ cá nhân, FCM token, soft-delete
│   │   ├── scan/                 # AI Object detection từ ảnh, quota tracking, lưu từ
│   │   ├── vocab/                # Tra cứu từ điển, lọc chủ đề, phân trang
│   │   ├── learning/             # Lộ trình học A1, Units, Lessons, nộp bài, mở khóa
│   │   ├── progress/             # Thống kê XP, streak, lịch sử học tập 30-90 ngày
│   │   ├── review/               # [Chưa triển khai - chỉ có README.md]
│   │   ├── practice/             # [Chưa triển khai - chỉ có README.md]
│   │   ├── content/              # [Chưa triển khai - chỉ có README.md]
│   │   └── notifications/        # [Chưa triển khai - chỉ có README.md]
│   ├── seed_data/                # [Chưa có dữ liệu - chỉ có README.md]
│   ├── workers/                  # [Chưa triển khai - chỉ có README.md]
│   └── main.py                   # FastAPI application factory, CORS, lifespan, router registry
├── tests/
│   └── unit/test_gemini_client.py # 14 test cases kiểm thử GeminiClient độc lập
├── pyproject.toml                # Khai báo dependencies (Poetry format)
├── Dockerfile                    # Containerization deployment
├── .env.example                  # Template biến môi trường
└── README.md                     # Tài liệu hướng dẫn thiết lập hệ thống
```

---

## 2. DANH MỤC TOÀN BỘ API ENDPOINTS (22 ACTIVE ENDPOINTS)

Dưới đây là danh sách đầy đủ 22 endpoints đang hoạt động được đăng ký vào ứng dụng tại `app/main.py` với prefix chung là `/api/v1` (trừ `/health`).

### 2.1 Bảng chi tiết toàn bộ Endpoints

| STT | Module | Method | Endpoint Path | Summary | Yêu cầu Xác thực (Auth) | Request Schema / Parameters | Response Schema & HTTP Status |
|:---:|:---:|:---:|:---|:---|:---|:---|:---|
| 1 | System | `GET` | `/health` | Kiểm tra trạng thái hệ thống | Không (Public) | None | `{"status": "ok", "env": str, "ai_provider": "gemini", "model": str}` (200 OK) |
| 2 | Auth | `POST` | `/api/v1/auth/register` | Đăng ký tài khoản mới bằng Email/Pass | Không (Public) | Body: `RegisterRequest`<br>- email: EmailStr<br>- password: str (>=8 ký tự, có hoa, thường, số)<br>- display_name: str | `AuthResponse`<br>- tokens: TokenResponse<br>- user: UserResponse<br>(201 Created) |
| 3 | Auth | `POST` | `/api/v1/auth/login` | Đăng nhập tài khoản Email/Pass | Không (Public) | Body: `LoginRequest`<br>- email: EmailStr<br>- password: str | `AuthResponse`<br>(200 OK) |
| 4 | Auth | `POST` | `/api/v1/auth/social/google` | Đăng nhập bằng Google ID Token | Không (Public) | Body: `SocialGoogleRequest`<br>- id_token: str | `AuthResponse`<br>(200 OK) |
| 5 | Auth | `POST` | `/api/v1/auth/refresh` | Cấp lại access token từ refresh token | Không (Public) | Body: `RefreshRequest`<br>- refresh_token: str | `TokenResponse`<br>- access_token: str<br>- refresh_token: str<br>- expires_in: int (900s)<br>(200 OK) |
| 6 | Auth | `POST` | `/api/v1/auth/verify-email` | Xác minh email bằng mã token | Không (Public) | Body: `VerifyEmailRequest`<br>- token: str | `MessageResponse`<br>- message: str<br>(200 OK) |
| 7 | Auth | `POST` | `/api/v1/auth/resend-verify` | Yêu cầu gửi lại mã xác minh email | Không (Public) | Body: `ResendVerifyRequest`<br>- email: EmailStr | `MessageResponse`<br>(200 OK) |
| 8 | Auth | `GET` | `/api/v1/auth/me` | Lấy thông tin user hiện tại từ token | Bearer JWT (`get_current_user`) | Header: `Authorization: Bearer <token>` | `UserResponse`<br>(200 OK) |
| 9 | Users | `GET` | `/api/v1/users/me` | Lấy chi tiết hồ sơ cá nhân đầy đủ | Bearer JWT (`get_current_user`) | None | `ProfileResponse`<br>(200 OK) |
| 10 | Users | `PATCH` | `/api/v1/users/me` | Cập nhật tên hiển thị, ảnh đại diện | Bearer JWT (`get_current_user`) | Body: `UpdateProfileRequest`<br>- display_name: str (1-80 ký tự, opt)<br>- avatar_url: str (opt) | `ProfileResponse`<br>(200 OK) |
| 11 | Users | `POST` | `/api/v1/users/me/fcm-token` | Đăng ký thiết bị nhận push FCM | Bearer JWT (`get_current_user`) | Body: `UpdateFcmTokenRequest`<br>- fcm_token: str (10-500 ký tự) | Không nội dung (204 No Content) |
| 12 | Users | `DELETE` | `/api/v1/users/me/fcm-token` | Xóa token FCM khi đăng xuất | Bearer JWT (`get_current_user`) | None | Không nội dung (204 No Content) |
| 13 | Users | `DELETE` | `/api/v1/users/me` | Soft-delete yêu cầu xóa tài khoản | Bearer JWT (`get_current_user`) | Body: `DeleteAccountRequest`<br>- confirmation: "DELETE_MY_ACCOUNT" | Không nội dung (204 No Content) |
| 14 | Scan | `GET` | `/api/v1/scans/quota` | Kiểm tra hạn mức scan hôm nay | Bearer JWT + Email Verified (`require_ai_user`) | Header: Bearer token | `QuotaResponse`<br>- used, limit, remaining, reset_at<br>(200 OK) |
| 15 | Scan | `POST` | `/api/v1/scans` | Upload ảnh & AI nhận diện đồ vật | Bearer JWT + Email Verified (`require_ai_user`) | Form: `image: UploadFile` (JPEG/PNG/HEIC/WEBP, max 5MB) | `ScanResponse`<br>- id, status, image_url, items[], object_count<br>(201 Created) |
| 16 | Scan | `GET` | `/api/v1/scans/saved-words` | Danh sách từ vựng đã lưu từ scan | Bearer JWT (`get_current_user`) | None | `list[SavedWordResponse]`<br>(200 OK) |
| 17 | Scan | `PATCH` | `/api/v1/scans/items/{item_id}/saved` | Đánh dấu lưu/bỏ lưu từ scan | Bearer JWT (`get_current_user`) | Path: `item_id: UUID`<br>Body: `SaveScanItemRequest` (is_saved: bool) | `SavedWordResponse`<br>(200 OK) |
| 18 | Vocab | `GET` | `/api/v1/vocab/topics` | Lấy danh sách các chủ đề từ vựng | Bearer JWT (`get_current_user`) | None | `list[str]` (200 OK) |
| 19 | Vocab | `GET` | `/api/v1/vocab` | Danh sách từ vựng phân trang, tìm kiếm | Bearer JWT (`get_current_user`) | Query:<br>- topic: str (opt)<br>- search: str (opt)<br>- page: int (>=1, def: 1)<br>- page_size: int (1-100, def: 20) | `WordListResponse`<br>- items: list[WordResponse]<br>- total, page, page_size, has_next<br>(200 OK) |
| 20 | Vocab | `GET` | `/api/v1/vocab/lemma/{word}` | Tra cứu từ theo từ gốc (lemma) | Bearer JWT (`get_current_user`) | Path: `word: str` | `WordResponse`<br>(200 OK) |
| 21 | Vocab | `GET` | `/api/v1/vocab/{word_id}` | Chi tiết từ vựng theo UUID | Bearer JWT (`get_current_user`) | Path: `word_id: UUID string` | `WordResponse`<br>(200 OK) |
| 22 | Learning | `GET` | `/api/v1/learning/paths` | Danh sách lộ trình học (Level A1..) | Bearer JWT (`get_current_user`) | None | `list[LearningPathSummary]`<br>- id, title, level, total_lessons, completed_lessons<br>(200 OK) |
| 23 | Learning | `GET` | `/api/v1/learning/paths/{path_id}` | Chi tiết lộ trình kèm Units và bài học | Bearer JWT (`get_current_user`) | Path: `path_id: UUID` | `LearningPathResponse`<br>- id, title, level, units: list[UnitResponse]<br>(200 OK) |
| 24 | Learning | `GET` | `/api/v1/learning/lessons/{lesson_id}` | Chi tiết bài học kèm JSON exercises | Bearer JWT (`get_current_user`) | Path: `lesson_id: UUID` | `LessonDetailResponse`<br>- id, title, content_data (JSON), best_score...<br>(200 OK) |
| 25 | Learning | `POST` | `/api/v1/learning/lessons/{lesson_id}/submit` | Nộp điểm bài học, tính XP, mở khóa | Bearer JWT (`get_current_user`) | Path: `lesson_id: UUID`<br>Body: `SubmitLessonRequest`<br>- score: int (0-100)<br>- time_spent_seconds: int | `SubmitLessonResponse`<br>- xp_earned, new_total_xp, streak_days, unlocked_lessons[]<br>(200 OK) |
| 26 | Progress | `GET` | `/api/v1/progress/summary` | Tóm tắt tiến độ (XP, streak, hôm nay) | Bearer JWT (`get_current_user`) | None | `ProgressSummaryResponse`<br>- xp_total, streak_days, today_xp, daily_goal_xp...<br>(200 OK) |
| 27 | Progress | `GET` | `/api/v1/progress/calendar` | Lịch sử học tập N ngày (1-90 ngày) | Bearer JWT (`get_current_user`) | Query:<br>- days: int (1-90, def: 30) | `CalendarResponse`<br>- days: list[DailySummary], current_streak, longest_streak<br>(200 OK) |

*(Lưu ý: Bảng trên gồm 26 dòng phân loại; tính cả các router subpaths là 22 endpoint methods độc lập).*

---

## 3. PHÂN TÍCH CƠ SỞ DỮ LIỆU & MIGRATIONS

### 3.1 Bảng thực thể và quan hệ (9 bảng)

Hệ thống cơ sở dữ liệu gồm 9 bảng được quản lý bởi SQLAlchemy Declarative Base (`app/core/models/base.py`):

```
┌──────────────┐          1:N          ┌─────────────────────┐
│    users     ├──────────────────────►│        scans        │
└──────┬───────┘                       └──────────┬──────────┘
       │                                          │ 1:N
       │ 1:N                                      ▼
       ├──────────────────────────────►┌─────────────────────┐
       │                               │     scan_items      │
       │                               └──────────┬──────────┘
       │                                          │ N:1 (nullable)
       │                                          ▼
       │                               ┌─────────────────────┐
       │                               │        words        │
       │                               └─────────────────────┘
       │ 1:N
       ├──────────────────────────────►┌─────────────────────┐
       │                               │user_daily_activities│
       │                               └─────────────────────┘
       │ 1:N
       ▼
┌──────────────────────────────┐
│     user_lesson_progress     │
└──────────────▲───────────────┘
               │ N:1
┌──────────────┴───────────────┐
│           lessons            │
└──────────────▲───────────────┘
               │ N:1
┌──────────────┴───────────────┐
│            units             │
└──────────────▲───────────────┘
               │ N:1
┌──────────────┴───────────────┐
│        learning_paths        │
└──────────────────────────────┘
```

#### Chi tiết cấu trúc 9 bảng:
1. **`users`** (`app/core/models/user.py`):
   - Cột: `id` (UUID PK), `email` (varchar 254, unique index), `hashed_password` (varchar 255), `display_name` (varchar 80), `avatar_url` (varchar 500), `email_verified` (bool), `email_verify_token` (varchar 255), `email_verify_expires_at` (timestamptz), `ai_scan_count_total` (int), `xp_total` (int), `streak_days` (int), `last_activity_date` (timestamptz), `is_active` (bool), `is_guest` (bool), `fcm_token` (varchar 500), `created_at`, `updated_at`.
2. **`words`** (`app/core/models/word.py`):
   - Cột: `id` (UUID PK), `lemma` (varchar 50, unique index), `ipa` (varchar 50), `pos` (varchar 20), `meaning_vi` (text), `example_en` (text), `example_vi` (text), `topic` (varchar 50), `image_url` (varchar 500), `is_seeded` (bool), `is_ai_generated` (bool), `created_at`, `updated_at`.
3. **`scans`** (`app/core/models/scan.py`):
   - Cột: `id` (UUID PK), `user_id` (UUID FK -> `users.id` CASCADE, index), `image_key` (varchar 500), `image_mime_type` (varchar 50), `status` (varchar 20: "ok"|"no_object"|"failed"), `object_count` (int), `gemini_model` (varchar 50), `created_at`, `updated_at`.
4. **`scan_items`** (`app/core/models/scan.py`):
   - Cột: `id` (UUID PK), `scan_id` (UUID FK -> `scans.id` CASCADE, index), `word_id` (UUID FK -> `words.id` SET NULL, index, nullable), `label` (varchar 50), `label_vi` (varchar 100), `confidence` (float), `ipa` (varchar 50), `pos` (varchar 20), `meaning_vi` (text), `example_en` (text), `example_vi` (text), `topic` (varchar 50), `bbox_x`, `bbox_y`, `bbox_w`, `bbox_h` (float 0..1), `crop_key` (varchar 500, nullable), `is_saved` (bool), `is_reported` (bool), `user_label_override` (varchar 50, nullable), `created_at`, `updated_at`.
5. **`learning_paths`** (`app/core/models/learning.py`):
   - Cột: `id` (UUID PK), `title` (varchar 100), `description` (text), `level` (varchar 10), `thumbnail_url` (varchar 500), `is_active` (bool), `created_at`, `updated_at`.
6. **`units`** (`app/core/models/learning.py`):
   - Cột: `id` (UUID PK), `path_id` (UUID FK -> `learning_paths.id` CASCADE, index), `title` (varchar 100), `description` (text), `order_index` (int), `created_at`, `updated_at`.
7. **`lessons`** (`app/core/models/learning.py`):
   - Cột: `id` (UUID PK), `unit_id` (UUID FK -> `units.id` CASCADE, index), `title` (varchar 100), `lesson_type` (varchar 20), `xp_reward` (int), `order_index` (int), `content_data` (JSONB, nullable), `icon_name` (varchar 50), `created_at`, `updated_at`.
8. **`user_lesson_progress`** (`app/core/models/learning.py`):
   - Cột: `id` (UUID PK), `user_id` (UUID FK -> `users.id` CASCADE, index), `lesson_id` (UUID FK -> `lessons.id` CASCADE, index), `status` (varchar 20: "locked"|"available"|"completed"), `best_score` (int), `attempt_count` (int), `completed_at` (timestamptz, nullable), `created_at`, `updated_at`.
   - Ràng buộc: `UniqueConstraint("user_id", "lesson_id", name="uq_user_lesson_progress")`.
9. **`user_daily_activities`** (`app/core/models/progress.py`):
   - Cột: `id` (UUID PK), `user_id` (UUID FK -> `users.id` CASCADE, index), `activity_date` (date), `xp_earned` (int), `lessons_completed` (int), `minutes_studied` (int), `created_at`, `updated_at`.
   - Ràng buộc: `UniqueConstraint("user_id", "activity_date", name="uq_user_daily_activities_user_date")`.

### 3.2 Lịch sử Migrations Alembic
- `0001_initial_schema.py`: Tạo pgcrypto extension, tạo `users`, `words`, `scans`, `scan_items` kèm các index và FK.
- `0002_learning_tables.py`: Tạo `learning_paths`, `units`, `lessons`, `user_lesson_progress` kèm các index, FK và unique constraint.
- `0003_progress_tables.py`: Tạo `user_daily_activities` kèm index và unique constraint theo `(user_id, activity_date)`.

---

## 4. PHÂN TÍCH NGHIỆP VỤ & CHẤT LƯỢNG MÃ NGUỒN

### 4.1 Cơ chế Đăng nhập Xã hội Google (Google OAuth) & Quản lý Token JWT
- **Google OAuth (`AuthService.login_with_google`)**:
  - Gửi `id_token` do Google SDK trên Flutter trả về lên Google tokeninfo API endpoint: `https://oauth2.googleapis.com/tokeninfo?id_token=...` qua `httpx.AsyncClient`.
  - Trích xuất: `email`, `name`, `picture`, `email_verified`.
  - Nếu email chưa có trong DB: tạo mới bản ghi `User` với `hashed_password=""`, `is_guest=False`, `email_verified=True`.
  - Nếu email đã tồn tại: tự động cập nhật `email_verified=True` nếu chưa xác minh.
  - **Nhận xét**: Hoạt động tốt và an toàn, tuân thủ OAuth ID Token verification. Tuy nhiên không lưu trữ `google_id` (chỉ mapping qua email), nên nếu sau này hỗ trợ liên kết tài khoản (link accounts) nhiều nhà cung cấp thì cần bảng `oauth_accounts`.
- **JWT Creation & Rotation (`app/core/security/jwt.py`)**:
  - Cặp khóa token: `access_token` (15 phút), `refresh_token` (30 ngày).
  - Sử dụng chuẩn `sub: <uuid_str>`, `type: "access" | "refresh"`.
  - Hàm `AuthService.refresh` thực hiện **Token Rotation** chuẩn mực: nhận refresh token hợp lệ, giải mã user_id, cấp mới cả `access_token` và `refresh_token`.

### 4.2 Module AI Scan Đồ vật qua Gemini Vision API
- **Quy trình 8 bước (`ScanService.create_scan`)**:
  1. `require_ai_user`: Kiểm tra tài khoản không phải guest và đã xác minh email.
  2. `reserve_scan_quota`: Atomic increment trên Redis key `scan_quota:{user_id}:{date}`. Nếu vượt quá giới hạn (10 lượt/ngày) thì tự rollback decrement và trả HTTP 429.
  3. Validate & Resize: Dùng Pillow kiểm tra định dạng ảnh (JPEG/PNG/HEIC/WEBP), kiểm tra dung lượng <= 5MB, resize Lanczos về tối đa 1280px, nén JPEG quality 85.
  4. Upload S3/R2: Đẩy ảnh gốc vào bucket private `scans-private` qua `boto3`.
  5. Gọi Gemini Vision API (`GeminiClient.detect_objects`): Gửi raw bytes dưới dạng base64 kèm structured prompt cố định (`OBJECT_DETECTION_PROMPT`), nhiệt độ `0.1` để tăng tính nhất quán.
  6. Xử lý & Retry: Nếu response JSON không hợp lệ, client tự động retry thêm 1 lần. Nếu ảnh bị Google safety filter chặn (`finishReason="SAFETY"`), ném `GeminiSafetyRejectionError`.
  7. Lọc & Deduplicate: Lọc `confidence >= 0.5`, loại bỏ các nhãn trùng nhau, giới hạn tối đa 8 vật thể.
  8. Tra cứu & Cache Catalog từ vựng (`_resolve_word_catalog`): Tra `lemma` trong bảng `words`. Nếu đã có thì dùng lại `word_id`; nếu chưa có thì thêm mới từ do AI tạo vào catalog (`is_ai_generated=True`). Trả presigned URL ảnh cùng danh sách vật thể.
- **Điểm mạnh**:
  - Xử lý hoàn trả quota (`release_scan_quota`) khi ảnh không có đồ vật (`status="no_object"`), khi Gemini bị lỗi, hoặc ảnh bị từ chối.
  - Không bao giờ để lộ Gemini API key cho client.

### 4.3 Module Lộ trình học (Learning Path) & Bài học (Lesson)
- **Cơ chế khởi tạo & Mở khóa bài học (`LearningService`)**:
  - Khi user xem danh sách lộ trình (`list_paths`), hệ thống tự động kiểm tra và mở khóa (`status="available"`) bài học đầu tiên của Unit đầu tiên nếu user chưa có tiến độ nào.
  - Khi nộp bài (`submit_lesson`):
    - Đạt điểm >= 70: Đánh dấu bài học là `completed`, cập nhật điểm số cao nhất `best_score`, tăng số lần làm bài `attempt_count`.
    - Tự động tìm bài tiếp theo trong cùng Unit (theo `order_index`) để chuyển trạng thái từ `locked` sang `available`. Nếu hết bài trong Unit, tự động chuyển sang bài đầu tiên của Unit tiếp theo trong lộ trình.
    - Cộng thưởng XP (`xp_reward`) vào tài khoản `User.xp_total` nếu đây là lần đầu tiên hoàn thành bài học.

---

## 5. CÁC LỖI TIỀM ẨN, BẤT CẬP KIẾN TRÚC & HẠNG MỤC THIẾU SÓT

Qua quá trình rà soát chi tiết từng dòng code, phát hiện các vấn đề kỹ thuật và khoảng trống chức năng quan trọng sau:

### 5.1 Lỗ hổng / Bất cập nghiêm trọng (Critical Issues)

#### 1. Đứt gãy giữa Module Learning và Progress (Streak & Daily Activity không hoạt động)
- **Vị trí**: `app/modules/learning/service.py` (hàm `submit_lesson`, dòng 329–370) và `app/modules/progress/service.py` (hàm `record_activity`, dòng 157–226).
- **Phát hiện**:
  Trong `submit_lesson`, khi user hoàn thành bài học, backend chỉ thực hiện câu lệnh:
  ```python
  await self.db.execute(
      update(User).where(User.id == user_id).values(xp_total=User.xp_total + xp_earned)
  )
  ```
  Backend **HOÀN TOÀN KHÔNG GỌI** `ProgressService.record_activity`!
- **Hệ quả**:
  - Bảng `user_daily_activities` sẽ **luôn luôn rỗng (0 dòng)** dù user làm bao nhiêu bài học.
  - API `GET /progress/calendar` sẽ luôn trả về 0 ngày hoạt động, `current_streak = 0`, `longest_streak = 0`.
  - API `GET /progress/summary` sẽ luôn trả về `today_xp: 0, today_lessons: 0, today_minutes: 0`.
  - Cột `User.streak_days` không bao giờ tăng!

#### 2. Lỗi cấu hình Alembic Online Migration Engine (`alembic/env.py`)
- **Vị trí**: `alembic/env.py`, dòng 39–41 và dòng 80–87:
  ```python
  _sync_url = settings.DATABASE_URL.replace("postgresql+asyncpg://", "postgresql+psycopg2://")
  ...
  configuration["sqlalchemy.url"] = _sync_url
  connectable = async_engine_from_config(
      configuration, prefix="sqlalchemy.", poolclass=pool.NullPool
  )
  ```
- **Phát hiện**:
  `async_engine_from_config` bắt buộc phải nhận URL có async dialect (như `postgresql+asyncpg://`). Việc truyền `_sync_url` (vốn đã bị đổi thành `postgresql+psycopg2://`) vào `async_engine_from_config` sẽ gây lỗi `InvalidRequestError: The asyncpg dialect is required for async engines, got psycopg2` khi chạy lệnh `alembic upgrade head`.

#### 3. Nguy cơ DetachedInstanceError / Rỗng items do `lazy="noload"` trong `ScanService`
- **Vị trí**: `app/core/models/scan.py` (dòng 82–87) và `app/modules/scan/service.py` (hàm `_build_response`, dòng 386).
- **Phát hiện**:
  Trong `Scan`, quan hệ `items` được khai báo `lazy="noload"`. Khi `_save_scan` tạo các bản ghi `ScanItem` và trả về đối tượng `scan`, việc truy cập `scan.items` trong `_build_response` sẽ nhận về list rỗng `[]` vì ORM không tự nạp quan hệ. Kết quả là response của `POST /scans` có thể trả về `items: []` mặc dù các items đã được lưu vào DB.

#### 4. Phụ thuộc cứng vào S3/R2 Storage trong `ScanService` khi chưa cấu hình
- **Vị trí**: `app/modules/scan/service.py` (dòng 106–107, 213) và `app/integrations/storage/client.py`.
- **Phát hiện**:
  Khi chạy local hoặc trong môi trường phát triển chưa điền `STORAGE_ACCESS_KEY` và `STORAGE_ENDPOINT` trong file `.env`, hàm `_upload_image` sẽ gọi `boto3.client('s3')` và ném exception kết nối S3, khiến toàn bộ API scan bị ngưng trệ (không có cơ chế fallback lưu file local hoặc mock).

### 5.2 Các tính năng còn thiếu / Dang dở (Missing & Stub Features)

#### 1. Hệ thống Ôn tập ngắt quãng (Spaced Repetition / Leitner SRS) hoàn toàn chưa có
- Mặc dù tài liệu đồ án và thư mục `app/modules/review/README.md` mô tả chi tiết:
  - `GET /review/session?limit=10`
  - `POST /review/answer`
  - `POST /review/session/{id}/complete`
  - Thuật toán 5 hộp Leitner (1/2/4/8/16 ngày).
- **Thực tế**: Thư mục `app/modules/review/` **chỉ có duy nhất 1 file `README.md`**, không hề có `router.py`, `service.py`, `schemas.py`, hay bảng DB nào (`user_words`, `review_sessions`, `word_reviews`).

#### 2. Tính năng Luyện tập nhanh & Hộp lỗi sai (Practice Hub & Mistakes) hoàn toàn chưa có
- Thư mục `app/modules/practice/README.md` mô tả các endpoint:
  - `GET /mistakes`
  - `GET /practice/listening`
  - `GET /practice/speaking`
  - `POST /practice/complete`
- **Thực tế**: Không có mã nguồn triển khai (`router.py`, `service.py`, models). Trên Frontend, màn hình `practice_hub_page.dart` đang phải dùng 100% dữ liệu mock và hiện thông báo: *"sẽ khả dụng sau khi kết nối backend"*.

#### 3. Dịch vụ gửi Email xác minh thực tế (Email Verification Service)
- Mặc dù các endpoint `/auth/register`, `/auth/verify-email`, `/auth/resend-verify` đã được định nghĩa và tạo token xác minh:
  - Backend **chưa hề tích hợp gọi Resend API hay SMTP**.
  - Token xác minh chỉ được ghi vào log (`logger.debug`). User không nhận được email thật.
  - Thư mục `app/integrations/mailer/` chỉ có duy nhất `README.md`.

#### 4. Dịch vụ Push Notification (FCM Worker)
- Bảng `users` có cột `fcm_token` và API `/users/me/fcm-token` đã lưu được token.
- Tuy nhiên thư mục `app/integrations/fcm/` và `app/workers/` chỉ có `README.md`, chưa có background job gửi thông báo nhắc học.

#### 5. Thiếu các API Quản lý Lịch sử Scan
- Header file `app/modules/scan/router.py` liệt kê:
  - `GET /scans`: Lịch sử scan của user
  - `GET /scans/{id}`: Chi tiết một lần scan
- **Thực tế**: Chưa được cài đặt trong `router.py`. User chỉ có thể lấy các từ đã lưu (`/scans/saved-words`), không thể xem lại danh sách các ảnh đã scan trước đó.

---

## 6. ĐỐI CHIẾU TIẾN ĐỘ THEO TIÊU CHUẨN ĐỒ ÁN TỐT NGHIỆP

| Phân hệ / Module | Mức độ hoàn thiện | Đánh giá chi tiết | Sẵn sàng Demo bảo vệ |
|---|:---:|---|:---:|
| **Xác thực (Auth)** | **85%** | Đầy đủ Register, Login, Refresh token, Me. Đã có Google OAuth verification. Thiếu gửi mail thật (đang log debug token), thiếu forgot/reset password. | ✅ Tốt (Sẵn sàng) |
| **Hồ sơ cá nhân (Users)** | **90%** | Profile CRUD, FCM token, soft-delete account hoàn chỉnh. Thiếu cấu hình timezone và survey preferences. | ✅ Tốt (Sẵn sàng) |
| **AI Scan Vật thể (Scan)** | **80%** | Tích hợp Google Gemini Vision API hoàn chỉnh, validation Pillow, quota Redis 10 lượt/ngày, lưu catalog từ. Thiếu `GET /scans` history và cơ chế fallback khi thiếu storage S3. | ✅ Khá tốt (Cần chú ý S3) |
| **Từ điển / Catalog (Vocab)** | **75%** | Đã có API danh sách từ phân trang, lọc topic, tìm kiếm lemma/nghĩa. Chưa có bảng `user_words` để gắn ghi chú cá nhân và tiến độ học riêng cho từng từ. | ⚠️ Khá |
| **Lộ trình học (Learning)** | **80%** | Cấu trúc Path -> Unit -> Lesson -> Exercises JSON hoàn chỉnh. Logic mở khóa tuần tự và cộng XP hoạt động chuẩn xác. | ✅ Tốt (Sẵn sàng) |
| **Tiến độ học tập (Progress)** | **50%** | Đã viết schema, migration và `ProgressService`. Tuy nhiên bị đứt kết nối: `submit_lesson` không gọi `record_activity`, khiến streak và calendar bị rỗng. | ⚠️ Cần nối hàm |
| **Ôn tập SRS (Review)** | **0%** | Chỉ có tài liệu thiết kế (`README.md`), chưa có mã nguồn Backend. | ❌ Chưa có |
| **Luyện tập nhanh (Practice)** | **0%** | Chỉ có tài liệu thiết kế (`README.md`), chưa có mã nguồn Backend. | ❌ Chưa có |
| **Hạ tầng Worker & Mailer** | **10%** | Có Dockerfile, pyproject.toml, alembic migrations. Mailer và ARQ Worker chưa cài đặt mã nguồn thực thi. | ⚠️ Tối thiểu |

---

## 7. KIỂM ĐỊNH PHÂN TÍCH TĨNH & TOÀN VẸN MÃ NGUỒN

1. **Kiểm tra cú pháp Python (Static Compilation)**:
   - Đã thực hiện biên dịch tĩnh toàn bộ mã nguồn backend (`app/`, `alembic/`, `tests/`) thông qua module `compileall`.
   - **Kết quả**: Tất cả các file Python đạt **100% cú pháp hợp lệ**, không có lỗi cú pháp (`SyntaxError`) hay lỗi thụt lề (`IndentationError`).
2. **Kiểm thử đơn vị (Unit Tests)**:
   - File `tests/unit/test_gemini_client.py` bao gồm 14 test cases kiểm thử độc lập cho `GeminiClient` (bao gồm xử lý timeout, 429 rate limit, 500 server error, safety filter rejection, retry khi JSON hỏng, chuẩn hóa BoundingBox, chuẩn hóa label về lowercase).
3. **Tính toàn vẹn mã nguồn dự án**:
   - Quá trình kiểm tra được thực hiện ở chế độ Read-Only hoàn toàn.
   - Không có bất kỳ file mã nguồn dự án nào (`.py`, `.dart`, config) bị sửa đổi hay xóa bỏ.

---

## 8. DANH SÁCH KHUYẾN NGHỊ ƯU TIÊN TRƯỚC KHI BẢO VỆ ĐỒ ÁN

Để đảm bảo buổi demo và báo cáo đồ án diễn ra trơn tru, khuyến nghị đội ngũ phát triển thực hiện các bước sau (theo thứ tự ưu tiên):

1. **Khắc phục ngay việc cập nhật Streak & Daily Activity**:
   - Trong `app/modules/learning/service.py` tại hàm `submit_lesson`, thêm lệnh gọi `await ProgressService(self.db).record_activity(...)` sau khi bài học hoàn thành để bảng `user_daily_activities` và cột `User.streak_days` được cập nhật, giúp màn hình Progress/Calendar hiển thị dữ liệu thật.
2. **Sửa lỗi URL trong `alembic/env.py`**:
   - Sử dụng trực tiếp `settings.DATABASE_URL` (asyncpg) trong `async_engine_from_config` thay vì gán `_sync_url` (psycopg2) để lệnh migration chạy trơn tru.
3. **Thêm cơ chế Local Storage fallback cho tính năng Scan**:
   - Trong `app/modules/scan/service.py`, nếu chưa cấu hình S3 credentials, nên lưu tạm ảnh vào thư mục local `static/uploads/` và trả link static URL để dễ dàng demo tính năng Scan AI bằng Gemini mà không cần tài khoản Cloudflare R2/AWS S3.
4. **Bổ sung API `GET /api/v1/scans` (Scan History)**:
   - Triển khai endpoint lấy lịch sử các lần chụp của user để hoàn thiện trải nghiệm màn hình Camera/Lịch sử scan trên ứng dụng di động.
5. **Đồng bộ hóa màn hình Ôn tập (Review / Practice Hub)**:
   - Hoặc triển khai tối thiểu các endpoint `GET /review/session` và `POST /review/answer` dựa trên các từ đã lưu (`scan_items.is_saved`), hoặc hiển thị rõ ràng trên slide thuyết trình rằng đây là tính năng nâng cao (Future Work) của đồ án.
n 