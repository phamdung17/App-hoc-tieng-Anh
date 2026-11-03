# Báo Cáo Phân Tích Tĩnh & Kiểm Định Chất Lượng Dự Án (Static Audit & Quality Report)

**Dự án:** Ứng dụng Học Tiếng Anh + AI (LingoUp) — Fullstack Flutter & FastAPI  
**Thời điểm thực hiện:** 03/11/2026  
**Người thực hiện:** Teamwork Explorer — Static Analysis & Verification Agent  
**Nguyên tắc thực thi:** Phân tích tĩnh, rà soát mã nguồn & tài liệu đối chiếu thực tế (Read-Only, không can thiệp mã nguồn dự án).  

---

## 1. Tóm Tắt Tổng Quan (Executive Summary)

Dự án đã có cấu trúc thư mục rõ ràng theo hướng phân tầng Clean Architecture (Feature-First) ở cả Frontend Flutter (`app_hoc_tieng_anh/`) và Backend FastAPI (`backend_app/backend/`). Tuy nhiên, qua quá trình kiểm tra tĩnh toàn diện, chạy công cụ phân tích cú pháp, linter, test runner và đối chiếu môi trường, đã phát hiện **2 lỗi chặn nghiêm trọng (Fatal Bugs)** có thể làm tê liệt toàn bộ hệ thống lúc khởi chạy, cùng nhiều khoảng cách (gaps) giữa mã nguồn thực tế và đặc tả đồ án:

1. **Fatal Startup Bug (Backend):** Pydantic Settings v2 tại `app/core/config/settings.py` gặp lỗi phân giải kiểu dữ liệu `CORS_ORIGINS` khi nạp từ `.env`, khiến backend bị crash ngay lập tức ở cấp độ nạp module (`json.decoder.JSONDecodeError` / `SettingsError`).
2. **Fatal Integration Bug (Frontend - Backend Networking):** Cấu hình `AppConfig.baseUrl` có chứa đường dẫn con (`/api/v1`), nhưng toàn bộ các service Dio ở Frontend gọi API bằng đường dẫn bắt đầu bằng dấu gạch chéo `/` (ví dụ `dio.post('/auth/login')`). Theo tiêu chuẩn RFC 3986 của Dio, đường dẫn gốc bị xóa bỏ và yêu cầu được gửi tới `/auth/login` thay vì `/api/v1/auth/login`, dẫn tới **100% API calls bị lỗi HTTP 404 Not Found**.
3. **Lệch pha dữ liệu học tập (Learning Module Gap):** Backend đã triển khai đầy đủ các endpoint `/learning/paths`, `/learning/lessons/{id}` và cơ sở dữ liệu migration `0002_learning_tables`, nhưng Frontend hoàn toàn không gọi các endpoint này mà chạy 100% bằng dữ liệu giả (`MockLearningRepository`).
4. **Kiểm thử tự động (Automated Testing Gap):** Backend chỉ có 1 file test mock cho Gemini (`test_gemini_client.py`), chưa chạy được do lỗi nạp `.env`. Frontend chỉ có 1 file test mặc định từ Flutter template (`widget_test.dart`) và đang bị fail với lỗi thiếu `ProviderScope` và sai assertion.

---

## 2. Kết Quả Kiểm Định Backend (FastAPI)

### 2.1. Cú pháp & Môi trường thực thi
- **Môi trường nhận diện:** Python 3.15.2 (quản lý qua `uv 0.13.6` tại `C:\Users\dungl\.local\bin\uv.exe`).
- **Kiểm tra biên dịch toàn bộ mã nguồn (`compileall`):**
  - Lệnh: `python -m compileall -q backend_app/backend`
  - Kết quả: **Đạt (0 lỗi cú pháp)**. Toàn bộ mã nguồn Python biên dịch hợp lệ về mặt bytecode.

### 2.2. Kết quả kiểm tra Linter (`ruff check`)
Chạy công cụ phân tích tĩnh `ruff` trên toàn bộ thư mục `backend_app/backend/` phát hiện **142 cảnh báo/lỗi quy chuẩn mã nguồn**, trong đó có 87 lỗi có thể tự động sửa (`--fix`). Phân bổ chi tiết:

| Mã lỗi | Số lượng | Mô tả & Nguyên nhân | Mức độ nghiêm trọng |
|---|---|---|---|
| **B008** | 52 | `function-call-in-default-argument`: Gọi hàm `Depends()`, `Query()`, `Path()` trong giá trị mặc định của router FastAPI. | Thấp (Quy chuẩn code FastAPI, cần cấu hình bỏ qua B008 trong `pyproject.toml`). |
| **UP037** | 19 | `quoted-annotation`: Sử dụng type annotation dạng chuỗi (ví dụ `"Settings"`) không cần thiết trong Python 3.11+. | Thấp (Code style). |
| **I001** | 16 | `unsorted-imports`: Khối import chưa được sắp xếp theo chuẩn PEP 8. | Thấp (Code style). |
| **UP017** | 15 | `datetime-timezone-utc`: Sử dụng `timezone.utc` thay cho cú pháp chuẩn mới `datetime.UTC`. | Thấp (Code style). |
| **F401** | 13 | `unused-import`: Import thư viện nhưng không sử dụng. Điển hình: `uuid` trong migration 0001, `math` trong `vocab/service.py`, `AnyHttpUrl` trong `settings.py`, `MagicMock` & `typing.Any` trong unit test. | Trung bình (Dư thừa tài nguyên). |
| **UP045** | 12 | `non-pep604-annotation-optional`: Dùng `Optional[T]` thay vì `T \| None` chuẩn PEP 604. | Thấp (Code style). |
| **PIE790** | 5 | `unnecessary-placeholder`: Dùng lệnh `pass` thừa thãi khi hàm đã có docstring. | Thấp (Code style). |
| **RUF100** | 4 | `unused-noqa`: Đánh dấu `# noqa` không cần thiết. | Thấp (Code style). |
| **RUF022** | 2 | `unsorted-dunder-all`: Biến `__all__` chưa sắp xếp theo thứ tự chữ cái. | Thấp (Code style). |
| **BLE001** | 1 | `blind-except`: Bắt ngoại lệ chung `except Exception:` tại `app/integrations/gemini/client.py:244` trong hàm `_safe_log_payload`. | Trung bình (Cần hẹp ngoại lệ hoặc ghi log chi tiết). |
| **SIM102** | 1 | `collapsible-if`: Lệnh `if` lồng nhau không cần thiết tại `app/core/config/settings.py:105`. | Thấp (Code style). |
| **UP035** | 1 | `deprecated-import`: Import `AsyncIterator` từ `typing` thay vì `collections.abc` tại `app/main.py:14`. | Thấp (Code style). |
| **F841** | 1 | `unused-variable`: Biến cục bộ `exc` gán nhưng không dùng tại `app/modules/auth/router.py:182`. | Thấp (Code style). |

### 2.3. Lỗi Fatal: Crash khi nạp cấu hình `.env` (`CORS_ORIGINS`)
- **Tập tin phát hiện:** `backend_app/backend/app/core/config/settings.py` (dòng 31 & 36) và `.env` (dòng 13).
- **Hiện tượng:**
  Trong `settings.py`:
  ```python
  CORS_ORIGINS: list[str] = ["http://localhost:3000"]
  @field_validator("CORS_ORIGINS", mode="before")
  @classmethod
  def parse_cors_origins(cls, v: str | list[str]) -> list[str]:
      if isinstance(v, str):
          return [origin.strip() for origin in v.split(",") if origin.strip()]
      return v
  ```
  Trong `.env` và `.env.example`:
  ```env
  CORS_ORIGINS=http://localhost:3000,http://localhost:8000
  ```
- **Nguyên nhân cốt lõi:**
  Trong Pydantic Settings v2, khi trường khai báo kiểu `list[str]`, bộ phân giải `DotEnvSettingsSource` sẽ tự động thực hiện `json.loads(value)` trước khi chuyển giao cho `@field_validator(mode="before")`. Chuỗi `http://localhost:3000,...` không phải định dạng JSON hợp lệ, sinh ngoại lệ:
  `json.decoder.JSONDecodeError: Expecting value: line 1 column 1 (char 0)`
  dẫn tới `pydantic_settings.exceptions.SettingsError: error parsing value for field "CORS_ORIGINS" from source "DotEnvSettingsSource"`.
- **Hậu quả:** Bất kỳ file nào import `from app.core.config import settings` (bao gồm `main.py`, router, migration và tests) đều bị crash ngay khi khởi động.

### 2.4. Đánh giá Database Migration (Alembic)
- **Chuỗi migration hiện tại:**
  `0001_initial_schema` (khởi tạo `users`, `words`, `scans`, `scan_items`)  
  ⬇️  
  `0002_learning_tables` (khởi tạo `learning_paths`, `units`, `lessons`, `user_lesson_progress`)  
  ⬇️  
  `0003_progress_tables` (khởi tạo `user_daily_activities`)
- **Đánh giá:**
  - Chuỗi migration liên tục, định danh `revision` và `down_revision` chính xác.
  - Các bảng và kiểu cột đồng bộ với các SQLAlchemy model trong `app/core/models/`.
  - **Lưu ý triển khai:** Migration 0001 sử dụng lệnh `CREATE EXTENSION IF NOT EXISTS pgcrypto`, yêu cầu quyền superuser hoặc database owner trên PostgreSQL.

### 2.5. Hiện trạng Unit Tests Backend
- Toàn bộ thư mục `tests/` chỉ chứa 1 file test: `tests/unit/test_gemini_client.py` (349 dòng mã, 15 kịch bản test sử dụng mock `httpx`).
- Chưa có unit test hoặc integration test cho: `auth`, `users`, `vocab`, `learning`, `progress`, `storage`.
- Test suite hiện tại không thể chạy độc lập do phụ thuộc vào module settings bị lỗi `CORS_ORIGINS` nêu trên.

---

## 3. Kết Quả Kiểm Định Frontend (Flutter)

### 3.1. Cú pháp & Môi trường thực thi
- **Môi trường nhận diện:** Flutter 3.47.5 (channel stable), Dart SDK 3.13.4.
- **Kết quả kiểm tra tĩnh (`flutter analyze`):**
  - **Tổng số vấn đề:** 6 issues (0 lỗi compile/type, 3 warnings, 3 infos).
  - Chi tiết 6 vấn đề:
    1. `warning` - `lib/features/auth/presentation/pages/login_page.dart:136:16`: Hàm `_openForgotPasswordDialog` được khai báo nhưng không còn được sử dụng (`unused_element`).
    2. `warning` - `lib/features/auth/presentation/pages/register_page.dart:5:8`: Import thừa `package:flutter_svg/flutter_svg.dart` (`unused_import`).
    3. `warning` - `lib/features/review/presentation/pages/review_page.dart:3:8`: Import thừa `package:go_router/go_router.dart` (`unused_import`).
    4. `info` - `lib/core/auth/auth_notifier.dart:77:11`: Khai báo 2 dấu gạch dưới `(_, __)` thừa trong callback Dart 3 (`unnecessary_underscores`).
    5. `info` - `lib/features/auth/presentation/pages/password_recovery_page.dart:53:9`: Lệnh `if` không có dấu ngoặc nhọn bao quanh (`curly_braces_in_flow_control_structures`).
    6. `info` - `lib/features/vocabulary/presentation/pages/vocabulary_detail_page.dart:450:15`: Sử dụng `if (trailing != null) trailing!` thay vì null-aware element `?trailing` (`use_null_aware_elements`).
  - **Nhận xét chất lượng:** Mã nguồn Dart có cấu trúc chặt chẽ, sạch sẽ, không có lỗi kiểu dữ liệu nghiêm trọng.

### 3.2. Hiện trạng Unit & Widget Test Frontend
- Chạy lệnh `flutter test`: **Thất bại (Failed)**.
- **Tập tin duy nhất:** `test/widget_test.dart` (mã boilerplate tạo ra từ `flutter create`, được sửa import sang `LingoUpApp()`).
- **Nguyên nhân thất bại:**
  1. `Bad state: No ProviderScope found`: `LingoUpApp` là widget dùng Riverpod, khi test độc lập bằng `tester.pumpWidget(const LingoUpApp())` bắt buộc phải được bọc trong `ProviderScope(child: LingoUpApp())`.
  2. `TestFailure: Expected: exactly one matching candidate with text '0'`: Ứng dụng thực tế không có widget bộ đếm đính kèm `Icons.add`.
- **Kết luận:** Dự án hoàn toàn **chưa có bất kỳ unit test hoặc widget test thực chất nào** cho các màn hình nghiệp vụ (Auth, Scan, Vocab, Learning, Profile).

### 3.3. Lỗi Fatal: Xung đột URL Base và Đường Dẫn Tương Đối trong Dio
- **Tập tin phát hiện:** `app_hoc_tieng_anh/lib/core/config/app_config.dart` (dòng 24) và toàn bộ các file gọi API (`app_api.dart`, `login_page.dart`, `register_page.dart`, `scan_api_service.dart`, `vocabulary_api_service.dart`, `profile_page.dart`, `review_page.dart`).
- **Hiện tượng:**
  Trong `app_config.dart`:
  ```dart
  static const String baseUrl = 'http://10.0.2.2:8000/api/v1';
  ```
  Trong các service và controller:
  ```dart
  dio.post('/auth/login', ...)
  dio.get('/scans/quota')
  dio.get('/vocab')
  dio.get('/auth/me')
  ```
- **Nguyên nhân cốt lõi:**
  Theo chuẩn URL resolution (RFC 3986) mà thư viện `Dio` tuân thủ, khi `baseUrl` chứa đường dẫn phụ (`/api/v1`) nhưng tham số truyền vào hàm request bắt đầu bằng dấu gạch chéo `/`, Dio sẽ giải quyết đường dẫn tương đối so với **root authority** (bỏ qua toàn bộ đường dẫn phụ `/api/v1`):
  `http://10.0.2.2:8000/api/v1` + `'/auth/login'` ➡️ `http://10.0.2.2:8000/auth/login`.
  Trong khi đó, Backend FastAPI đăng ký router với tiền tố `settings.API_V1_PREFIX = "/api/v1"`:
  `app.include_router(auth_router, prefix="/api/v1")` ➡️ Route thực tế là `http://localhost:8000/api/v1/auth/login`.
- **Hậu quả:** Mọi request từ Frontend tới Backend đều nhận mã lỗi **HTTP 404 Not Found**.

---

## 4. Ma Trận Đối Chiếu Tương Thích API Frontend - Backend

| Module | Nghiệp vụ | Backend Endpoint | Frontend Service / Screen | Trạng thái đồng bộ | Ghi chú & Sai lệch phát hiện |
|---|---|---|---|---|---|
| **Auth** | Đăng ký | `POST /api/v1/auth/register` | `RegisterPage._submit` | ⚠️ Bị 404 do URL; Schema khớp | Backend trả `AuthResponse` {tokens, user}; FE nhận `tokens`. |
| **Auth** | Đăng nhập | `POST /api/v1/auth/login` | `LoginPage._submit` | ⚠️ Bị 404 do URL; Schema khớp | Backend trả `AuthResponse`; FE lưu vào SecureStorage. |
| **Auth** | Làm mới token | `POST /api/v1/auth/refresh` | `AppApi` (QueuedInterceptor) | ⚠️ Bị 404 do URL | Tự động làm mới khi gặp 401. |
| **Auth** | Xác minh email | `POST /api/v1/auth/verify-email` | `EmailVerificationPage` | ⚠️ Bị 404 do URL; Schema khớp | Nhận token qua query param hoặc deep link. |
| **Auth** | Gửi lại email | `POST /api/v1/auth/resend-verification` | `EmailVerificationPage` | ⚠️ Bị 404 do URL; Schema khớp | Gửi lại mã kích hoạt tài khoản. |
| **Auth** | Google Social | `POST /api/v1/auth/social/google` | `GoogleAuthService.signIn` | ⚠️ Bị 404 do URL; Schema khớp | FE gửi `id_token`, BE xác minh trả tokens. |
| **Auth** | Quên / Đặt lại MK | ❌ Chưa triển khai ở Backend | `PasswordRecoveryPage` | ❌ Lệch hoàn toàn (Missing BE) | FE có trang `password_recovery_page.dart` nhưng BE chưa có router. |
| **Scan** | Lấy Quota ngày | `GET /api/v1/scans/quota` | `ScanApiService.getQuota` | ⚠️ Bị 404 do URL; Schema khớp | BE trả `{used, limit, remaining, reset_at}`. FE parse đúng. |
| **Scan** | Upload scan ảnh | `POST /api/v1/scans` | `ScanApiService.scanImage` | ⚠️ Bị 404 do URL; Schema khớp | Multipart form-data `image`. BE trả presigned URL + items. |
| **Scan** | Lưu từ scan | `PATCH /api/v1/scans/items/{id}/saved` | `ScanApiService.setSaved` | ⚠️ Bị 404 do URL; Schema khớp | BE cập nhật `is_saved = True/False`. |
| **Scan** | Từ đã lưu | `GET /api/v1/scans/saved-words` | `ScanApiService.getSavedWords` | ⚠️ Bị 404 do URL; Schema khớp | Dùng chung cho Kho từ và Flashcards. |
| **Vocab** | Danh sách từ | `GET /api/v1/vocab` | `VocabularyApiService.listWords` | ⚠️ Chưa nối UI | Service FE đã viết nhưng `VocabularyPage` lại gọi `/scans/saved-words`. |
| **Vocab** | Chủ đề từ vựng | `GET /api/v1/vocab/topics` | `VocabularyApiService.listTopics` | ⚠️ Chưa nối UI | Service FE có hàm nhưng chưa gắn vào filter của trang từ vựng. |
| **Vocab** | Chi tiết từ | `GET /api/v1/vocab/{id}` | `VocabularyApiService.getById` | ⚠️ Chưa nối UI | `VocabularyDetailPage` tự tìm trong danh sách scan saved words. |
| **Learning** | Lộ trình học | `GET /api/v1/learning/paths` | ❌ `MockLearningRepository` | ❌ Chưa nối BE (Dùng mock 100%) | BE có sẵn endpoint & DB nhưng FE dùng mock JSON cứng. |
| **Learning** | Chi tiết bài học | `GET /api/v1/learning/lessons/{id}` | ❌ `MockLearningRepository` | ❌ Chưa nối BE (Dùng mock 100%) | 5 dạng bài tập ở FE đều lấy dữ liệu từ mock data. |
| **Learning** | Nộp kết quả bài | `POST /api/v1/learning/lessons/{id}/submit` | ❌ `MockLearningRepository` | ❌ Chưa nối BE (Dùng mock 100%) | Nộp XP, điểm bài học chưa được đồng bộ về DB Postgres. |
| **Progress** | Tóm tắt tiến trình | `GET /api/v1/progress/summary` | ❌ Chưa có UI / Service | ❌ Chưa triển khai FE | BE có endpoint tính XP, streak, mục tiêu ngày; FE thiếu màn hình. |
| **Progress** | Lịch học ngày | `GET /api/v1/progress/calendar` | ❌ Chưa có UI / Service | ❌ Chưa triển khai FE | BE có endpoint calendar streak; FE thư mục `features/progress` trống trơn. |
| **Users** | Profile người dùng | `GET /api/v1/users/me` hoặc `/auth/me` | `ProfilePage._loadProfile` | ⚠️ Bị 404 do URL; Schema khớp | Đọc display_name, email, streak, xp_total. |
| **Users** | Đăng ký FCM token | `POST /api/v1/users/me/fcm-token` | ❌ Chưa gọi từ FE | ❌ Chưa nối FE | Backend có sẵn nhưng FE dùng `flutter_local_notifications` cục bộ. |

---

## 5. Rà Soát Tài Liệu & Cấu Hình Triển Khai

### 5.1. File `docker-compose.yml` (Thư mục gốc)
- **Lỗi sai lệch đường dẫn:**
  File `docker-compose.yml` ở thư mục gốc khai báo:
  ```yaml
  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    env_file:
      - ./backend/.env
    volumes:
      - ./backend:/app
  ```
  Nhưng trên thực tế thư mục backend trong repo là `backend_app/backend/`. Khi chạy lệnh `docker compose up` từ thư mục gốc dự án, Docker báo lỗi ngay vì không tìm thấy đường dẫn `./backend`.

### 5.2. File `project_review.md` và `weekly_implementation_plan.md`
- `project_review.md` (viết ngày 27/10/2026): Đã ghi nhận chính xác lỗi đường dẫn của `docker-compose.yml` và việc thiếu migration. Đến nay (03/11/2026), nhóm phát triển đã bổ sung 3 file migration (`0001`, `0002`, `0003`) nhưng **chưa sửa file `docker-compose.yml`**.
- `weekly_implementation_plan.md`: Đặt mục tiêu thay thế YOLO-World bằng Gemini API và tạo khung Flutter. Tiến độ backend Gemini đã hoàn thành, nhưng phần kết nối giữa Flutter và Backend bị đình trệ.

### 5.3. Log Build Android (`android_build.log`)
- Log ghi nhận một lần chạy `./gradlew assembleDebug` thất bại:
  `Execution failed for task ':image_picker_android:compileDebugKotlin'`.
  Nguyên nhân: Daemon Kotlin của Gradle trên Windows bị lỗi khóa file bộ đệm gia tăng (`Could not close incremental caches`). Đây là vấn đề phổ biến trên Windows, có thể khắc phục bằng cách chạy `./gradlew --stop` và xóa thư mục `build/`.

---

## 6. Đánh Giá Theo Tiêu Chuẩn Đồ Án Môn Học / Tốt Nghiệp

| Tiêu chuẩn đánh giá | Đánh giá hiện tại | Chi tiết hiện trạng |
|---|---|---|
| **Tính khả thi Demo (Demo Readiness)** | **3.5 / 5.0 (Cần khắc phục khẩn cấp)** | Giao diện Flutter thiết kế đẹp, mượt mà, đầy đủ hiệu ứng âm thanh/animation cho 5 dạng bài tập và camera scan. Tuy nhiên, nếu cắm Backend thật vào sẽ bị lỗi 404 toàn diện do URL bug và crash do .env bug. Hiện tại chỉ demo được trên dữ liệu Mock. |
| **Độ hoàn thiện Backend (Backend Completion)** | **4.0 / 5.0** | Viết bằng FastAPI rất chuẩn mực: Pydantic v2, async SQLAlchemy 2.0, Alembic đầy đủ, Redis quota, Gemini client có retry logic và error handling. Khuyết thiếu: Quên/đặt lại mật khẩu chưa có router, module `practice/review/notifications` còn là skeleton rỗng. |
| **Độ hoàn thiện Frontend (Frontend Completion)** | **3.8 / 5.0** | Kiến trúc Riverpod + GoRouter bài bản. UI bài học và camera hoàn chỉnh. Khuyết thiếu: Module `progress` rỗng, chưa nối API cho Learning (dùng mock 100%), speaking/listening chưa có TTS/STT thật (dùng delay giả lập). |
| **Độ tin cậy & Kiểm thử (Testing & QA)** | **1.0 / 5.0 (Kém)** | Backend chỉ có 1 file test gemini và đang bị crash; Frontend chỉ có 1 file test template và đang fail. Không có integration test hay end-to-end test nào hoạt động được. |
| **Tính nhất quán cấu hình (DevOps & CI/CD)** | **2.5 / 5.0** | Cấu hình Docker Compose sai path, thiếu script tự động hóa khởi chạy database/migration. |

---

## 7. Đề Xuất Các Hạng Mục Ưu Tiên Cần Sửa Chữa (Actionable Proposals)

*Lưu ý: Báo cáo tuân thủ nguyên tắc không can thiệp mã nguồn. Dưới đây là các giải pháp cụ thể gửi nhóm phát triển/implementer:*

### Ưu tiên 1 (P0 - Sửa ngay để hệ thống chạy được):
1. **Sửa lỗi `CORS_ORIGINS` trong `backend_app/backend/app/core/config/settings.py`:**
   Đổi kiểu khai báo:
   ```python
   # Trước
   CORS_ORIGINS: list[str] = ["http://localhost:3000"]
   # Sau
   CORS_ORIGINS: list[str] | str = ["http://localhost:3000"]
   ```
   Hoặc cập nhật `.env`:
   ```env
   CORS_ORIGINS=["http://localhost:3000","http://localhost:8000"]
   ```
2. **Sửa lỗi Dio URL Resolution trong `app_hoc_tieng_anh/lib/core/config/app_config.dart`:**
   Bỏ `/api/v1` khỏi `baseUrl`:
   ```dart
   // Trước
   static const String baseUrl = 'http://10.0.2.2:8000/api/v1';
   // Sau
   static const String baseUrl = 'http://10.0.2.2:8000';
   ```
   (Và điều chỉnh tiền tố các endpoint thành `/api/v1/...` hoặc cấu hình Interceptor gắn prefix).
3. **Sửa đường dẫn trong `docker-compose.yml`:**
   Đổi `./backend` thành `./backend_app/backend` tại các mục `context`, `env_file`, `volumes`.

### Ưu tiên 2 (P1 - Nối nghiệp vụ cốt lõi để bảo vệ đồ án):
1. **Kết nối `LearningPathPage` và `LessonPage` với API Backend:**
   Viết `LearningApiService` để gọi `GET /api/v1/learning/paths` và `POST /api/v1/learning/lessons/{id}/submit` thay vì dùng dữ liệu cứng trong `MockLearningRepository`.
2. **Kết nối `VocabularyPage` với `VocabularyApiService`:**
   Hiển thị danh mục từ vựng học tập song song với từ vựng lưu từ scan camera.
3. **Sửa `test/widget_test.dart` của Flutter:**
   Bọc `ProviderScope` và viết test case kiểm tra hiển thị `LingoUpApp` hoặc các widget con đơn lẻ.

### Ưu tiên 3 (P2 - Tối ưu hóa & Làm sạch đồ án):
1. Thêm router `POST /auth/forgot-password` và `POST /auth/reset-password` ở Backend.
2. Dọn dẹp 6 cảnh báo của `flutter analyze` và 142 cảnh báo của `ruff` (thêm `ignore = ["B008"]` vào `pyproject.toml`).
3. Bổ sung màn hình theo dõi tiến trình học tập (`features/progress`) hiển thị streak và calendar hoạt động.
