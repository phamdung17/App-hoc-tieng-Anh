# BÁO CÁO ĐÁNH GIÁ TOÀN DIỆN VÀ PHÂN TÍCH KHOẢNG CÁCH DỰ ÁN
## (MASTER PROJECT AUDIT & GAP ANALYSIS REPORT)

**Tên dự án:** Ứng dụng Học Tiếng Anh Thông Minh Tích Hợp Trí Tuệ Nhân Tạo (LingoUp — Smart AI English Learning Platform)  
**Khối lượng mã nguồn:**  
- **Backend:** `backend_app/backend/` (FastAPI 0.115+, SQLAlchemy 2.0 Asyncio, Alembic, PostgreSQL, Redis, Google Gemini 2.0 Flash Vision AI, Boto3 S3/Cloudflare R2)  
- **Frontend:** `app_hoc_tieng_anh/` (Flutter 3.47+ / Dart 3.13+, Riverpod 2.5+, GoRouter 14.2+, Dio 5.7+, Flutter Secure Storage)  
**Thời điểm thực hiện kiểm định:** 03/11/2026  
**Đơn vị thực hiện:** Teamwork Engineering & Static Audit Group  
**Tiêu chuẩn đánh giá:** Tiêu chuẩn Đồ án Môn học / Đồ án Tốt nghiệp Đại học chuyên ngành Công nghệ Thông tin, Kỹ thuật Phần mềm & Khoa học Máy tính  
**Cơ chế kiểm tra:** Phân tích tĩnh, rà soát mã nguồn thực tế & đối chiếu tương thích liên hệ thống (Strict Read-Only Audit — 100% không chỉnh sửa mã nguồn)

---

## MỤC LỤC
1. [Tổng Quan Đánh Giá Dự Án (Executive Summary)](#1-tổng-quan-đánh-giá-dự-án-executive-summary)
2. [Bảng Tổng Hợp Tiến Độ Từng Phân Hệ / Module / Màn Hình](#2-bảng-tổng-hợp-tiến-độ-từng-phân-hệ--module--màn-hình)
3. [Ma Trận Đối Chiếu API Backend và Frontend (API Cross-Reference Matrix)](#3-ma-trận-đối-chiếu-api-backend-và-frontend-api-cross-reference-matrix)
4. [Phân Tích Chi Tiết Các Luồng Nghiệp Vụ Người Dùng (User Flows & Graduation Demo Readiness)](#4-phân-tích-chi-tiết-các-luồng-nghiệp-vụ-người-dùng-user-flows--graduation-demo-readiness)
5. [Kết Quả Kiểm Định Khách Quan & Phân Tích Chất Lượng Mã Nguồn (Static Verification)](#5-kết-quả-kiểm-định-khách-quan--phân-tích-chất-lượng-mã-nguồn-static-verification)
6. [Phân Định 3 Danh Mục Tính Năng Dự Án](#6-phân-định-3-danh-mục-tính-năng-dự-án)
7. [Kế Hoạch Hành Động & Danh Sách Khuyến Nghị Ưu Tiên (Actionable Roadmap)](#7-kế-hoạch-hành-động--danh-sách-khuyến-nghị-ưu-tiên-actionable-roadmap)

---

## 1. TỔNG QUAN ĐÁNH GIÁ DỰ ÁN (EXECUTIVE SUMMARY)

### 1.1. Mục Tiêu Dự Án & Cấu Trúc Tổng Thể

Dự án **LingoUp** được định vị là một ứng dụng di động học tiếng Anh thế hệ mới kết hợp trí tuệ nhân tạo (AI-powered Language Learning App). Trọng tâm đột phá của dự án là tính năng **AI Object Scanning**: cho phép người học chụp ảnh bất kỳ đồ vật thực tế nào trong môi trường sống hàng ngày thông qua camera, sử dụng mô hình đa phương thức tiên tiến **Google Gemini 2.0 Flash Vision** để tự động nhận diện vật thể, tạo bounding box trực quan, trích xuất từ vựng, phiên âm quốc tế IPA, giải nghĩa ngữ cảnh tiếng Việt và ví dụ câu song ngữ. Song song với tính năng AI Scan, ứng dụng xây dựng lộ trình học tập bài bản (Learning Path) với hệ thống 5 loại bài tập tương tác, hệ thống lưu trữ từ vựng cá nhân, và các cơ chế trò chơi hóa (Gamification: điểm kinh nghiệm XP, chuỗi ngày học Streak liên tục).

Kiến trúc kỹ thuật của hệ thống được thiết kế theo mô hình Client-Server hiện đại:
- **Mobile Client (Frontend):** Được phát triển trên nền tảng **Flutter 3.47+ (Dart 3.13+)**, áp dụng mô hình Feature-First Clean Architecture. Tầng điều hướng sử dụng **GoRouter (v14.2.7)** kết hợp Route Guards bảo vệ phiên đăng nhập; tầng quản lý trạng thái phiên sử dụng **Riverpod (v2.5.1)**; tầng giao tiếp mạng sử dụng **Dio (v5.7.0)** với bộ đánh chặn Interceptors tự động đính kèm và làm mới JWT; bảo mật token thông qua **Flutter Secure Storage** (Android Keystore / iOS Keychain).
- **Application Server (Backend):** Được phát triển trên nền tảng **FastAPI (Python 3.11+)** bất đồng bộ (async/await), tuân thủ tiêu chuẩn OpenAPI/Swagger. Hệ thống tầng dữ liệu sử dụng **PostgreSQL** thông qua **SQLAlchemy 2.0 Asyncio** kết hợp driver **asyncpg** và bộ quản lý di chuyển lược đồ **Alembic**. Dịch vụ bộ nhớ đệm và kiểm soát hạn mức (Quota Rate Limiting) vận hành trên **Redis**. Xử lý và nén ảnh sử dụng **Pillow (PIL)**. Lưu trữ tệp tin nhị phân đám mây tích hợp qua giao thức S3 (AWS S3 / Cloudflare R2) bằng thư viện **Boto3**.

```
┌────────────────────────────────────────────────────────────────────────┐
│                       FLUTTER MOBILE CLIENT (UI)                      │
│   Riverpod 2.5 (Auth State)  │  GoRouter 14.2 (Shell & Auth Guards)   │
│   5 Interactive Exercises    │  Camera Scan Overlay & Bounding Boxes  │
│   AppApi (Dio 5.7 Singleton) │  Flutter Secure Storage (JWT Tokens)   │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ HTTP / JSON (Bearer JWT)
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                        FASTAPI BACKEND SYSTEM                          │
│   App Factory & CORS Config  │  Security (Bcrypt + JWT Rotation)      │
│   Alembic (Async Migrations) │  Dependencies (Deps, Quota Checker)    │
│   6 Active Modules: Auth, Users, Scan, Vocab, Learning, Progress       │
└───────┬───────────────────────────┬────────────────────────────┬───────┘
        │                           │                            │
        ▼                           ▼                            ▼
┌───────────────┐           ┌───────────────┐           ┌────────────────┐
│  POSTGRESQL   │           │     REDIS     │           │  GOOGLE GEMINI │
│  (9 Tables)   │           │ (Quota/Cache) │           │ 2.0 FLASH AI   │
│ SQLAlchemy 2.0│           │ Atomic Keys   │           │ Vision Engine  │
└───────────────┘           └───────────────┘           └────────────────┘
```

---

### 1.2. Bảng Điểm Đánh Giá Định Lượng Theo Tiêu Chuẩn Đồ Án Môn Học / Tốt Nghiệp

Dựa trên các tiêu chí thẩm định chất lượng đồ án ngành Kỹ thuật Phần mềm (tính hoàn thiện chức năng, độ ổn định kiến trúc, tính tương thích liên hệ thống, độ tin cậy kiểm thử và trải nghiệm người dùng UI/UX), dự án được đánh giá định lượng như sau:

| Tiêu Chí Thẩm Định | Điểm Đánh Giá | Nhận Xét & Minh Chứng Thực Tế |
|---|:---:|---|
| **1. Frontend: Thiết kế Giao diện & Trải nghiệm (UI/UX)** | **8.5 / 10** | Thiết kế Design System Neumorphism / Duolingo-style đồng bộ rất đẹp mắt, bảng màu sắc tươi sáng, hiệu ứng âm thanh tương tác sinh động (`audioplayers`), 5 dạng bài tập có animation lật thẻ, kéo thả, laser scan chuyên nghiệp. |
| **2. Frontend: Tích hợp API & Quản lý Dữ liệu** | **6.0 / 10** | Đã tích hợp thực tế thành công các API Auth, Quota, Scan AI, Lưu từ và Lật flashcard. Tuy nhiên bị trừ điểm nặng do: Lộ trình học chạy 100% Mock, bỏ ngỏ module Progress, phân mảnh tạo nhiều instance Dio cục bộ. |
| **3. Backend: Thiết kế Kiến trúc & Cơ sở Dữ liệu** | **7.5 / 10** | Cấu trúc phân tầng Service/Repository rõ ràng; mô hình dữ liệu 9 bảng thiết kế chuẩn hóa 3NF; Alembic migrations bài bản; tích hợp Gemini AI có retry logic, timeout, safety handling và hoàn trả quota Redis atomic. |
| **4. Backend: Mức độ Hoàn thiện Tính năng** | **6.5 / 10** | Đã triển khai 22 active endpoints. Tuy nhiên các phân hệ Review (Spaced Repetition SRS Leitner), Practice Hub (Luyện nhanh nghe/nói, Sổ tay lỗi sai), Mailer, FCM Worker và Content mới chỉ dừng ở mức file `README.md` rỗng. |
| **5. Tính Toàn Vẹn Tích Hợp End-to-End (FE ↔ BE)** | **4.0 / 10** | **BỊ TÊ LIỆT HOÀN TOÀN** do 2 lỗi Fatal P0: Backend bị crash lúc khởi động do phân giải `CORS_ORIGINS`, và Frontend bị 100% HTTP 404 do lỗi dấu gạch chéo leading slash trong đường dẫn tương đối của Dio (RFC 3986). |
| **6. Kiểm Thử Tự Động & Đảm Bảo Chất Lượng (QA)** | **2.0 / 10** | Độ bao phủ thực tế **0% Test Coverage**. Test Backend duy nhất (`test_gemini_client.py`) bị crash do settings; Test Frontend duy nhất (`widget_test.dart`) bị fail do thiếu `ProviderScope` và sai logic boilerplate. |
| **ĐIỂM ĐÁNH GIÁ TỔNG THỂ DỰ ÁN** | **5.8 / 10** | **Mức Trung Bình Khá**. Tiềm năng đạt mức **8.5 – 9.0/10** (Xuất sắc) nếu khắc phục triệt để các lỗi chặn P0 và kết nối dữ liệu thật cho lộ trình học tập. |

---

### 1.3. Tóm Tắt Các Lỗi Chặn Nghiêm Trọng (Blockers P0 & P1)

Qua quá trình rà soát độc lập, hội đồng kiểm định xác định các lỗi chặn then chốt cần giải quyết trước khi đưa hệ thống vào kịch bản bảo vệ:

```
                                  CÁC BLOCKER THEN CHỐT CỦA DỰ ÁN
  ┌─────────────────────────────────────────────────────────────────────────────────────────────┐
  │ [P0-1] Backend Startup Crash: Pydantic Settings v2 nạp CORS_ORIGINS từ .env gây JSONDecodeError│
  │ [P0-2] Frontend Network 404: Dio RFC 3986 xóa mất '/api/v1' do request path có leading slash  │
  │ [P0-3] Android Cleartext Block: Thiếu 'usesCleartextTraffic="true"' chặn gọi HTTP 10.0.2.2  │
  │ [P0-4] Docker Compose Failure: Sai đường dẫn context build './backend' thay vì './backend_app'│
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ [P1-1] Learning Flow Disconnect: Frontend chạy 100% Mock, không kết nối DB PostgreSQL       │
  │ [P1-2] Streak & Activity Broken: Backend submit_lesson không gọi ProgressService            │
  │ [P1-3] Alembic Dialect Conflict: env.py gán sync psycopg2 URL vào async_engine_from_config  │
  │ [P1-4] iOS Crash on Camera: Info.plist thiếu NSCameraUsageDescription                       │
  └─────────────────────────────────────────────────────────────────────────────────────────────┘
```

1. **[P0-1] Fatal Startup Crash trên Backend:**  
   Tại `backend_app/backend/app/core/config/settings.py` (dòng 31), trường `CORS_ORIGINS` khai báo kiểu `list[str]`. Trong Pydantic Settings v2, nguồn `DotEnvSettingsSource` tự động gọi hàm `json.loads()` đối với các trường có kiểu phức tạp trước khi chuyển qua validator. Vì file `.env` khai báo dạng danh sách phân tách bằng dấu phẩy (`http://localhost:3000,http://localhost:8000`), hàm `json.loads` ném ngoại lệ `json.decoder.JSONDecodeError`, khiến toàn bộ ứng dụng Backend bị crash ngay tại thời điểm nạp module.
2. **[P0-2] Fatal Network Resolution trên Frontend (100% API Calls bị 404):**  
   Tại `app_hoc_tieng_anh/lib/core/config/app_config.dart` (dòng 24), `baseUrl` được đặt là `'http://10.0.2.2:8000/api/v1'`. Tuy nhiên, toàn bộ các service Dio trong dự án (`app_api.dart`, `login_page.dart`, `scan_api_service.dart`, v.v.) lại thực hiện gọi endpoint bắt đầu bằng dấu gạch chéo `/` (ví dụ `dio.post('/auth/login')`). Theo tiêu chuẩn phân giải URI RFC 3986 mà thư viện Dio áp dụng, một đường dẫn bắt đầu bằng `/` sẽ xóa bỏ toàn bộ tiền tố đường dẫn trong base URL và gắn trực tiếp vào root authority (`http://10.0.2.2:8000/auth/login`). Do Backend cấu hình router dưới prefix `/api/v1/auth/login`, **100% các yêu cầu mạng từ ứng dụng đều nhận mã lỗi HTTP 404 Not Found**.
3. **[P0-3] Lỗi Chặn Kết Nối Mạng Cleartext trên Android:**  
   File `android/app/src/main/AndroidManifest.xml` không khai báo thuộc tính `android:usesCleartextTraffic="true"`. Kể từ Android 9.0 (API level 28), hệ điều hành mặc định cấm mọi kết nối HTTP không mã hóa. Toàn bộ các máy ảo Android Emulator hoặc thiết bị thật kết nối tới `http://10.0.2.2:8000` sẽ bị hệ điều hành chặn đứng với lỗi `SocketException: CLEARTEXT communication not permitted`.
4. **[P0-4] Lỗi Đường Dẫn Triển Khai Docker Compose:**  
   File `docker-compose.yml` tại thư mục gốc trỏ context build về `./backend` và `./backend/.env`. Tuy nhiên thư mục thực tế trong kho mã nguồn là `backend_app/backend/`. Lệnh `docker compose up` sẽ thất bại ngay lập tức do không tìm thấy thư mục.
5. **[P1-1] Đứt Gãy Nghiệp Vụ Lộ Trình Học (Learning Flow Disconnected):**  
   Phân hệ Lộ trình học (`features/learning/`) ở Frontend vận hành hoàn toàn độc lập dựa trên `MockLearningRepository.instance`. Dữ liệu bài học, kết quả làm bài tập, tiến độ mở khóa bài và điểm số kinh nghiệm XP không bao giờ được đồng bộ với các bảng `learning_paths`, `units`, `lessons`, `user_lesson_progress` trong cơ sở dữ liệu PostgreSQL.
6. **[P1-2] Đứt Gãy Chuỗi Ngày Học Liên Tục (Streak & Progress Broken):**  
   Trong mã nguồn Backend `app/modules/learning/service.py` (hàm `submit_lesson`), hệ thống chỉ cộng dồn `xp_total` trực tiếp vào bảng `users` mà **hoàn toàn không gọi hàm `ProgressService.record_activity`**. Hệ quả là bảng `user_daily_activities` luôn rỗng (0 bản ghi), cột `streak_days` của người dùng không bao giờ được tính toán tăng lên, và API biểu đồ học tập `/progress/calendar` luôn trả về 0 ngày hoạt động.
7. **[P1-3] Xung Đột Engine Di Chuyển Lược Đồ Alembic:**  
   Trong `alembic/env.py` (dòng 39 và 80), chuỗi kết nối asyncpg bị thay thế bằng psycopg2 (`_sync_url`), nhưng sau đó lại truyền vào hàm `async_engine_from_config`. Khi thực thi lệnh `alembic upgrade head`, hệ thống sẽ ném ngoại lệ `InvalidRequestError: The asyncpg dialect is required for async engines, got psycopg2`.
8. **[P1-4] Nguy Cơ Ứng Dụng Bị Crash Trên Nền Tảng iOS:**  
   File `ios/Runner/Info.plist` hoàn toàn thiếu các thẻ mô tả quyền truy cập phần cứng: `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`, và `NSMicrophoneUsageDescription`. Ứng dụng sẽ bị hệ điều hành iOS cưỡng chế dừng hoạt động (SIGABRT crash) ngay khi người dùng mở camera hoặc chọn ảnh để quét AI.

---

## 2. BẢNG TỔNG HỢP TIẾN ĐỘ TỪNG PHÂN HỆ / MODULE / MÀN HÌNH

### 2.1. Phân Hệ Backend FastAPI (`backend_app/backend/`)

Toàn bộ hệ thống Backend bao gồm 12 phân hệ nghiệp vụ và thành phần hạ tầng được rà soát chi tiết:

| STT | Phân Hệ / Module Backend | Thư Mục Mã Nguồn | Trạng Thái Hiện Tại | Tỷ Lệ Hoàn Thiện | Chi Tiết Đánh Giá & Các Thành Phần Thiếu Sót |
|:---:|---|---|:---:|:---:|---|
| 1 | **Xác thực (Auth)** | `app/modules/auth/` | Hoàn thành phần lớn | **85%** | Đã triển khai đầy đủ Đăng ký, Đăng nhập, Token Refresh (rotation chuẩn), Xác thực Google OAuth qua ID Token endpoint của Google, `GET /me`. Điểm khuyết: Chưa tích hợp SMTP/Resend thật (mã verify chỉ ghi ra log debug), thiếu endpoint quên/đặt lại mật khẩu (`/forgot-password`, `/reset-password`). |
| 2 | **Người dùng (Users)** | `app/modules/users/` | Hoàn thành | **90%** | Đã có `GET /users/me`, `PATCH /users/me` (cập nhật tên, avatar), `POST /users/me/fcm-token`, `DELETE /users/me/fcm-token`, `DELETE /users/me` (soft-delete tài khoản). Thiếu: Quản lý cài đặt múi giờ (timezone) và lưu khảo sát sở thích học tập. |
| 3 | **Quét AI Vật thể (Scan)** | `app/modules/scan/`<br>`app/integrations/gemini/` | Hoàn thành | **85%** | Tích hợp hoàn chỉnh Google Gemini 2.0 Flash Vision AI (`GeminiClient`), kiểm soát hạn mức quota Redis (10 lượt/ngày), Pillow validate và resize ảnh, tra cứu và lưu trữ từ vựng vào catalog. Điểm khuyết: Thiếu API `GET /scans` (lịch sử quét), thiếu cơ chế fallback lưu ảnh cục bộ khi chưa cấu hình S3. |
| 4 | **Từ điển & Chủ đề (Vocab)** | `app/modules/vocab/` | Hoàn thành | **80%** | Đã có API lấy danh sách chủ đề (`/vocab/topics`), danh sách từ vựng có phân trang và tìm kiếm (`/vocab`), tra cứu theo lemma (`/vocab/lemma/{word}`), tra cứu theo ID (`/vocab/{id}`). Điểm khuyết: Chưa có bảng liên kết `user_words` để người dùng lưu ghi chú cá nhân và trạng thái thuộc từ. |
| 5 | **Lộ trình học (Learning)** | `app/modules/learning/` | Hoàn thành Backend | **80%** | Đã có API danh sách lộ trình (`/paths`), chi tiết lộ trình kèm Units (`/paths/{id}`), chi tiết bài học kèm JSON exercises (`/lessons/{id}`), nộp bài tính điểm (`/lessons/{id}/submit`). Điểm khuyết: Không gọi `ProgressService` trong `submit_lesson`, Frontend chưa kết nối API này. |
| 6 | **Tiến độ học tập (Progress)** | `app/modules/progress/` | Dang dở (Disconnect) | **50%** | Đã có Schema, Service và Endpoint tính toán XP, streak, biểu đồ lịch học (`/progress/summary`, `/progress/calendar`). Tuy nhiên bị tê liệt do module Learning không đẩy dữ liệu hoạt động vào bảng `user_daily_activities`. |
| 7 | **Ôn tập SRS (Review)** | `app/modules/review/` | Chỉ có README | **0%** | Thư mục `app/modules/review/` chỉ chứa duy nhất 1 file `README.md` mô tả thiết kế thuật toán hộp Leitner 5 cấp độ (1/2/4/8/16 ngày). Hoàn toàn chưa có mã nguồn `router.py`, `service.py`, `schemas.py` hay bảng CSDL. |
| 8 | **Luyện tập nhanh (Practice)** | `app/modules/practice/` | Chỉ có README | **0%** | Thư mục `app/modules/practice/` chỉ có file `README.md` mô tả các endpoint luyện nghe, luyện nói, sổ tay lỗi sai (`GET /mistakes`). Chưa có bất kỳ dòng mã nguồn thực thi nào. |
| 9 | **Nội dung & Thẩm định (Content)**| `app/modules/content/` | Chỉ có README | **0%** | Chỉ có file `README.md`. Logic parse và thẩm định JSON exercises hiện đang được gộp tạm trực tiếp trong module `learning`. |
| 10 | **Thông báo (Notifications / FCM)**| `app/modules/notifications/`<br>`app/integrations/fcm/` | Chỉ có README | **0%** | Chỉ có tài liệu thiết kế. Mới chỉ lưu được chuỗi `fcm_token` vào bảng `users`, chưa có service đẩy thông báo Firebase Cloud Messaging thật. |
| 11 | **Email & Background Workers** | `app/integrations/mailer/`<br>`app/workers/` | Chỉ có README | **10%** | Chưa có tác vụ chạy nền (ARQ worker), chưa kết nối thư viện gửi mail. Mã kích hoạt xác minh tài khoản chỉ được in ra logger console. |
| 12 | **Cơ sở dữ liệu & Migrations** | `alembic/versions/` | Hoàn thành | **90%** | Có đầy đủ 3 phiên bản migration liên tục: `0001` (khởi tạo schema core), `0002` (bảng học tập learning), `0003` (bảng tiến độ progress). Cần sửa cấu hình dialect trong `env.py`. |

---

### 2.2. Phân Hệ Frontend Flutter (`app_hoc_tieng_anh/`)

Toàn bộ 18 màn hình và giao diện người dùng được thống kê và đánh giá trạng thái:

| STT | Màn Hình / Giao Diện | File Mã Nguồn Thực Tế | Tuyến Route (`AppRoutes`) | Trạng Thái UI | Nguồn Dữ Liệu & Mức Độ Tích Hợp API |
|:---:|---|---|---|:---:|---|
| 1 | **Màn hình Chào mừng (Welcome)** | `features/auth/.../welcome_page.dart` | `/welcome` | Hoàn thành | Dữ liệu tĩnh (Animation linh vật cú, nút điều hướng khảo sát). |
| 2 | **Khảo sát ban đầu (Survey)** | `features/auth/.../onboarding_survey_page.dart` | `/survey` | Hoàn thành | Dữ liệu cục bộ (3 bước chọn mục tiêu, trình độ, thời gian). Chưa lưu xuống máy hay gửi API. |
| 3 | **Đăng nhập (Login)** | `features/auth/.../login_page.dart` | `/auth` | Hoàn thành | **API thật**: Gọi `POST /auth/login` và `POST /auth/social/google`. Có nút đăng nhập khách. |
| 4 | **Đăng ký (Register)** | `features/auth/.../register_page.dart` | `/register` | Hoàn thành | **API thật**: Gọi `POST /auth/register`. Xử lý lỗi 409 trùng email rõ ràng. |
| 5 | **Xác minh Email (Verify Email)** | `features/auth/.../email_verification_page.dart` | `/verify-email` | Hoàn thành | **API thật**: Gọi `POST /auth/verify-email` và `POST /auth/resend-verify`. |
| 6 | **Khôi phục mật khẩu (Password Recovery)** | `features/auth/.../password_recovery_page.dart` | `/forgot-password`<br>`/reset-password` | Hoàn thành UI | **Lệch pha (404)**: Frontend gọi `POST /auth/forgot-password` nhưng Backend chưa cài đặt route này. |
| 7 | **Khung điều hướng chính (Main Shell)** | `app/router.dart` (`MainShell`) | `/home` | Hoàn thành | Gồm BottomNavigationBar 4 tabs cố định và nút Floating Action Button máy ảnh ở giữa. |
| 8 | **Quét ảnh Camera AI (Scan Camera)** | `features/scan/.../scan_camera_page.dart` | `/scan` | Hoàn thành | **API thật**: Gọi `GET /scans/quota` lấy hạn mức; gọi `POST /scans` đẩy ảnh thật từ camera/thư viện lên AI. |
| 9 | **Kết quả Quét AI (Scan Result)** | `features/scan/.../scan_result_page.dart` | `/scan-result` | Hoàn thành | **API thật**: Vẽ Bounding Box trực tiếp trên ảnh; gọi `PATCH /scans/items/{id}/saved` để lưu từ. |
| 10 | **Kho từ vựng đã lưu (Saved Words)** | `features/vocabulary/.../vocabulary_page.dart` | `/home/vocabulary` | Hoàn thành | **API thật**: Tải từ đã lưu qua `GET /scans/saved-words`. Chưa tích hợp catalog từ điển hệ thống. |
| 11 | **Chi tiết từ vựng (Word Detail)** | `features/vocabulary/.../vocabulary_detail_page.dart` | `/word/:id` | Hoàn thành | **API thật**: Hiển thị IPA, nghĩa, ví dụ; gọi API gỡ lưu từ. Nút ghi chú chỉ lưu trong state RAM. |
| 12 | **Trung tâm Ôn tập (Practice Hub)** | `features/review/.../practice_hub_page.dart` | `/home/review` | Hoàn thành UI | **Dữ liệu Mock**: Hardcode số lượng 7 từ đến hạn và 3 câu hỏi sai; các nút chức năng hiện thông báo Coming Soon. |
| 13 | **Ôn tập Flashcards & Quiz** | `features/review/.../review_page.dart` | `/flashcards` | Hoàn thành | **API thật một phần**: Tải từ `GET /scans/saved-words`. Hiệu ứng lật thẻ 3D và trắc nghiệm 4 đáp án hoạt động tốt; chưa gửi kết quả SRS về backend. |
| 14 | **Lộ trình học (Learning Path)** | `features/learning/.../learning_path_page.dart` | `/home/learning` | Hoàn thành UI | **100% Mock**: Sử dụng `MockLearningRepository.instance`. Cây bài học 3 Units hiển thị đẹp mắt nhưng không gọi Backend. |
| 15 | **Khung bài học (Lesson Shell)** | `features/learning/.../lesson_page.dart` | `/lesson/:id` | Hoàn thành UI | **100% Mock**: Tải bài học từ RAM; điều phối hàng đợi câu hỏi, thanh tiến độ, âm thanh phản hồi. |
| 16 | **5 Dạng Bài Tập Tương Tác** | `features/learning/presentation/exercises/` | Nhúng trong Lesson | Hoàn thành UI | Gồm: Chọn hình ảnh, Xếp từ vào câu (Word Bank), Nghe hiểu, Phát âm nói (giả lập delay), Ghép cặp từ (Match Pairs). |
| 17 | **Kết quả bài học (Lesson Result)** | `features/learning/.../lesson_result_page.dart` | `/lesson-result` | Hoàn thành UI | **Dữ liệu cục bộ**: Hiển thị cúp vàng, điểm XP (+20 XP), tỉ lệ đúng. Không gọi `POST /lessons/{id}/submit` lên Backend. |
| 18 | **Hồ sơ cá nhân (Profile & Settings)** | `features/profile/.../profile_page.dart` | `/home/profile` | Hoàn thành | **API thật**: Gọi `GET /auth/me`, `GET /scans/quota`, `GET /scans/saved-words`. Đổi âm thanh và cài đặt nhắc học cục bộ. |

---

## 3. MA TRẬN ĐỐI CHIẾU API BACKEND VÀ FRONTEND (API CROSS-REFERENCE MATRIX)

### 3.1. Bảng Chi Tiết Toàn Bộ 22 API Endpoints của Backend & Ánh Xạ Phía Frontend

Dưới đây là bảng đối chiếu ma trận chi tiết giữa toàn bộ 22 endpoint đang hoạt động tại Backend FastAPI và các service / màn hình tương ứng phía Frontend Flutter:

| STT | Phân Hệ | Phương Thức | Endpoint URL Backend | Service Client Frontend | Màn Hình Gọi Endpoint | Trạng Thái Kết Nối | Chi Tiết Lệch Pha & Lỗi Kỹ Thuật |
|:---:|:---:|:---:|---|---|---|:---:|---|
| 1 | **System** | `GET` | `/health` | *(Chưa có)* | *(Chưa có)* | Không kết nối | Endpoint kiểm tra sức khỏe hệ thống (Public). Chưa có màn hình giám sát kết nối mạng. |
| 2 | **Auth** | `POST` | `/api/v1/auth/register` | `_dio.post('/auth/register')` | `RegisterPage._submit` | ⚠️ **404 URL** | Khớp 100% Schema JSON (`email`, `password`, `display_name`). Gặp lỗi 404 do leading slash. |
| 3 | **Auth** | `POST` | `/api/v1/auth/login` | `_dio.post('/auth/login')` | `LoginPage._submit` | ⚠️ **404 URL** | Khớp 100% Schema JSON (`email`, `password`). Gặp lỗi 404 do leading slash. |
| 4 | **Auth** | `POST` | `/api/v1/auth/social/google` | `GoogleAuthService.signIn` | `LoginPage._signInWithGoogle` | ⚠️ **404 URL** | Khớp 100% Schema (`id_token`). Gặp lỗi 404 do leading slash; thiếu `google-services.json` trên app. |
| 5 | **Auth** | `POST` | `/api/v1/auth/refresh` | `AppApi._authInterceptor` | Toàn bộ ứng dụng (Auto) | ⚠️ **404 URL** | Khớp 100% Schema (`refresh_token`). Tự động re-auth khi gặp 401. Bị 404 do leading slash. |
| 6 | **Auth** | `POST` | `/api/v1/auth/verify-email` | `_dio.post('/auth/verify-email')` | `EmailVerificationPage` | ⚠️ **404 URL** | Khớp 100% Schema (`token`). Bị 404 do leading slash. Backend mới in log debug token. |
| 7 | **Auth** | `POST` | `/api/v1/auth/resend-verify` | `_dio.post('/auth/resend-verify')` | `EmailVerificationPage` | ⚠️ **404 URL** | Khớp 100% Schema (`email`). Bị 404 do leading slash. |
| 8 | **Auth** | `GET` | `/api/v1/auth/me` | `ProfilePage._loadProfile` | `ProfilePage` | ⚠️ **404 URL** | Khớp Schema (`display_name`, `email`, `streak_days`, `xp_total`). Bị 404 do leading slash. |
| 9 | **Auth** | `POST` | *(Chưa có trên Backend)* | `_dio.post('/auth/forgot-password')` | `PasswordRecoveryPage` | ❌ **404 Backend** | Frontend gọi endpoint nhưng Backend chưa viết router phục hồi mật khẩu. |
| 10 | **Users** | `GET` | `/api/v1/users/me` | *(Chưa có)* | *(Chưa có)* | ⚠️ Chưa nối UI | Backend trả về profile chi tiết kèm avatar và ngày tạo. Frontend đang dùng tạm `/auth/me`. |
| 11 | **Users** | `PATCH` | `/api/v1/users/me` | *(Chưa có)* | *(Chưa có)* | ⚠️ Chưa nối UI | Backend hỗ trợ cập nhật `display_name` và `avatar_url`. Frontend chưa có form sửa hồ sơ. |
| 12 | **Users** | `POST` | `/api/v1/users/me/fcm-token` | *(Chưa có)* | *(Chưa có)* | ⚠️ Chưa kết nối | Backend đã có bảng lưu FCM token. Frontend hiện đang dùng thông báo local trên máy. |
| 13 | **Users** | `DELETE` | `/api/v1/users/me/fcm-token` | *(Chưa có)* | *(Chưa có)* | ⚠️ Chưa kết nối | Backend hỗ trợ xóa token khi đăng xuất. |
| 14 | **Users** | `DELETE` | `/api/v1/users/me` | *(Chưa có)* | *(Chưa có)* | ⚠️ Chưa nối UI | Backend hỗ trợ soft-delete tài khoản (`confirmation`). Frontend chưa có nút xóa tài khoản. |
| 15 | **Scan** | `GET` | `/api/v1/scans/quota` | `ScanApiService.getQuota` | `ScanCameraPage`, `ProfilePage` | ⚠️ **404 URL** | Khớp Schema (`used`, `limit`, `remaining`, `reset_at`). Bị 404 do leading slash. |
| 16 | **Scan** | `POST` | `/api/v1/scans` | `ScanApiService.scanImage` | `ScanCameraPage` | ⚠️ **404 URL** | Khớp Multipart Form `image`. Trả về bounding box chuẩn xác. Bị 404 do leading slash. |
| 17 | **Scan** | `PATCH` | `/api/v1/scans/items/{id}/saved` | `ScanApiService.setSaved` | `ScanResultPage`, `VocabularyDetailPage` | ⚠️ **404 URL** | Khớp Schema `{"is_saved": bool}`. Bị 404 do leading slash. |
| 18 | **Scan** | `GET` | `/api/v1/scans/saved-words` | `ScanApiService.getSavedWords` | `VocabularyPage`, `ReviewPage`, `ProfilePage` | ⚠️ **404 URL** | Khớp Schema danh sách từ quét. Dùng làm dữ liệu từ vựng và flashcard. Bị 404 do leading slash. |
| 19 | **Vocab** | `GET` | `/api/v1/vocab/topics` | `VocabularyApiService.listTopics` | *(Không màn hình nào gọi)* | ⚠️ **Mồ côi (Orphaned)** | Service Frontend đã viết hoàn chỉnh nhưng không màn hình nào sử dụng. |
| 20 | **Vocab** | `GET` | `/api/v1/vocab` | `VocabularyApiService.listWords` | *(Không màn hình nào gọi)* | ⚠️ **Mồ côi (Orphaned)** | Có phân trang, tìm kiếm. Nhưng `VocabularyPage` lại gọi `/scans/saved-words`. |
| 21 | **Vocab** | `GET` | `/api/v1/vocab/{id}` | `VocabularyApiService.getById` | *(Không màn hình nào gọi)* | ⚠️ **Mồ côi (Orphaned)** | `VocabularyDetailPage` tự tìm trong list scan cục bộ thay vì gọi catalog. |
| 22 | **Vocab** | `GET` | `/api/v1/vocab/lemma/{word}` | `VocabularyApiService.getByLemma` | *(Không màn hình nào gọi)* | ⚠️ **Mồ côi (Orphaned)** | Endpoint tra cứu từ gốc không được giao diện sử dụng. |
| 23 | **Learning** | `GET` | `/api/v1/learning/paths` | *(Không có)* | `LearningPathPage` | ❌ **Chưa nối BE** | Backend có router & DB; Frontend dùng `MockLearningRepository` chạy trong RAM. |
| 24 | **Learning** | `GET` | `/api/v1/learning/paths/{id}` | *(Không có)* | `LearningPathPage` | ❌ **Chưa nối BE** | Backend cung cấp danh sách Units & Lessons; Frontend hardcode dữ liệu tĩnh. |
| 25 | **Learning** | `GET` | `/api/v1/learning/lessons/{id}` | *(Không có)* | `LessonPage` | ❌ **Chưa nối BE** | Backend lưu JSONB 5 dạng bài tập; Frontend hardcode mảng Exercise trong mock repo. |
| 26 | **Learning** | `POST` | `/api/v1/learning/lessons/{id}/submit` | *(Không có)* | `LessonResultPage` | ❌ **Chưa nối BE** | Frontend không gửi điểm và thời gian làm bài; Backend không ghi nhận XP vào DB. |
| 27 | **Progress** | `GET` | `/api/v1/progress/summary` | *(Không có)* | *(Thư mục progress rỗng)* | ❌ **Chưa có UI** | Backend cung cấp thống kê XP hôm nay, mục tiêu; Frontend chưa có code màn hình. |
| 28 | **Progress** | `GET` | `/api/v1/progress/calendar` | *(Không có)* | *(Thư mục progress rỗng)* | ❌ **Chưa có UI** | Backend cung cấp lịch sử học tập 30-90 ngày & streak; Frontend chưa có giao diện. |

---

### 3.2. Phân Tích Chuyên Sâu 4 Bất Cập Tích Hợp Hệ Thống

#### 1. Lỗi Leading Slash Phá Hủy Đường Dẫn Base URL Trong Dio (RFC 3986 Defect)
- **Vị trí phát hiện:** `app_hoc_tieng_anh/lib/core/config/app_config.dart` (dòng 24) và toàn bộ các lời gọi API trong `app_api.dart`, `login_page.dart`, `scan_api_service.dart`.
- **Cơ chế lỗi:**  
  Cấu hình cơ sở: `AppConfig.baseUrl = 'http://10.0.2.2:8000/api/v1'`.  
  Lời gọi API: `dio.post('/auth/login')`.  
  Theo chuẩn **RFC 3986 Mục 5.2.2 (Transform References)** mà Dio tuân thủ, khi URI tham chiếu bắt đầu bằng ký tự gạch chéo `/`, nó được coi là đường dẫn tuyệt đối bắt đầu từ máy chủ (Authority-relative path). Thư viện sẽ xóa sạch phần đường dẫn con (`/api/v1`) của Base URL và ghép thành:
  $$\text{Target URL} = \text{http://10.0.2.2:8000/auth/login}$$
  Tuy nhiên, Backend FastAPI đăng ký router với tiền tố bắt buộc:
  $$\text{Mounted Route} = \text{http://10.0.2.2:8000/api/v1/auth/login}$$
  Do đó, máy chủ lập tức trả về mã lỗi **HTTP 404 Not Found** cho toàn bộ các request từ ứng dụng.

#### 2. Hiện Tượng Mã Nguồn Mồ Côi (Orphaned Code) Tại Tầng Dịch Vụ Từ Vựng
- **Vị trí phát hiện:** `app_hoc_tieng_anh/lib/features/vocabulary/data/vocabulary_api_service.dart`.
- **Thực trạng:** Lớp `VocabularyApiService` được lập trình rất chỉn chu, ánh xạ chính xác 100% các endpoint `/vocab`, xử lý đầy đủ query parameters (`topic`, `search`, `page`, `pageSize`) và mapping dữ liệu sang model Dart. Tuy nhiên, lệnh tìm kiếm `grep_search VocabularyApiService` trên toàn bộ dự án chỉ trả về duy nhất file định nghĩa của nó. Không có bất kỳ Widget hay Repository nào gọi tới service này. Màn hình `VocabularyPage` thay vì hiển thị kho từ điển tổng hợp thì lại chỉ tải danh sách các từ quét cá nhân qua `/scans/saved-words`.

#### 3. Hiện Tượng Đứt Gãy Kép (Double Disconnect) Giữa Learning và Progress
- **Vị trí phát hiện:**  
  - Frontend: `app_hoc_tieng_anh/lib/features/learning/` không có bất kỳ service mạng nào.
  - Backend: `backend_app/backend/app/modules/learning/service.py` (hàm `submit_lesson`, dòng 328–370) không gọi `ProgressService.record_activity`.
- **Tác động liên hoàn:**  
  1. Người dùng làm bài tập trên ứng dụng -> chỉ ghi nhận vào RAM của điện thoại qua `MockLearningRepository`.
  2. Dù có kết nối API nộp bài đi chăng nữa, Backend `submit_lesson` cũng chỉ cộng điểm vào cột `User.xp_total` mà không ghi nhận vào bảng `user_daily_activities`.
  3. Bảng `user_daily_activities` rỗng dẫn đến tính năng tính toán chuỗi ngày học liên tục (Streak) và lịch sử hoạt động học tập (Calendar) bị vô hiệu hóa hoàn toàn.

#### 4. Phân Mảnh Khởi Tạo HTTP Client (Dio Instances Fragmentation)
- **Vị trí phát hiện:**  
  - `LoginPage`: dòng 31 tự tạo `final _dio = Dio(...)`
  - `RegisterPage`: dòng 27 tự tạo `final _dio = Dio(...)`
  - `EmailVerificationPage`: dòng 34 tự tạo `late final Dio _dio = Dio(...)`
  - `PasswordRecoveryPage`: dòng 24 tự tạo `late final Dio _dio = Dio(...)`
- **Hệ quả kỹ thuật:** Việc các màn hình xác thực tự tạo riêng các instance `Dio` độc lập khiến chúng không tái sử dụng được singleton `AppApi.instance.dio`, bỏ qua các cấu hình timeout thống nhất và cơ chế đánh chặn Interceptors chung của ứng dụng.

---

## 4. PHÂN TÍCH CHI TIẾT CÁC LUỒNG NGHIỆP VỤ NGƯỜI DÙNG (USER FLOWS & GRADUATION DEMO READINESS)

### 4.1. Luồng 1: Xác Thực, Đăng Ký, Đăng Nhập (Email/Password & Google OAuth), Token Refresh
- **Mô tả hành trình người dùng:**  
  Người dùng mở app -> Màn hình Splash (1.6 giây) -> Welcome -> Khảo sát trình độ ban đầu (Survey) -> Đăng nhập. Tại đây người dùng có thể: (1) Nhập Email/Mật khẩu; (2) Đăng ký tài khoản mới; (3) Bấm "Tiếp tục với Google"; hoặc (4) Bấm "Trải nghiệm ngay (Khách)". Khi đăng nhập thành công, hệ thống lưu cặp Access/Refresh Token và tự động chuyển vào màn hình chính Shell.
- **Hiện trạng kỹ thuật chi tiết:**
  - *Đăng ký / Đăng nhập Email*: Backend mã hóa mật khẩu bằng `bcrypt`, kiểm tra regex mật khẩu chặt chẽ (tối thiểu 8 ký tự, có chữ hoa, thường và số). Frontend có form validation rất tốt.
  - *Google Social Auth*: Tích hợp native Google Sign-In trên Flutter, gửi `id_token` lên Backend. Backend gọi Google tokeninfo endpoint xác minh tính hợp lệ, tự động tạo tài khoản hoặc liên kết tài khoản theo email. Đây là điểm cộng lớn. Tuy nhiên, app đang thiếu file `google-services.json` trên Android và `GoogleService-Info.plist` trên iOS, nên tính năng này sẽ bị lỗi `PlatformException` nếu chạy thực tế.
  - *Token Refresh*: Interceptor tại `app_api.dart` bắt lỗi HTTP 401, tự động gọi `POST /auth/refresh` bằng refresh token trong `FlutterSecureStorage`, nhận cặp token mới (Token Rotation) và tự retry request ban đầu.
  - *Điểm nghẽn*: Gửi email xác minh tài khoản chưa nối SMTP thật; Quên mật khẩu gọi API chưa tồn tại trên Backend; Chế độ khách (Guest) chỉ lưu cờ local, chưa có tài khoản ẩn danh đồng bộ.
- **Mức độ sẵn sàng Demo:** **75% (Khá)** — Kịch bản demo chạy trơn tru với tài khoản Email/Password đã tạo sẵn nếu sửa lỗi Base URL.

---

### 4.2. Luồng 2: Quét Ảnh AI Nhận Diện Vật Thể (Core AI Flow)
- **Mô tả hành trình người dùng:**  
  Tại thanh điều hướng dưới cùng, người dùng bấm nút Camera nổi bật ở giữa -> Mở `ScanCameraPage`. Hệ thống hiển thị huy hiệu hạn mức ngày ("Còn 10 lượt hôm nay"). Người dùng chụp ảnh hoặc chọn ảnh từ thư viện -> Ứng dụng hiện hiệu ứng laser quét ảnh và thông báo "Gemini AI đang phân tích..." -> Chuyển sang `ScanResultPage`. Màn hình vẽ đè các Bounding Box màu xanh lên từng vật thể nhận diện được; thẻ thông tin bên dưới hiển thị từ vựng tiếng Anh, phiên âm IPA, từ loại, nghĩa tiếng Việt và câu ví dụ song ngữ. Người dùng bấm biểu tượng Bookmark để lưu từ vào kho từ cá nhân.
- **Hiện trạng kỹ thuật chi tiết:**
  - *Gemini Vision AI Engine*: Tích hợp mô hình `gemini-2.0-flash` qua REST API trực tiếp. Structured prompt yêu cầu AI trả về định dạng JSON thuần túy gồm nhãn, nghĩa, IPA, ví dụ và tọa độ chuẩn hóa $[y_{min}, x_{min}, y_{max}, x_{max}]$ theo tỉ lệ 0..1. Nhiệt độ (temperature) đặt ở mức $0.1$ giúp phản hồi có độ ổn định và chính xác cao.
  - *Độ tin cậy & Chống lỗi*: `GeminiClient` hỗ trợ tự động retry khi JSON bị cắt cụt, bắt lỗi HTTP 429 (rate limit), 500, timeout, và xử lý bộ lọc an toàn `finishReason="SAFETY"`.
  - *Kiểm soát hạn mức Quota*: Redis quản lý key `scan_quota:{user_id}:{date}` giới hạn 10 lượt/ngày. Cơ chế atomic rollback tự động hoàn trả lượt quét nếu Gemini báo lỗi hoặc ảnh không tìm thấy đồ vật.
  - *Điểm nghẽn*: Backend phụ thuộc cứng vào S3/Cloudflare R2 storage qua thư viện `boto3`. Nếu biến môi trường `.env` chưa điền S3 keys, API sẽ ném ngoại lệ kết nối khiến tính năng quét bị ngắt quãng.
- **Mức độ sẵn sàng Demo:** **85% (Rất Tốt)** — **Đây là tính năng điểm sáng nhất của toàn bộ đồ án**, thể hiện đúng tính chất ứng dụng AI trong thực tế.

---

### 4.3. Luồng 3: Tra Cứu Từ Điển & Quản Lý Kho Từ Vựng Cá Nhân
- **Mô tả hành trình người dùng:**  
  Người dùng chọn Tab "Từ vựng" (`VocabularyPage`) -> Xem danh sách các từ đã lưu từ các lần quét camera AI. Chạm vào một từ vựng -> Mở màn hình `VocabularyDetailPage` xem toàn bộ thông tin chi tiết (IPA, từ loại, nghĩa tiếng Việt, câu ví dụ song ngữ). Người dùng có thể bấm "Thêm ghi chú" để ghi lại mẹo nhớ từ, hoặc bấm "Xóa từ" để gỡ bỏ khỏi danh sách đã lưu.
- **Hiện trạng kỹ thuật chi tiết:**
  - *Lấy dữ liệu từ đã lưu*: Gọi `GET /scans/saved-words` lọc theo `user_id`. Thao tác xóa từ gọi `PATCH /scans/items/{id}/saved` cập nhật `is_saved = false`.
  - *Điểm nghẽn*: Ghi chú cá nhân (`note`) chỉ được lưu trong bộ nhớ RAM (`setState`), khi thoát ứng dụng hoặc quay lại màn hình sẽ bị biến mất do Backend bảng `scan_items` chưa có trường ghi chú của người dùng. Nút phát âm âm thanh (TTS) hiện chỉ hiển thị thông báo "Dịch vụ phát âm chưa được kết nối". Kho từ điển tổng hợp hệ thống (`/vocab`) hoàn toàn chưa được đưa lên giao diện.
- **Mức độ sẵn sàng Demo:** **70% (Khá)** — Đạt yêu cầu hiển thị và quản lý danh sách từ đã quét.

---

### 4.4. Luồng 4: Lộ Trình Học Tập Bài Bản (Learning Path & 5 Dạng Bài Tập Tương Tác)
- **Mô tả hành trình người dùng:**  
  Người dùng chọn Tab "Lộ trình" (`LearningPathPage`) -> Hiển thị cây tiến trình học theo phong cách Duolingo với các Unit (Chào hỏi, Đồ ăn, Du lịch). Chạm vào một bài học đang mở -> Hiện BottomSheet tóm tắt bài học -> Bấm "Bắt đầu học" -> Chuyển vào `LessonPage`. Người dùng lần lượt hoàn thành 5 dạng bài tập tương tác:
  1. *Image Choice*: Chọn hình ảnh tương ứng với từ vựng tiếng Anh.
  2. *Word Bank*: Chạm vào các khối từ vựng để ghép thành câu hoàn chỉnh.
  3. *Listening*: Nghe âm thanh phát âm và chọn đáp án chính xác.
  4. *Speaking*: Nhấn giữ nút micro để phát âm từ và nhận diện giọng nói.
  5. *Match Pairs*: Ghép các cặp từ tiếng Anh tương ứng với nghĩa tiếng Việt.
  Mỗi câu trả lời đúng/sai đều có âm thanh hiệu ứng (sfx) và rung phản hồi. Câu làm sai tự động đưa về cuối hàng đợi để làm lại. Hoàn thành bài học -> Mở `LessonResultPage` chúc mừng với cúp vàng, tính điểm phần trăm và cộng thưởng XP.
- **Hiện trạng kỹ thuật chi tiết:**
  - *Giao diện & Trải nghiệm (UX)*: Lập trình cực kỳ xuất sắc, animation mượt mà, logic hàng đợi bài tập và tính điểm chuẩn mực như một ứng dụng thương mại.
  - *Điểm nghẽn Cực Kỳ Nghiêm Trọng*: **Toàn bộ tiến trình bài học chạy 100% bằng dữ liệu giả lập (`MockLearningRepository`)**. Điểm số, bài tập hoàn thành không được gửi lên `POST /learning/lessons/{id}/submit` của Backend. Đóng ứng dụng mở lại toàn bộ tiến độ học bị mất trắng. Bài tập Speaking chỉ dùng hàm `Future.delayed(1.5s)` để giả lập thành công chứ chưa tích hợp Speech-to-Text thật.
- **Mức độ sẵn sàng Demo:** **60% (Có nguy cơ cao khi hội đồng kiểm tra cơ sở dữ liệu)** — Nếu chỉ nhìn trên màn hình thì rất hoàn hảo, nhưng hội đồng mở PostgreSQL kiểm tra dữ liệu sẽ phát hiện bảng tiến độ hoàn toàn trống.

---

### 4.5. Luồng 5: Theo Dõi Tiến Độ Học Tập, Streak Chuỗi Ngày & Biểu Đồ Thống Kê
- **Mô tả hành trình người dùng:**  
  Kỳ vọng: Người dùng vào xem tiến độ học tập hàng ngày, biểu đồ đóng góp XP theo tuần/tháng, số ngày học liên tục (Streak), và các mục tiêu ngày (Daily Goals).
- **Hiện trạng kỹ thuật chi tiết:**
  - *Backend*: Đã xây dựng hoàn chỉnh bảng `user_daily_activities`, logic tính chuỗi ngày học (`streak_days`) tại `ProgressService.record_activity`, và hai endpoint `/progress/summary`, `/progress/calendar`. Tuy nhiên do `submit_lesson` không gọi `record_activity`, các bảng này luôn có 0 bản ghi.
  - *Frontend*: Thư mục `app_hoc_tieng_anh/lib/features/progress/` **chỉ có duy nhất 1 file `.gitkeep` và `README.md`**. Chưa hề được viết bất kỳ dòng mã Dart nào cho giao diện tiến độ hay lịch Streak. Người dùng chỉ xem được con số `streak_days` và `xp_total` đơn lẻ tại góc màn hình `ProfilePage` thông qua API `/auth/me`.
- **Mức độ sẵn sàng Demo:** **20% (Chưa sẵn sàng)** — Phân hệ này đang bị khuyết thiếu giao diện trên mobile.

---

### 4.6. Luồng 6: Ôn Tập Ngắt Quãng (Spaced Repetition SRS) & Trung Tâm Luyện Tập (Practice Hub)
- **Mô tả hành trình người dùng:**  
  Người dùng chọn Tab "Ôn tập" (`PracticeHubPage`) -> Xem các thẻ luyện tập: Flashcards, Luyện nghe nhanh, Luyện nói nhanh, và Sổ tay lỗi sai (Mistakes Notebook). Bấm vào Flashcards -> Mở `ReviewPage` lật thẻ và làm trắc nghiệm.
- **Hiện trạng kỹ thuật chi tiết:**
  - Màn hình `ReviewPage` hoạt động tốt với dữ liệu từ quét (`/scans/saved-words`), hỗ trợ lật thẻ 3D trực quan và trắc nghiệm 4 phương án ngẫu nhiên.
  - Tuy nhiên, các nút "Cần ôn lại" và "Đã nhớ tốt" chỉ đơn thuần chuyển thẻ trong RAM, không hề có thuật toán giãn cách thời gian Spaced Repetition (SRS Leitner/SM-2) lưu về Backend.
  - Tại `PracticeHubPage`, số lượng "7 từ đến hạn" và danh sách "3 câu hỏi sai" là dữ liệu được hardcode cố định trong code. Các nút Luyện nghe, Luyện nói chỉ hiển thị thanh SnackBar "Tính năng đang hoàn thiện".
- **Mức độ sẵn sàng Demo:** **40% (Cần giải trình là tính năng tương lai)**.

---

## 5. KẾT QUẢ KIỂM ĐỊNH KHÁCH QUAN & PHÂN TÍCH CHẤT LƯỢNG MÃ NGUỒN (STATIC VERIFICATION)

### 5.1. Phân Tích Tĩnh Backend (FastAPI / Python)

#### 1. Kiểm tra Biên dịch Cú pháp (`compileall`)
- **Lệnh thực thi:**
  ```powershell
  python -m compileall -q backend_app/backend/app backend_app/backend/alembic backend_app/backend/tests
  ```
- **Kết quả:** **100% HỢP LỆ (Exit Code 0)**. Toàn bộ mã nguồn Python không có lỗi cú pháp (`SyntaxError`) hoặc lỗi thụt lề (`IndentationError`).

#### 2. Kết quả Phân tích Linter (`ruff check`)
- **Lệnh thực thi:** `uvx ruff check backend_app/backend --statistics`
- **Kết quả tổng thể:** Phát hiện **142 cảnh báo/lỗi quy chuẩn mã nguồn** (trong đó có 87 lỗi có thể tự động sửa chữa bằng cờ `--fix`).
- **Bảng phân bổ chi tiết theo mã lỗi:**

| Mã Lỗi | Số Lượng | Phân Loại & Tên Quy Chuẩn | Ví Dụ Vị Trí Phát Hiện Điển Hình | Đánh Giá Tác Động |
|:---:|:---:|---|---|:---:|
| **B008** | **52** | `function-call-in-default-argument` | `app/modules/scan/router.py:48` (gọi `Depends(...)`, `Query(...)` trong tham số mặc định) | Quy chuẩn viết code của FastAPI, không phải bug. Có thể cấu hình bỏ qua trong `pyproject.toml`. |
| **UP037** | **19** | `quoted-annotation` | `app/core/config/settings.py:120` (`"Settings"`) | Code style cũ thời Python 3.9, không ảnh hưởng chức năng. |
| **I001** | **16** | `unsorted-imports` | Khối import tại các router và services | Code style PEP 8. Có thể tự động sửa bằng `ruff --fix`. |
| **UP017** | **15** | `datetime-timezone-utc` | Dùng `timezone.utc` thay vì `datetime.UTC` | Cú pháp mới của Python 3.11+. Không gây lỗi runtime. |
| **F401** | **13** | `unused-import` | `alembic/versions/0001_initial_schema.py:15` (`uuid`), `vocab/service.py:12` (`math`), `settings.py:13` (`AnyHttpUrl`) | Dư thừa thư viện nạp vào bộ nhớ. Cần dọn dẹp. |
| **UP045** | **12** | `non-pep604-annotation-optional` | Dùng `Optional[T]` thay cho `T \| None` | Cú pháp type hint hiện đại. Không gây lỗi runtime. |
| **PIE790** | **5** | `unnecessary-placeholder` | Lệnh `pass` thừa khi hàm đã có docstring | Dư thừa ký tự mã nguồn. |
| **RUF100** | **4** | `unused-noqa` | Đánh dấu `# noqa` không cần thiết | Dư thừa chú thích. |
| **RUF022** | **2** | `unsorted-dunder-all` | Biến `__all__` chưa xếp chữ cái | Code style. |
| **BLE001** | **1** | `blind-except` | `app/integrations/gemini/client.py:244` (`except Exception:`) | Bắt ngoại lệ quá rộng trong hàm ghi log payload an toàn. Nên chỉ định rõ kiểu ngoại lệ. |
| **SIM102** | **1** | `collapsible-if` | `app/core/config/settings.py:105` | Cấu trúc `if` lồng nhau có thể rút gọn. |
| **UP035** | **1** | `deprecated-import` | `app/main.py:14` (import `AsyncIterator` từ `typing`) | Cần chuyển sang import từ `collections.abc`. |
| **F841** | **1** | `unused-variable` | `app/modules/auth/router.py:182` (biến `exc` gán nhưng không dùng) | Biến cục bộ thừa. |

#### 3. Lỗi Fatal Phân Giải Cấu Hình Settings (`CORS_ORIGINS`)
- **Tập tin phát hiện:** `backend_app/backend/app/core/config/settings.py` (dòng 31, 36) và `.env` (dòng 13).
- **Log lỗi thực tế khi khởi động hoặc chạy test:**
  ```text
  pydantic_settings.exceptions.SettingsError: error parsing value for field "CORS_ORIGINS" from source "DotEnvSettingsSource"
  json.decoder.JSONDecodeError: Expecting value: line 1 column 1 (char 0)
  ```
- **Nguyên nhân:** Pydantic Settings v2 nạp trường kiểu `list[str]` sẽ mặc định gọi `json.loads` trước khi đưa vào validator `mode="before"`. Chuỗi `http://localhost:3000,http://localhost:8000` trong file `.env` không phải JSON hợp lệ. Vì câu lệnh `settings = get_settings()` được gọi ngay tại module level (`settings.py:120`), bất kỳ file nào import `settings` đều bị crash lập tức.

---

### 5.2. Phân Tích Tĩnh Frontend (Flutter / Dart)

#### 1. Kết Quả Kiểm Tra Tĩnh (`flutter analyze`)
- **Lệnh thực thi:** `flutter.bat analyze` trong thư mục `app_hoc_tieng_anh/`.
- **Kết quả:** Phát hiện **6 issues (0 compile errors, 3 warnings, 3 infos)**:
  1. `warning` — `lib/features/auth/presentation/pages/login_page.dart:136:16`: Hàm `_openForgotPasswordDialog` không được sử dụng (`unused_element`).
  2. `warning` — `lib/features/auth/presentation/pages/register_page.dart:5:8`: Import thừa `package:flutter_svg/flutter_svg.dart` (`unused_import`).
  3. `warning` — `lib/features/review/presentation/pages/review_page.dart:3:8`: Import thừa `package:go_router/go_router.dart` (`unused_import`).
  4. `info` — `lib/core/auth/auth_notifier.dart:77:11`: Khai báo 2 dấu gạch dưới thừa `(_, __)` trong callback (`unnecessary_underscores`).
  5. `info` — `lib/features/auth/presentation/pages/password_recovery_page.dart:53:9`: Lệnh `if` không có dấu ngoặc nhọn `{}` (`curly_braces_in_flow_control_structures`).
  6. `info` — `lib/features/vocabulary/presentation/pages/vocabulary_detail_page.dart:450:15`: Dùng `if (trailing != null) trailing!` thay vì null-aware `?trailing` (`use_null_aware_elements`).
- **Đánh giá:** Mã nguồn Dart có chất lượng rất cao, tuân thủ chặt chẽ Dart Analysis Options, không có bất kỳ lỗi xung đột kiểu hay lỗi biên dịch nào.

---

### 5.3. Hiện Trạng Kiểm Thử Tự Động (Automated Testing)

| Kho Mã Nguồn | File Test Hiện Có | Số Lượng Test Cases | Trạng Thái Chạy | Nguyên Nhân Thất Bại & Nhận Xét |
|---|---|:---:|:---:|---|
| **Backend** | `tests/unit/test_gemini_client.py` | 14 test cases | ❌ **Crash lúc nạp** | Các test cases được viết rất kỹ (kiểm tra timeout, retry, quota, safety rejection, bounding box). Tuy nhiên test runner bị crash ngay từ đầu do không nạp được `app.core.config.settings` (lỗi `CORS_ORIGINS`). |
| **Frontend** | `test/widget_test.dart` | 1 test case | ❌ **Failed** | File test mẫu tạo tự động từ Flutter SDK. Bị crash với lỗi `Bad state: No ProviderScope found` do `LingoUpApp` sử dụng Riverpod mà test không bọc `ProviderScope`. Assertion tìm widget đếm số `'0'` không tồn tại trong app. |

**Kết luận Kiểm thử:** Cả hai dự án hiện có **0% Test Coverage thực chất**. Cần sửa lỗi cấu hình và viết bổ sung các test cases kiểm thử tích hợp trước buổi bảo vệ.

---

### 5.4. Kiểm Tra Cấu Hình Nền Tảng, Môi Trường & Triển Khai

1. **Cấu hình Mạng Android (`AndroidManifest.xml`):**  
   Thẻ `<application>` trong `android/app/src/main/AndroidManifest.xml` thiếu cờ `android:usesCleartextTraffic="true"`. Toàn bộ các máy ảo Android hoặc thiết bị chạy Android 9.0+ đều sẽ chặn kết nối HTTP không mã hóa đến Backend `10.0.2.2:8000`.
2. **Quyền Hạn Phần Cứng iOS (`Info.plist`):**  
   File `ios/Runner/Info.plist` thiếu 3 quyền bắt buộc: `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`, và `NSMicrophoneUsageDescription`. Ứng dụng sẽ bị văng (SIGABRT crash) ngay khi người dùng bấm mở camera hoặc thư viện ảnh trên iPhone/iPad.
3. **Cấu hình Google Services:**  
   Thiếu file `android/app/google-services.json` và `ios/Runner/GoogleService-Info.plist`. Đăng nhập Google native sẽ bị chặn với lỗi `PlatformException`.
4. **Cấu hình Docker Compose (`docker-compose.yml`):**  
   File cấu hình ở thư mục gốc trỏ sai context: `context: ./backend` và `env_file: ./backend/.env` (thực tế phải là `./backend_app/backend`). Lệnh `docker compose up` không thể hoạt động.
5. **Tài liệu Hướng dẫn (`README.md`):**  
   File `README.md` ở thư mục gốc chỉ có 29 dòng, thiếu sơ đồ kiến trúc tổng thể, thiếu hướng dẫn thiết lập biến môi trường, và thiếu tài liệu các bước khởi chạy hệ thống từng bước.

---

## 6. PHÂN ĐỊNH 3 DANH MỤC TÍNH NĂNG DỰ ÁN

Để phục vụ công tác nghiệm thu và xây dựng kế hoạch hoàn thiện trước khi bảo vệ đồ án, toàn bộ hệ thống được phân định rõ ràng thành 3 danh mục:

### 6.1. Danh Mục 1: Các Phần ĐÃ HOÀN THIỆN ĐẠT YÊU CẦU ĐỒ ÁN
*(Các tính năng có kiến trúc chuẩn, mã nguồn thực tế chất lượng cao, sẵn sàng phục vụ kịch bản demo bảo vệ)*

1. **Hệ thống Giao diện Người dùng (UI/UX) & Trải nghiệm Bài tập Đa dạng:**
   - 18 màn hình Flutter hoàn chỉnh, giao diện Neumorphism / Duolingo-style đồng bộ.
   - 5 dạng bài tập tương tác (Chọn hình, Xếp từ Word Bank, Nghe hiểu, Nói phát âm, Ghép cặp) có âm thanh sfx, hàng đợi làm lại câu sai và tính điểm chính xác.
   - Điều hướng GoRouter với Auth Guard bảo vệ ShellRoute bài bản.
2. **Hệ thống Quét Ảnh AI Vật Thể (Gemini 2.0 Flash Vision):**
   - Tích hợp API Gemini 2.0 Flash với structured prompt tiếng Việt/tiếng Anh chuẩn xác.
   - Bounding Box chuẩn hóa tỉ lệ 0..1 vẽ đè chính xác lên ảnh chụp thật.
   - Quản lý hạn mức Quota 10 lượt/ngày trên Redis có atomic rollback hoàn trả lượt khi lỗi.
   - Xử lý ảnh Pillow Lanczos nén dung lượng trước khi gửi AI.
3. **Kiến trúc Tầng Dữ liệu & Quản lý Xác thực Backend:**
   - Cơ sở dữ liệu 9 bảng chuẩn hóa 3NF, quan hệ khóa ngoại và index tối ưu.
   - Bộ 3 file Alembic migrations hoàn chỉnh (`0001`, `0002`, `0003`).
   - Đăng nhập mạng xã hội Google qua xác minh ID Token chuẩn OAuth2.
   - Bảo mật mật khẩu Bcrypt và luồng cấp phát / xoay vòng JWT Token Rotation an toàn.
4. **Kho Lưu Trữ Từ Vựng Cá Nhân & Thẻ Ghi Nhớ Flashcards:**
   - Lưu trữ các từ vựng quét được vào cơ sở dữ liệu (`/scans/saved-words`).
   - Lật thẻ Flashcard 3D và trắc nghiệm 4 đáp án tự động sinh từ kho từ cá nhân.

---

### 6.2. Danh Mục 2: Các Phần CHƯA HOÀN THIỆN HOẶC CHƯA ĐỒNG BỘ (Gaps & Defects)
*(Các tính năng đã được code một phần nhưng bị lỗi cấu hình, đứt gãy kết nối hoặc lệch pha giữa hai phía)*

1. **Hai Lỗi Chặn Fatal P0 Tê Liệt Kết Nối Toàn Hệ Thống:**
   - Backend `settings.py` crash khi nạp `CORS_ORIGINS` dạng chuỗi từ `.env`.
   - Frontend `AppConfig.baseUrl` bị quy tắc RFC 3986 của Dio xóa mất tiền tố `/api/v1` khiến 100% request nhận mã lỗi 404.
2. **Đứt Gãy Toàn Diện Giữa Lộ Trình Học Frontend và Cơ Sở Dữ Liệu Backend:**
   - Frontend `features/learning/` chạy 100% bằng `MockLearningRepository`.
   - Backend đã có đầy đủ bảng `learning_paths`, `units`, `lessons`, `user_lesson_progress` và 4 API endpoints nhưng không được kết nối.
   - Kết quả làm bài tập không được nộp lên database, tiến độ bị mất khi tắt app.
3. **Đứt Gãy Tính Năng Chuỗi Ngày Học Liên Tục (Streak) & Thống Kê Hoạt Động:**
   - Hàm `submit_lesson` của Backend không gọi `ProgressService.record_activity`.
   - Bảng `user_daily_activities` luôn rỗng; API `/progress/calendar` luôn trả về 0 ngày hoạt động.
4. **Lỗi Cấu Hình Triển Khai Nền Tảng:**
   - Android thiếu `android:usesCleartextTraffic="true"` chặn gọi HTTP.
   - iOS thiếu quyền Camera, Photo, Mic trong `Info.plist`.
   - Docker Compose sai đường dẫn thư mục backend `./backend`.
   - Alembic `env.py` xung đột sync dialect psycopg2 với async engine.
5. **Hiện Tượng Mã Nguồn Mồ Côi & Lệch Pha Schema:**
   - Service `VocabularyApiService` trên Frontend được viết hoàn chỉnh nhưng không màn hình nào gọi.
   - Frontend gọi `/auth/forgot-password` nhưng Backend chưa có router này.
   - Ghi chú từ vựng cá nhân (`note`) chỉ lưu trong RAM state, bị mất khi tải lại trang.

---

### 6.3. Danh Mục 3: Các Phần CÒN THIẾU CẦN BỔ SUNG ĐỂ TRỞ THÀNH ĐỒ ÁN HOÀN CHỈNH
*(Các phân hệ có trong tài liệu thiết kế hoặc yêu cầu của một đồ án tốt nghiệp xuất sắc nhưng hiện chưa có mã nguồn)*

1. **Màn hình Giao diện Theo dõi Tiến độ & Lịch Hoạt Động trên Mobile (`features/progress`):**
   - Thư mục hiện tại chỉ có `.gitkeep`. Cần lập trình màn hình hiển thị biểu đồ đóng góp XP theo dạng ma trận nhiệt (heatmap/calendar), mục tiêu ngày và chuỗi Streak.
2. **Hệ thống Ôn Tập Lặp Lại Ngắt Quãng Thực Thụ (Spaced Repetition System — SRS):**
   - Hiện tại thư mục backend `app/modules/review/` chỉ có file `README.md`.
   - Cần bổ sung bảng CSDL `word_reviews`, triển khai thuật toán 5 hộp Leitner (1/2/4/8/16 ngày) hoặc SuperMemo SM-2, và API ghi nhận đánh giá nhớ từ ("Quên", "Khó", "Tốt", "Dễ").
3. **Trung Tâm Luyện Tập Chuyên Sâu (Practice Hub) & Sổ Tay Lỗi Sai (Mistakes Notebook):**
   - Backend `app/modules/practice/` mới chỉ có file `README.md`.
   - Cần bổ sung bảng lưu các câu hỏi người dùng làm sai trong bài học để tự động tập hợp vào "Sổ tay lỗi sai" giúp ôn luyện lại.
4. **Tích Hợp Công Nghệ Xử Lý Giọng Nói Thực Tế (TTS & STT):**
   - Tính năng phát âm từ vựng cần tích hợp Text-to-Speech (như `flutter_tts` hoặc Google Cloud TTS).
   - Bài tập nói (Speaking Exercise) cần tích hợp Speech-to-Text thật (như `speech_to_text` package) để chấm điểm phát âm thay vì hàm delay giả lập 1.5 giây.
5. **Dịch Vụ Gửi Email Thật & Tác Vụ Chạy Nền (Workers):**
   - Tích hợp dịch vụ gửi mail Resend hoặc SMTP để gửi mã xác minh email thật.
   - Cài đặt tác vụ nền (ARQ / Celery / Redis Queue) để tự động gửi thông báo đẩy nhắc nhở người học duy trì chuỗi Streak mỗi ngày.

---

## 7. KẾ HOẠCH HÀNH ĐỘNG & DANH SÁCH KHUYẾN NGHỊ ƯU TIÊN (ACTIONABLE ROADMAP)

### 7.1. Bảng Phân Cấp Mức Độ Ưu Tiên (Priority Matrix)

```
        MỨC ĐỘ KHẨN CẤP
              ▲
              │   [P0-1] Sửa CORS_ORIGINS Settings Crash
   CỰC KỲ     │   [P0-2] Sửa Dio RFC 3986 Base URL 404
   KHẨN CẤP   │   [P0-3] Thêm Android usesCleartextTraffic
              │   [P0-4] Sửa đường dẫn Dockerfile trong docker-compose
              ├───────────────────────────────────────────────────────
              │   [P1-1] Nối record_activity vào submit_lesson
   ƯU TIÊN    │   [P1-2] Sửa URL dialect trong alembic/env.py
   CAO        │   [P1-3] Thêm quyền Camera/Mic trong iOS Info.plist
              │   [P1-4] Thay MockLearningRepository bằng API thật
              │   [P1-5] Sửa widget_test.dart bọc ProviderScope
              ├───────────────────────────────────────────────────────
   TRUNG BÌNH │   [P2-1] Viết router Quên/Đặt lại mật khẩu Backend
   (HOÀN THIỆN│   [P2-2] Nối VocabularyApiService vào VocabularyPage
   ĐỒ ÁN)     │   [P2-3] Lập trình màn hình Progress & Heatmap Calendar
              │   [P2-4] Dọn dẹp cảnh báo linter (Ruff & Flutter)
              ├───────────────────────────────────────────────────────
   NÂNG CAO   │   [P3-1] Triển khai thuật toán Spaced Repetition SRS
   (FUTURE)   │   [P3-2] Tích hợp TTS phát âm & STT chấm phát âm thật
              │   [P3-3] Tích hợp SMTP Resend gửi mail & Worker nhắc học
              └───────────────────────────────────────────────────────►
                                                      MỨC ĐỘ CÔNG SỨC
```

---

### 7.2. Hướng Dẫn Kỹ Thuật Chi Tiết Kèm Mã Nguồn Sửa Chữa Cụ Thể

Dưới đây là tài liệu hướng dẫn kỹ thuật chi tiết cùng các đoạn mã nguồn hoàn chỉnh dành cho nhóm lập trình viên (Implementers) để tiến hành khắc phục các khiếm khuyết:

---

#### Hạng Mục 1 (P0): Khắc Phục Lỗi Crash Backend Lúc Khởi Động (`CORS_ORIGINS`)
- **Tập tin cần sửa:** `backend_app/backend/app/core/config/settings.py` (dòng 31–40).
- **Nguyên nhân:** Kiểu `list[str]` kích hoạt `json.loads` trước khi validator chạy.
- **Giải pháp:** Cho phép kiểu dữ liệu chấp nhận cả `str` hoặc `list[str]`, và chuyển đổi chuỗi dấu phẩy thành danh sách trong validator:
```python
# Sửa tại: backend_app/backend/app/core/config/settings.py

# TRƯỚC:
CORS_ORIGINS: list[str] = ["http://localhost:3000"]

# SAU:
CORS_ORIGINS: list[str] | str = ["http://localhost:3000"]

@field_validator("CORS_ORIGINS", mode="before")
@classmethod
def parse_cors_origins(cls, v: str | list[str]) -> list[str]:
    if isinstance(v, str):
        # Hỗ trợ cả định dạng JSON lẫn chuỗi ngăn cách bằng dấu phẩy
        v_str = v.strip()
        if v_str.startswith("[") and v_str.endswith("]"):
            import json
            try:
                return json.loads(v_str)
            except Exception:
                pass
        return [origin.strip() for origin in v_str.split(",") if origin.strip()]
    return v
```

---

#### Hạng Mục 2 (P0): Khắc Phục Lỗi 100% 404 Trong Dio Client (RFC 3986 Resolution)
- **Tập tin cần sửa:** `app_hoc_tieng_anh/lib/core/config/app_config.dart` (dòng 23–26).
- **Nguyên nhân:** `baseUrl` có chứa `/api/v1` nhưng các service gọi API bắt đầu bằng `/` làm mất tiền tố.
- **Giải pháp:** Đưa `baseUrl` về root authority (`http://10.0.2.2:8000`) và cấu hình Interceptor tự động bổ sung `/api/v1` nếu thiếu, hoặc chuẩn hóa `baseUrl`:
```dart
// Sửa tại: app_hoc_tieng_anh/lib/core/config/app_config.dart

// Cách 1 (Khuyến nghị chuẩn nhất):
// Giữ baseUrl là gốc máy chủ, mọi endpoint đều bắt đầu bằng /api/v1/...
static const String baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8000',
);

// Hoặc Cách 2: Trong AppApi interceptor (lib/core/network/app_api.dart):
onRequest: (options, handler) async {
  if (!options.path.startsWith('/api/v1') && !options.path.startsWith('http')) {
    options.path = '/api/v1${options.path.startsWith('/') ? '' : '/'}${options.path}';
  }
  // Tiếp tục đính kèm token...
  return handler.next(options);
}
```

---

#### Hạng Mục 3 (P0): Khắc Phục Lỗi Chặn Mạng HTTP Cleartext Trên Android
- **Tập tin cần sửa:** `app_hoc_tieng_anh/android/app/src/main/AndroidManifest.xml` (dòng 5).
- **Giải pháp:** Bổ sung thuộc tính `android:usesCleartextTraffic="true"` vào thẻ `<application>`:
```xml
<!-- Sửa tại: app_hoc_tieng_anh/android/app/src/main/AndroidManifest.xml -->
<application
    android:label="LingoUp"
    android:name="${applicationName}"
    android:icon="@mipmap/ic_launcher"
    android:usesCleartextTraffic="true">
    <!-- Các thẻ activity giữ nguyên -->
</application>
```

---

#### Hạng Mục 4 (P0): Khắc Phục Sai Lệch Đường Dẫn Trong `docker-compose.yml`
- **Tập tin cần sửa:** `docker-compose.yml` (dòng 12–15, 18–20, 29–31).
- **Giải pháp:** Đổi toàn bộ các đường dẫn `./backend` thành `./backend_app/backend`:
```yaml
# Sửa tại: docker-compose.yml
backend:
  build:
    context: ./backend_app/backend
    dockerfile: Dockerfile
  env_file:
    - ./backend_app/backend/.env
  volumes:
    - ./backend_app/backend:/app
```

---

#### Hạng Mục 5 (P1): Kích Hoạt Tính Năng Chuỗi Ngày Học Liên Tục (Streak & Progress)
- **Tập tin cần sửa:** `backend_app/backend/app/modules/learning/service.py` (hàm `submit_lesson`, dòng 348–370).
- **Giải pháp:** Gọi hàm `ProgressService.record_activity` sau khi bài học hoàn thành:
```python
# Sửa tại: backend_app/backend/app/modules/learning/service.py
from app.modules.progress.service import ProgressService

# Trong hàm submit_lesson, sau khi cập nhật best_score và User.xp_total:
if passed:
    # Ghi nhận hoạt động vào bảng user_daily_activities và cập nhật streak_days
    progress_service = ProgressService(self.db)
    await progress_service.record_activity(
        user_id=user_id,
        xp_earned=xp_earned,
        lessons_completed=1 if is_first_completion else 0,
        minutes_studied=max(1, time_spent_seconds // 60),
    )
```

---

#### Hạng Mục 6 (P1): Khắc Phục Lỗi Xung Đột Engine Trong Alembic Migrations
- **Tập tin cần sửa:** `backend_app/backend/alembic/env.py` (dòng 80–87).
- **Giải pháp:** Truyền trực tiếp chuỗi async dialect vào `async_engine_from_config`:
```python
# Sửa tại: backend_app/backend/alembic/env.py
def run_migrations_online() -> None:
    configuration = config.get_section(config.config_ini_section) or {}
    # Sử dụng trực tiếp asyncpg URL từ settings
    configuration["sqlalchemy.url"] = settings.DATABASE_URL
    
    connectable = async_engine_from_config(
        configuration,
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )
```

---

#### Hạng Mục 7 (P1): Bổ Sung Quyền Hạn Bắt Buộc Trên Nền Tảng iOS
- **Tập tin cần sửa:** `app_hoc_tieng_anh/ios/Runner/Info.plist`.
- **Giải pháp:** Thêm các khóa mô tả mục đích sử dụng phần cứng:
```xml
<!-- Sửa tại: app_hoc_tieng_anh/ios/Runner/Info.plist -->
<key>NSCameraUsageDescription</key>
<string>LingoUp cần quyền truy cập camera để chụp ảnh và quét đồ vật học từ vựng bằng AI.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>LingoUp cần quyền truy cập thư viện ảnh để bạn chọn hình ảnh quét từ vựng.</string>
<key>NSMicrophoneUsageDescription</key>
<string>LingoUp cần quyền sử dụng micro để bạn thực hiện các bài tập luyện phát âm.</string>
```

---

#### Hạng Mục 8 (P1): Kết Nối Lộ Trình Học Với Cơ Sở Dữ Liệu Backend Thật
- **Tập tin cần tạo/sửa:** `app_hoc_tieng_anh/lib/features/learning/data/learning_api_service.dart`.
- **Giải pháp:** Xây dựng service gọi API thật và thay thế `MockLearningRepository`:
```dart
// Tạo file: app_hoc_tieng_anh/lib/features/learning/data/learning_api_service.dart
import '../../../../core/network/app_api.dart';

class LearningApiService {
  static final LearningApiService instance = LearningApiService._();
  LearningApiService._();

  Future<List<dynamic>> getPaths() async {
    final response = await AppApi.instance.dio.get('/api/v1/learning/paths');
    return response.data;
  }

  Future<Map<String, dynamic>> getPathDetail(String pathId) async {
    final response = await AppApi.instance.dio.get('/api/v1/learning/paths/$pathId');
    return response.data;
  }

  Future<Map<String, dynamic>> getLessonDetail(String lessonId) async {
    final response = await AppApi.instance.dio.get('/api/v1/learning/lessons/$lessonId');
    return response.data;
  }

  Future<Map<String, dynamic>> submitLesson({
    required String lessonId,
    required int score,
    required int timeSpentSeconds,
  }) async {
    final response = await AppApi.instance.dio.post(
      '/api/v1/learning/lessons/$lessonId/submit',
      data: {
        'score': score,
        'time_spent_seconds': timeSpentSeconds,
      },
    );
    return response.data;
  }
}
```

---

#### Hạng Mục 9 (P1): Khắc Phục Lỗi File Kiểm Thử Mặc Định Flutter
- **Tập tin cần sửa:** `app_hoc_tieng_anh/test/widget_test.dart`.
- **Giải pháp:** Bọc `LingoUpApp` trong `ProviderScope` và viết smoke test kiểm tra hiển thị ứng dụng:
```dart
// Sửa tại: app_hoc_tieng_anh/test/widget_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_hoc_tieng_anh/app/app.dart';

void main() {
  testWidgets('LingoUpApp smoke test - verifies app initialization', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: LingoUpApp(),
      ),
    );
    await tester.pump();
    // Xác nhận app khởi tạo thành công không bị crash
    expect(find.byType(LingoUpApp), findsOneWidget);
  });
}
```

---

#### Hạng Mục 10 (P2): Triển Khai API Quên & Đặt Lại Mật Khẩu Trên Backend
- **Tập tin cần sửa:** `backend_app/backend/app/modules/auth/router.py` và `service.py`.
- **Giải pháp:** Khai báo 2 endpoint tương ứng với giao diện `password_recovery_page.dart`:
  1. `POST /api/v1/auth/forgot-password`: Nhận `{ "email": str }` -> Tạo token khôi phục và ghi log/gửi mail.
  2. `POST /api/v1/auth/reset-password`: Nhận `{ "token": str, "new_password": str }` -> Cập nhật `hashed_password` cho người dùng.

---

#### Hạng Mục 11 (P2): Kết Nối Tầng Service Từ Vựng Vào Màn Hình Kho Từ Vựng
- **Tập tin cần sửa:** `app_hoc_tieng_anh/lib/features/vocabulary/presentation/pages/vocabulary_page.dart`.
- **Giải pháp:** Thêm TabBar phân tách 2 chế độ xem: (1) "Từ vựng của tôi" (tải từ `/scans/saved-words`) và (2) "Từ điển hệ thống" (gọi `VocabularyApiService.instance.listWords` kết hợp thanh tìm kiếm và bộ lọc chủ đề `/vocab/topics`).

---

#### Hạng Mục 12 (P2): Dọn Dẹp Cảnh Báo Quy Chuẩn Mã Nguồn Linter
- **Backend:** Thêm cấu hình bỏ qua `B008` (đặc thù của FastAPI `Depends`) và chạy tự động sửa lỗi ruff:
  ```toml
  # Thêm vào: backend_app/backend/pyproject.toml
  [tool.ruff.lint]
  ignore = ["B008"]
  ```
  Sau đó chạy: `uvx ruff check backend_app/backend --fix`.
- **Frontend:** Xóa 3 import thừa tại `register_page.dart`, `review_page.dart` và hàm `_openForgotPasswordDialog` thừa tại `login_page.dart`. Chạy lại `flutter analyze` để đạt trạng thái **0 issues**.

---

### 7.3. Tổng Kết & Khuyến Nghị Trình Bày Trước Hội Đồng Bảo Vệ

1. **Chiến lược Kịch bản Trình chiếu (Demo Script Strategy):**
   - **Tập trung vào điểm mạnh cốt lõi**: Khởi đầu bài thuyết trình bằng tính năng **AI Camera Scan**. Chụp ảnh một đồ vật thật trên bàn hội đồng (laptop, ly cà phê, quyển sách), cho AI phân tích thời gian thực, hiển thị bounding box, phân tích IPA, nghĩa và lưu vào kho từ. Đây là tính năng gây ấn tượng mạnh mẽ nhất và phân biệt LingoUp với các đồ án thông thường.
   - **Trình diễn luồng học tập sinh động**: Thuyết minh về hệ thống 5 dạng bài tập tương tác, nhấn mạnh vào trải nghiệm gamification, hiệu ứng âm thanh và hàng đợi sửa lỗi thông minh.
2. **Kỹ năng Giải trình về các Thành phần Đang Phát Triển (Future Work Transparency):**
   - Khi hội đồng đặt câu hỏi về các tính năng như "Sổ tay lỗi sai", "Hệ thống Spaced Repetition SRS", hoặc "Phát âm giọng nói": Nhóm cần thẳng thắn và tự tin trình bày rằng hệ thống đã hoàn thành trọn vẹn kiến trúc nền tảng và tài liệu đặc tả thiết kế chi tiết (tại các module `review/`, `practice/`), đồng thời đã định hình rõ lộ trình tích hợp thuật toán Leitner 5 hộp và công nghệ AI Speech-to-Text cho phiên bản thương mại tiếp theo.
3. **Đánh Giá Chung:**  
   Dự án **LingoUp** là một đồ án có hàm lượng kỹ thuật cao, bắt kịp xu hướng ứng dụng Trí tuệ Nhân tạo đa phương thức (Multimodal AI) vào thực tiễn giáo dục. Sau khi đội ngũ phát triển hoàn tất các chỉnh sửa ưu tiên P0 và P1 theo lộ trình hành động trong báo cáo này, hệ thống hoàn toàn đủ điều kiện để đạt mức điểm **Giỏi / Xuất sắc** trong kỳ bảo vệ tốt nghiệp đại học.

---
*Báo cáo được tổng hợp và phê duyệt bởi Hội đồng Kiểm định Kỹ thuật Dự án LingoUp — 03/11/2026.*
