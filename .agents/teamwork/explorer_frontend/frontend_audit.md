# BÁO CÁO KIỂM TRA & ĐÁNH GIÁ TOÀN DIỆN FRONTEND FLUTTER
**Dự án**: Ứng dụng Học Tiếng Anh Thông Minh Tích Hợp AI (LingoUp)  
**Mã nguồn Frontend**: `app_hoc_tieng_anh/`  
**Tiêu chuẩn đánh giá**: Đồ án tốt nghiệp / Đồ án chuyên ngành Công nghệ Thông tin & Lập trình Di động  
**Ngày thực hiện kiểm tra**: 2026-11-03  
**Chế độ thực hiện**: Read-only Audit (Không can thiệp sửa đổi mã nguồn)

---

## 1. TỔNG QUAN & BẢNG ĐIỂM TIẾN ĐỘ (EXECUTIVE SUMMARY)

Ứng dụng Flutter (`app_hoc_tieng_anh`) được xây dựng với cấu trúc thư mục phân tách theo tính năng (`features/`), áp dụng `go_router` (v14.2.7) cho điều hướng điều kiện (auth guard), `flutter_riverpod` (v2.5.1) cho trạng thái xác thực toàn cục, `dio` (v5.7.0) cho tầng mạng, và `flutter_secure_storage` (v9.2.2) để lưu trữ JWT tokens.

Giao diện người dùng (UI) được thiết kế đồng bộ với hệ thống Design System Neumorphism / Duolingo-style (`AppTheme`, `AppColors`, `AppRadii`), hỗ trợ âm thanh tương tác (`audioplayers`), thông báo nhắc nhở học tập cục bộ (`flutter_local_notifications` + `timezone`), và hệ thống 5 loại bài tập tương tác hoàn chỉnh.

Tuy nhiên, **mức độ kết nối thực tế với Backend FastAPI (`backend_app/backend/`) bị phân hóa mạnh**:
- **Nhóm tính năng đã kết nối API thật**: Xác thực Auth (Login, Register, Social Google, Verify Email, Resend Verify), Quét ảnh AI Gemini (`/scans`, `/scans/quota`), Lưu từ vào kho cá nhân (`/scans/items/{id}/saved`, `/scans/saved-words`), Ôn tập Flashcards (`/scans/saved-words`), và Hồ sơ cá nhân (`/auth/me`).
- **Nhóm tính năng chạy hoàn toàn bằng Mock / Dữ liệu tĩnh**: Toàn bộ Lộ trình học & Bài tập (`features/learning/` không gọi API backend `/learning/*`), Trung tâm ôn tập (`practice_hub_page.dart` chứa danh sách câu sai và số lượng đến hạn hardcode), Khảo sát ban đầu (`onboarding_survey_page.dart` không lưu dữ liệu), Quên mật khẩu (Frontend gọi endpoint mà Backend chưa triển khai).
- **Tính năng Backend đã có nhưng Frontend bỏ ngỏ**: Danh mục tra cứu từ vựng (`/vocab`), Thống kê tiến độ & Lịch học (`/progress/summary`, `/progress/calendar`), Cập nhật hồ sơ & Xóa tài khoản (`/users/me`).

### Bảng tổng hợp mức độ hoàn thiện

| Module / Phân hệ | Mức độ hoàn thiện UI | Mức độ kết nối API | Đánh giá tổng thể |
|---|---|---|---|
| **1. Khởi động & Khảo sát (Welcome/Survey)** | 100% | 0% (Dữ liệu survey chưa lưu) | Đạt UI, cần lưu preferences |
| **2. Xác thực (Authentication)** | 95% | 85% (Google/Local login đạt; thiếu Quên mật khẩu BE) | Đạt mức demo |
| **3. Lộ trình học & Bài tập (Learning Path)** | 95% | 0% (Chạy 100% MockLearningRepository) | **Lệch pha hoàn toàn với Backend** |
| **4. Quét vật thể AI (Gemini Scan)** | 90% | 90% (Upload ảnh, bounding box, quota, save word) | **Điểm sáng lớn nhất của đồ án** |
| **5. Kho từ vựng (Vocabulary)** | 85% | 70% (Lấy từ đã lưu từ Scan; chưa nối Catalog từ vựng) | Đạt mức cơ bản |
| **6. Ôn tập & Flashcards (Review)** | 80% | 40% (Flashcard nối API từ scan; chưa có thuật toán SRS) | Hoàn thiện một phần |
| **7. Hồ sơ & Nhắc học (Profile/Settings)** | 85% | 60% (Lấy `/auth/me`; thiếu edit profile, xóa tài khoản) | Đạt mức khá |
| **8. Tiến độ & Lịch Streak (Progress)** | 0% | 0% (Thư mục chỉ có .gitkeep, chưa có code UI) | **Chưa triển khai trên Frontend** |
| **9. Kiểm thử tự động (Unit / Widget Test)** | 0% | 0% (Test mặc định bị crash do lệch kiến trúc) | Cần viết lại test suite |

---

## 2. KIẾN TRÚC MÃ NGUỒN & HẠ TẦNG DỰ ÁN

### 2.1. Cấu trúc thư mục `lib/`

Toàn bộ mã nguồn ứng dụng gồm **48 file Dart** với cấu trúc:

```
lib/
├── app/
│   ├── app.dart                   # Root widget LingoUpApp (MaterialApp.router + Theme)
│   └── router.dart                # Cấu hình GoRouter, AppRoutes, Auth Guard, MainShell
├── core/
│   ├── audio/
│   │   └── app_sound_effects.dart # Hiệu ứng âm thanh click, correct, error, complete
│   ├── auth/
│   │   ├── auth_notifier.dart     # Quản lý AuthState (unknown, authenticated, guest, unauthenticated)
│   │   └── google_auth_service.dart # Tích hợp Google OAuth2 -> POST /auth/social/google
│   ├── config/
│   │   └── app_config.dart        # Cấu hình baseUrl, timeouts, maxImageSizeBytes
│   ├── icons/
│   │   └── app_icons.dart         # Wrapper LucideIcons
│   ├── network/
│   │   └── app_api.dart           # Dio Client singleton, auth interceptor, refresh interceptor
│   ├── notifications/
│   │   └── study_reminder_notifications.dart # Lập lịch nhắc học cục bộ qua timezone
│   └── theme/
│       └── app_theme.dart         # AppColors, AppTextStyles, AppRadii, AppShadows
├── features/
│   ├── auth/presentation/pages/   # 6 màn hình xác thực & khảo sát
│   ├── learning/                  # Lộ trình, khung bài học, 5 dạng bài tập (Mock data)
│   ├── scan/                      # Camera scan, bounding box, quota badge (Real API)
│   ├── vocabulary/                # Danh sách từ đã lưu, chi tiết từ (Real API)
│   ├── review/                    # Practice Hub, Flashcards, Quiz (Real API + Mock)
│   ├── profile/                   # Thông tin cá nhân, cài đặt nhắc nhở, âm thanh (Real API)
│   └── progress/                  # CHỈ CÓ .gitkeep và README.md (Chưa code)
└── main.dart                      # Entrypoint: runApp(buildApp())
```

### 2.2. Đánh giá kiến trúc State Management & Router

- **State Management**:
  - `Riverpod` được dùng đúng vị trí cho trạng thái phiên đăng nhập (`authNotifierProvider`). Lớp `RouterRefreshNotifier` đóng vai trò cầu nối `Listenable` giúp `GoRouter` tự động đánh giá lại route redirect khi trạng thái user thay đổi (đăng nhập, đăng xuất, chuyển chế độ khách).
  - Trạng thái màn hình (ephemeral state) dùng `StatefulWidget` (`setState`). Cách tiếp cận này đơn giản, dễ debug cho quy mô đồ án môn học, tuy nhiên một số logic nghiệp vụ (như queue bài tập, tính điểm, timer) bị gắn chặt vào widget tree.
- **Navigation (GoRouter v14.2.7)**:
  - Phân chia rõ ràng giữa **Public Routes** (`/welcome`, `/survey`, `/auth`, `/register`, `/verify-email`, `/forgot-password`, `/reset-password`) và **Protected Routes** (được bảo vệ qua `ShellRoute`).
  - `MainShell` tích hợp `BottomAppBar` 4 tabs cố định (Lộ trình, Từ vựng, Ôn tập, Hồ sơ) cùng nút Floating Action Button ở vị trí trung tâm nổi bật để mở `/scan`.
  - Hỗ trợ deep-linking và tham số động: `/word/:id`, `/lesson/:id`.

---

## 3. DANH MỤC MÀN HÌNH, ROUTE & MÔ HÌNH DỮ LIỆU (SCREEN INVENTORY)

Toàn bộ 18 màn hình và giao diện được đối chiếu chi tiết trong bảng dưới đây:

| STT | Tên màn hình / View | File mã nguồn | Route Path | State Management | Nguồn dữ liệu sử dụng |
|---|---|---|---|---|---|
| **01** | **Màn hình Chào mừng / Splash** | `features/auth/presentation/pages/welcome_page.dart` | `/welcome` | `StatefulWidget` (`Timer`, `setState`) | Dữ liệu tĩnh (branding, mascot owl) |
| **02** | **Khảo sát ban đầu (Onboarding)** | `features/auth/presentation/pages/onboarding_survey_page.dart` | `/survey` | `StatefulWidget` (`setState`) | Dữ liệu tĩnh (Goal, Level, Time). **Chưa lưu xuống disk hay API** |
| **03** | **Đăng nhập & Chuyển chế độ** | `features/auth/presentation/pages/login_page.dart` | `/auth` | `ConsumerStatefulWidget` (Riverpod + `setState`) | **API thật**: `POST /auth/login`, `POST /auth/social/google` |
| **04** | **Đăng ký tài khoản** | `features/auth/presentation/pages/register_page.dart` | `/register` | `StatefulWidget` (`setState`) | **API thật**: `POST /auth/register` |
| **05** | **Xác minh Email** | `features/auth/presentation/pages/email_verification_page.dart` | `/verify-email` | `StatefulWidget` (`setState`) | **API thật**: `POST /auth/verify-email`, `POST /auth/resend-verify` |
| **06** | **Quên / Đặt lại mật khẩu** | `features/auth/presentation/pages/password_recovery_page.dart` | `/forgot-password`, `/reset-password` | `StatefulWidget` (`setState`) | **Lỗi kết nối**: Gọi `POST /auth/forgot-password` (Backend chưa có endpoint này) |
| **07** | **Lộ trình học (Learning Path)** | `features/learning/presentation/pages/learning_path_page.dart` | `/home/learning` | `StatefulWidget` (`setState`) | **100% Mock**: `MockLearningRepository.instance` |
| **08** | **Khung bài học (Lesson Shell)** | `features/learning/presentation/pages/lesson_page.dart` | `/lesson/:id` | `StatefulWidget` (`setState`) | **100% Mock**: Lấy bài từ in-memory repository |
| **09** | **Bài tập Chọn hình ảnh** | `features/learning/presentation/exercises/image_choice_exercise_widget.dart` | Nhúng trong Lesson | `StatefulWidget` (`setState`) | Dữ liệu bài tập mock (`ChoiceExercise`) |
| **10** | **Bài tập Xếp từ vào câu (Word Bank)** | `features/learning/presentation/exercises/word_bank_exercise_widget.dart` | Nhúng trong Lesson | `StatefulWidget` (`setState`) | Dữ liệu bài tập mock (`WordBankExercise`) |
| **11** | **Bài tập Nghe hiểu (Listening)** | `features/learning/presentation/exercises/listening_exercise_widget.dart` | Nhúng trong Lesson | `StatefulWidget` (`setState`) | Dữ liệu bài tập mock (`ListeningExercise`) |
| **12** | **Bài tập Phát âm (Speaking)** | `features/learning/presentation/exercises/speaking_exercise_widget.dart` | Nhúng trong Lesson | `StatefulWidget` (`setState`) | Giả lập thu âm / Mock speech recognition |
| **13** | **Bài tập Ghép cặp từ (Match Pairs)** | `features/learning/presentation/exercises/match_pairs_exercise_widget.dart` | Nhúng trong Lesson | `StatefulWidget` (`setState`) | Dữ liệu bài tập mock (`MatchPairsExercise`) |
| **14** | **Kết quả bài học (Lesson Result)** | `features/learning/presentation/pages/lesson_result_page.dart` | `/lesson-result` | `StatelessWidget` | Nhận `LessonResult` qua route `extra`. **Không gửi về backend** |
| **15** | **Quét ảnh Camera AI (Scan)** | `features/scan/presentation/pages/scan_camera_page.dart` | `/scan` | `StatefulWidget` (`AnimationController`, `setState`) | **API thật**: `GET /scans/quota`, `POST /scans` (upload file ảnh thật) |
| **16** | **Kết quả Quét AI & Bounding Box** | `features/scan/presentation/pages/scan_result_page.dart` | `/scan-result` | `StatefulWidget` (`setState`) | **API thật**: Vẽ box từ JSON backend, gọi `PATCH /scans/items/{id}/saved` |
| **17** | **Kho từ vựng cá nhân** | `features/vocabulary/presentation/pages/vocabulary_page.dart` | `/home/vocabulary` | `StatefulWidget` (`FutureBuilder`, `setState`) | **API thật**: `GET /scans/saved-words` |
| **18** | **Chi tiết từ vựng** | `features/vocabulary/presentation/pages/vocabulary_detail_page.dart` | `/word/:id` | `StatefulWidget` (`setState`) | **API thật**: `GET /scans/saved-words`, `PATCH /scans/items/{id}/saved` |
| **19** | **Trung tâm ôn tập (Practice Hub)** | `features/review/presentation/pages/practice_hub_page.dart` | `/home/review` | `StatefulWidget` (`setState`) | **Hỗn hợp**: Lấy số từ từ mock repo; 3 câu hỏi sai và 7 từ đến hạn là hardcode |
| **20** | **Ôn tập Flashcards & Quiz** | `features/review/presentation/pages/review_page.dart` | `/flashcards` | `StatefulWidget` (`setState`) | **API thật**: Tải từ `GET /scans/saved-words`; chế độ lật thẻ + 4 lựa chọn |
| **21** | **Hồ sơ cá nhân & Cài đặt** | `features/profile/presentation/pages/profile_page.dart` | `/home/profile` | `ConsumerStatefulWidget` (Riverpod + `setState`) | **API thật**: `GET /auth/me`, `GET /scans/quota`, `GET /scans/saved-words` |

---

## 4. PHÂN TÍCH TẦNG DỊCH VỤ MẠNG & XÁC THỰC (API CLIENTS & NETWORKING)

### 4.1. Khảo sát các lớp dịch vụ API

#### A. `AppApi` (`lib/core/network/app_api.dart`)
- **Vai trò**: Client Dio trung tâm kết nối Backend API.
- **Cấu hình**: `baseUrl = AppConfig.baseUrl` (`http://10.0.2.2:8000/api/v1`), `connectTimeout = 15s`, `receiveTimeout = 30s`, `sendTimeout = 30s`.
- **Cơ chế Token Attachment (`InterceptorsWrapper.onRequest`)**:
  - Tự động đọc `access_token` từ `FlutterSecureStorage` và đính kèm `Authorization: Bearer <token>`.
- **Cơ chế Token Rotation & Auto Refresh (`QueuedInterceptorsWrapper.onError`)**:
  - Bắt lỗi HTTP `401 Unauthorized`.
  - Kiểm tra nếu không phải request refresh token: Lấy `refresh_token` từ storage, tạo Dio client riêng (`refreshDio`) để gọi `POST /auth/refresh` với payload `{"refresh_token": token}`.
  - Nhận cặp token mới (`access_token`, `refresh_token`), cập nhật vào `FlutterSecureStorage`, gán token mới vào request ban đầu và retry tự động qua `dio.fetch()`.
  - Xử lý refresh thất bại: Xóa toàn bộ token (`clearTokens()`) và reject lỗi.

#### B. `ScanApiService` (`lib/features/scan/data/scan_api_service.dart`)
- `getQuota()`: Gọi `GET /scans/quota` -> deserializes sang model `ScanQuota` (`used`, `limit`, `remaining`).
- `scanImage(String path)`: Đóng gói ảnh thành `FormData` với `MultipartFile.fromFile(path)`, gửi `POST /scans` -> nhận JSON, map bounding box `{x, y, w, h}` sang `BoundingBox` và danh sách `DetectedObject`.
- `setSaved(String itemId, bool saved)`: Gọi `PATCH /scans/items/$itemId/saved` với body `{"is_saved": saved}`.
- `getSavedWords()`: Gọi `GET /scans/saved-words` -> lấy danh sách từ đã lưu.

#### C. `VocabularyApiService` (`lib/features/vocabulary/data/vocabulary_api_service.dart`)
- `listWords({topic, search, page, pageSize})`: Gọi `GET /vocab` với query parameters.
- `listTopics()`: Gọi `GET /vocab/topics`.
- `getById(wordId)`: Gọi `GET /vocab/$wordId`.
- `getByLemma(lemma)`: Gọi `GET /vocab/lemma/$lemma`.
- **Hiện trạng kiểm định**: Lớp service này được viết chuẩn xác và khớp hoàn toàn với schema của Backend `vocab`. Tuy nhiên, **không có bất kỳ màn hình nào trong ứng dụng gọi tới service này** (mã nguồn bị mồ côi / dead code trong ứng dụng thực tế).

#### D. `GoogleAuthService` (`lib/core/auth/google_auth_service.dart`)
- Mở luồng Google Sign-In native -> nhận `idToken` từ Google.
- Gửi lên Backend: `POST /auth/social/google` với payload `{"id_token": idToken}`.
- Nhận cặp token và lưu vào `FlutterSecureStorage`.

### 4.2. Khuyết tật kiến trúc trong việc sử dụng Dio Client

Tại các màn hình xác thực:
- `LoginPage`: Tự khai báo `final _dio = Dio(...)` cục bộ (Dòng 31–39 `login_page.dart`).
- `RegisterPage`: Tự khai báo `final _dio = Dio(...)` cục bộ (Dòng 27–35 `register_page.dart`).
- `EmailVerificationPage`: Tự khai báo `late final Dio _dio = Dio(...)` (Dòng 34–42 `email_verification_page.dart`).
- `PasswordRecoveryPage`: Tự khai báo `late final Dio _dio = Dio(...)` (Dòng 24–30 `password_recovery_page.dart`).

**Hậu quả**:
1. Không tái sử dụng được instance `AppApi.instance.dio`.
2. Không được thừa hưởng interceptors của hệ thống (nếu có bổ sung logging, metrics, error transformation sau này).
3. Cách lưu trữ token bị phân mảnh: `LoginPage` ghi trực tiếp qua `FlutterSecureStorage.write`, trong khi `RegisterPage` gọi `AppApi.instance.saveTokens(tokens)`.

---

## 5. MA TRẬN ĐỐI CHIẾU ENDPOINT BACKEND & FRONTEND (API MAPPING MATRIX)

Bảng đối chiếu toàn bộ các API endpoint được định nghĩa tại Backend FastAPI (`backend_app/backend/app/modules/`) và mức độ tích hợp của Frontend Flutter:

| Module Backend | HTTP Method & Endpoint Backend | Service / File Frontend gọi tới | Trạng thái tích hợp | Ghi chú & Lệch pha Schema |
|---|---|---|---|---|
| **Auth** | `POST /api/v1/auth/register` | `RegisterPage._submit` | **Đã kết nối** | Khớp schema (`email`, `password`, `display_name`). |
| **Auth** | `POST /api/v1/auth/login` | `LoginPage._submit` | **Đã kết nối** | Khớp schema (`email`, `password`). |
| **Auth** | `POST /api/v1/auth/social/google` | `GoogleAuthService.signIn` | **Đã kết nối** | Khớp schema (`id_token`). Cần file google-services trên thiết bị. |
| **Auth** | `POST /api/v1/auth/refresh` | `AppApi._authInterceptor` | **Đã kết nối** | Khớp schema (`refresh_token`). Tự động re-auth khi gặp 401. |
| **Auth** | `POST /api/v1/auth/verify-email` | `EmailVerificationPage._verifyToken` | **Đã kết nối** | Khớp schema (`token`). |
| **Auth** | `POST /api/v1/auth/resend-verify` | `EmailVerificationPage._resendEmail` | **Đã kết nối** | Khớp schema (`email`). |
| **Auth** | `GET /api/v1/auth/me` | `ProfilePage._loadProfile` | **Đã kết nối** | Khớp schema (`display_name`, `email`, `streak_days`, `xp_total`). |
| **Auth** | *(Chưa có trên Backend)* | `PasswordRecoveryPage._submit` | **Lệch pha (404)** | Frontend gọi `/auth/forgot-password` và `/auth/reset-password`, Backend chưa có route này. |
| **Auth** | *(Chưa có trên Backend)* | `LoginPage._signInAsGuest` | **Chỉ xử lý Local** | Frontend chỉ lưu cờ `is_guest = 'true'` trên local storage, Backend không có endpoint `/auth/guest`. |
| **Scan** | `GET /api/v1/scans/quota` | `ScanApiService.getQuota` | **Đã kết nối** | Khớp schema (`used`, `limit`, `remaining`, `reset_at`). |
| **Scan** | `POST /api/v1/scans` | `ScanApiService.scanImage` | **Đã kết nối** | Khớp schema `multipart/form-data` (`image`). Gemini AI phân tích và trả về bounding box. |
| **Scan** | `PATCH /api/v1/scans/items/{id}/saved` | `ScanApiService.setSaved` | **Đã kết nối** | Khớp schema `{"is_saved": bool}`. |
| **Scan** | `GET /api/v1/scans/saved-words` | `ScanApiService.getSavedWords`, `VocabularyPage`, `ReviewPage` | **Đã kết nối** | Khớp schema (`label`, `ipa`, `pos`, `meaning_vi`, `example_en`, `example_vi`). |
| **Learning** | `GET /api/v1/learning/paths` | *(Không có)* | **Thiếu kết nối (0%)** | Backend có router & DB, Frontend dùng `MockLearningRepository`. |
| **Learning** | `GET /api/v1/learning/paths/{id}` | *(Không có)* | **Thiếu kết nối (0%)** | Backend có router & DB, Frontend dùng mock in-memory. |
| **Learning** | `GET /api/v1/learning/lessons/{id}` | *(Không có)* | **Thiếu kết nối (0%)** | Backend có JSONB `content_data`, Frontend hardcode bài tập. |
| **Learning** | `POST /api/v1/learning/lessons/{id}/submit` | *(Không có)* | **Thiếu kết nối (0%)** | Frontend không nộp kết quả (`score`, `time_spent_seconds`) lên Backend. |
| **Vocab** | `GET /api/v1/vocab/topics` | `VocabularyApiService.listTopics` | **Mồ côi (Orphaned)** | Service frontend đã viết nhưng không có màn hình nào gọi. |
| **Vocab** | `GET /api/v1/vocab` | `VocabularyApiService.listWords` | **Mồ côi (Orphaned)** | Có hỗ trợ phân trang & search, nhưng màn hình `VocabularyPage` không sử dụng. |
| **Vocab** | `GET /api/v1/vocab/{id}` | `VocabularyApiService.getById` | **Mồ côi (Orphaned)** | Màn hình `VocabularyDetailPage` chỉ lọc từ danh sách scan cục bộ. |
| **Vocab** | `GET /api/v1/vocab/lemma/{word}` | `VocabularyApiService.getByLemma` | **Mồ côi (Orphaned)** | Không được gọi. |
| **Progress**| `GET /api/v1/progress/summary` | *(Không có)* | **Thiếu kết nối (0%)** | Backend cung cấp XP hôm nay, mục tiêu ngày; Frontend không có mã nguồn. |
| **Progress**| `GET /api/v1/progress/calendar` | *(Không có)* | **Thiếu kết nối (0%)** | Backend cung cấp lịch 30 ngày & streak dài nhất; Frontend không có mã nguồn. |
| **Users** | `GET /api/v1/users/me` | *(Không có)* | **Thiếu kết nối** | Frontend dùng tạm `GET /auth/me`. |
| **Users** | `PATCH /api/v1/users/me` | *(Không có)* | **Thiếu kết nối** | Backend cho đổi `display_name`, `avatar_url`; Frontend không có màn hình sửa hồ sơ. |
| **Users** | `DELETE /api/v1/users/me` | *(Không có)* | **Thiếu kết nối** | Backend có chức năng soft-delete; Frontend không có UI xác nhận xóa tài khoản. |
| **Users** | `POST /api/v1/users/me/fcm-token` | *(Không có)* | **Không kết nối** | Frontend dùng local notifications, không dùng backend FCM push. |

---

## 6. ĐÁNH GIÁ CÁC LUỒNG NGHIỆP VỤ & KỊCH BẢN BẢO VỆ ĐỒ ÁN (USER JOURNEYS)

### Luồng 1: Xác thực & Bắt đầu trải nghiệm (Onboarding -> Login / Guest)
- **Kịch bản thực tế**:
  1. Người dùng mở app -> Màn hình Splash chạy 1.6s -> Chuyển sang Welcome.
  2. Bấm "Bắt đầu ngay" -> Chuyển sang Onboarding Survey (3 bước chọn mục tiêu, trình độ, thời gian) -> Bấm "Tiếp tục" -> Chuyển sang Đăng nhập `/auth`.
  3. Tại Đăng nhập: Có thể Đăng ký tài khoản mới (nhập tên, email, mật khẩu), Đăng nhập bằng Email/Password thật, bấm "Tiếp tục với Google", hoặc bấm "Trải nghiệm ngay (Chế độ Khách)".
- **Đánh giá mức độ hoàn thiện**:
  - **Điểm mạnh**: Flow chuyển đổi mượt mà, validation form chi tiết (regex email, password đủ hoa/thường/số/8 ký tự), xử lý lỗi 401/409/timeout bằng SnackBar tiếng Việt thân thiện.
  - **Hạn chế**: Khảo sát ban đầu không lưu kết quả vào đâu; Guest mode chỉ lưu cờ local, không đồng bộ dữ liệu nếu user đổi máy; Quên mật khẩu chỉ hiển thị popup thông báo chưa có API.

### Luồng 2: Quét ảnh vật thể AI -> Nhận diện -> Lưu vào kho từ (Core AI Flow)
- **Kịch bản thực tế**:
  1. Từ thanh điều hướng chính, bấm nút Camera ở giữa -> Mở `ScanCameraPage`.
  2. Ứng dụng tự động kiểm tra hạn mức hôm nay (`GET /scans/quota`) và hiển thị huy hiệu (VD: "Còn 10 lượt").
  3. Người dùng có thể chọn chụp ảnh thật từ Camera hoặc chọn ảnh từ Thư viện (qua `image_picker`). Hoặc chọn nhanh chip mẫu (Cà phê, Sổ tay, Laptop, Quả táo).
  4. Hiệu ứng laser quét và overlay loading hiển thị "Gemini AI đang phân tích hình ảnh...".
  5. Ảnh kèm bounding box chuẩn hóa (tọa độ 0..1) được vẽ đè lên hình ảnh thật (`DetectionOverlay`). Bên dưới hiển thị thẻ từ chi tiết (Từ vựng, phiên âm IPA, từ loại, nghĩa tiếng Việt, câu ví dụ song ngữ).
  6. Bấm "Lưu vào kho từ" -> Gọi `PATCH /scans/items/{id}/saved` -> Cập nhật trạng thái thành công.
- **Đánh giá mức độ hoàn thiện**:
  - **Điểm mạnh**: **Đây là luồng nghiệp vụ hoàn thiện và ấn tượng nhất của đồ án**. Kết nối thực tế từ Flutter sang FastAPI đến Google Gemini Vision API; tính năng bounding box chuẩn xác, kiểm soát quota chặt chẽ.
  - **Hạn chế**: Không sử dụng package camera trực tiếp với live viewfinder thời gian thực mà thông qua picker hệ thống; các chip mẫu (sample) không tự gửi ảnh mẫu mà chỉ kích hoạt mở image picker.

### Luồng 3: Quản lý Kho từ vựng & Chi tiết từ
- **Kịch bản thực tế**:
  1. Người dùng mở Tab "Từ vựng" (`VocabularyPage`).
  2. Danh sách các từ đã quét và lưu từ AI Scan được tải về (`GET /scans/saved-words`).
  3. Bấm vào một từ -> Mở `VocabularyDetailPage` (`/word/:id`).
  4. Xem chi tiết nghĩa, ví dụ, chủ đề, nguồn lưu. Bấm "Thêm/Sửa ghi chú" -> Mở bottom sheet nhập ghi chú cá nhân. Bấm "Xóa từ" -> Gọi API gỡ lưu từ.
- **Đánh giá mức độ hoàn thiện**:
  - **Điểm mạnh**: Giao diện thẻ từ đẹp mắt, phân loại màu theo chủ đề và từ loại, thao tác xóa từ kết nối API thật.
  - **Hạn chế**: Ghi chú cá nhân (`note`) chỉ lưu trong `setState` của màn hình, khi thoát ra vào lại sẽ bị mất (Backend schema `ScanItem` chưa hỗ trợ cột note người dùng); nút phát âm từ chỉ hiển thị thông báo "Dịch vụ phát âm chưa được kết nối" (chưa tích hợp TTS); thanh tìm kiếm chỉ reload lại danh sách mà chưa lọc từ khóa; kho từ vựng tổng hợp của hệ thống (`/vocab`) hoàn toàn bị bỏ quên.

### Luồng 4: Ôn tập Flashcards & Trắc nghiệm
- **Kịch bản thực tế**:
  1. Người dùng mở Tab "Ôn tập" (`PracticeHubPage`).
  2. Bấm vào thẻ "Flashcard" -> Mở `ReviewPage`.
  3. Ứng dụng tải toàn bộ từ đã lưu từ `GET /scans/saved-words`.
  4. Người dùng có 2 chế độ:
     - **Flashcard**: Chạm vào thẻ để lật mặt trước (tiếng Anh + IPA) / mặt sau (nghĩa tiếng Việt + ví dụ). Bấm "Cần ôn lại" hoặc "Đã nhớ tốt" để chuyển từ tiếp theo.
     - **Quiz**: Chọn đáp án tiếng Anh đúng trong 4 phương án ngẫu nhiên, kiểm tra đúng/sai trực quan.
- **Đánh giá mức độ hoàn thiện**:
  - **Điểm mạnh**: Trực quan, hiệu ứng lật thẻ 3D mượt mà, tự động tạo câu hỏi trắc nghiệm từ kho từ cá nhân.
  - **Hạn chế**: Nút "Cần ôn lại" và "Đã nhớ tốt" không gửi bất kỳ đánh giá nào về backend (không có thuật toán lặp lại ngắt quãng SRS SuperMemo/SM-2); các mục "Luyện nghe nhanh", "Luyện nói nhanh", "Hộp lỗi sai" tại Practice Hub là dữ liệu tĩnh / placeholder.

### Luồng 5: Học theo Lộ trình & Hoàn thành bài học (Roadmap Flow)
- **Kịch bản thực tế**:
  1. Người dùng mở Tab "Lộ trình" (`LearningPathPage`).
  2. Thấy cây tiến trình 3 Unit: Chào hỏi, Đồ ăn, Du lịch.
  3. Bấm vào bài học đang mở (Unit 1 Lesson 2: Giới thiệu bản thân) -> Hiện preview bottom sheet -> Bấm "Bắt đầu học" -> Chuyển vào `LessonPage`.
  4. Trải nghiệm lần lượt 5 dạng bài tập: Chọn hình, xếp từ vào câu, nghe âm thanh, nói, ghép cặp. Có thanh tiến độ, âm thanh sfx (click, success, error), xử lý câu sai bằng cách đưa về cuối hàng đợi làm lại.
  5. Sau khi hết câu hỏi -> Chuyển sang `LessonResultPage` hiển thị cúp vàng, XP thưởng (+20 XP), tỉ lệ chính xác, thời gian làm bài, streak ngày. Bấm "Tiếp tục" -> Quay lại lộ trình, bài học tiếp theo được mở khóa.
- **Đánh giá mức độ hoàn thiện**:
  - **Điểm mạnh**: Trải nghiệm học tập và tương tác bài tập (gamification, audio feedback, redo queue) được lập trình rất xuất sắc, mượt mà và sinh động, tiệm cận ứng dụng thương mại như Duolingo.
  - **HẠN CHẾ CỰC KỲ NGHIÊM TRỌNG**: **Toàn bộ tiến trình học, điểm số, bài tập, mở khóa bài học hoàn toàn chạy trên bộ nhớ RAM (`MockLearningRepository.instance`)**. Khi tắt ứng dụng mở lại, tiến trình bị reset; kết quả bài học không hề được gửi lên Backend `POST /learning/lessons/{id}/submit`; các bài học trong database PostgreSQL của Backend hoàn toàn không được sử dụng.

---

## 7. ĐÁNH GIÁ BẢO MẬT, XỬ LÝ LỖI & CẤU HÌNH NỀN TẢNG (PLATFORM & SECURITY)

### 7.1. Cấu hình mạng Android & Nguy cơ chặn HTTP Cleartext
- **Quan sát**: Trong `lib/core/config/app_config.dart`, địa chỉ backend mặc định là:
  ```dart
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api/v1',
  );
  ```
- **Lỗi tiềm ẩn**: Trong `android/app/src/main/AndroidManifest.xml`, thẻ `<application>` **KHÔNG có thuộc tính `android:usesCleartextTraffic="true"`** và không có Network Security Config.
- **Hệ quả**: Từ Android 9.0 (API 28) trở lên, hệ điều hành mặc định cấm tất cả kết nối `http://` không mã hóa. Khi chạy trên máy ảo Android Emulator hoặc thiết bị thật kết nối qua mạng nội bộ, mọi request API sẽ bị chặn với lỗi `SocketException` hoặc `CLEARTEXT communication to 10.0.2.2 not permitted by network security policy`.

### 7.2. Cấu hình quyền hạn trên iOS (Info.plist)
- **Quan sát**: File `ios/Runner/Info.plist` hoàn toàn thiếu các khai báo quyền hạn bắt buộc:
  - Thiếu `NSCameraUsageDescription` (Quyền truy cập Camera).
  - Thiếu `NSPhotoLibraryUsageDescription` (Quyền truy cập Thư viện ảnh).
  - Thiếu `NSMicrophoneUsageDescription` (Quyền truy cập Micro thu âm).
- **Hệ quả**: Nếu biên dịch ứng dụng sang iOS và người dùng bấm nút chụp ảnh hoặc chọn ảnh trong màn hình Scan, hệ điều hành iOS sẽ **ngay lập tức ép ứng dụng crash (SIGABRT)** theo chính sách bảo mật của Apple.

### 7.3. Thiếu file cấu hình Google Services
- Tài liệu `GOOGLE_SIGNIN_SETUP.md` hướng dẫn chi tiết việc tích hợp Google OAuth2, tuy nhiên kiểm tra thực tế trong cây thư mục:
  - `android/app/google-services.json` -> **CHƯA CÓ**.
  - `ios/Runner/GoogleService-Info.plist` -> **CHƯA CÓ**.
- **Hệ quả**: Chức năng "Tiếp tục với Google" trên thiết bị thật sẽ gặp lỗi `PlatformException` hoặc không mở được cửa sổ đăng nhập tài khoản Google.

### 7.4. Xử lý Token & Đăng xuất
- Token lưu an toàn trong `FlutterSecureStorage` (sử dụng Android Keystore và iOS Keychain).
- Tuy nhiên, trong `lib/core/network/app_api.dart`:
  Khi refresh token thất bại tại interceptor, hàm `clearTokens()` được gọi nhưng **không thông báo cho `AuthNotifier`**. Trạng thái `authNotifierProvider` vẫn giữ giá trị `AuthState.authenticated`, khiến người dùng có thể vẫn nhìn thấy giao diện cá nhân cho đến khi họ thực hiện một thao tác điều hướng mới.

---

## 8. CHẤT LƯỢNG MÃ NGUỒN, KIỂM THỬ TỰ ĐỘNG & NỢ KỸ THUẬT (TECHNICAL DEBT)

### 8.1. Kiểm thử tự động (Unit / Widget Testing)
- Thư mục `test/` hiện chỉ có duy nhất 1 file: `test/widget_test.dart`.
- Nội dung file này là mã nguồn mẫu mặc định của Flutter:
  ```dart
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const LingoUpApp());
    expect(find.text('0'), findsOneWidget);
    ...
  });
  ```
- **Hậu quả**:
  1. `LingoUpApp` cần có `ProviderScope` để đọc `routerProvider`. Khi chạy `tester.pumpWidget(const LingoUpApp())`, test sẽ ngay lập tức crash với lỗi `Bad state: No ProviderScope found`.
  2. Test tìm kiếm widget đếm số `'0'`, `'1'` không tồn tại trong ứng dụng LingoUp.
  3. Dự án hiện có **0% Test Coverage** cho cả phần nghiệp vụ và widget thực tế.

### 8.2. Các thành phần mồ côi (Orphaned Code)
1. `lib/features/vocabulary/data/mock_vocabulary_repository.dart`: Khởi tạo sẵn một danh sách từ vựng giả lập, nhưng chỉ được `practice_hub_page.dart` gọi để lấy `.length`.
2. `lib/features/scan/data/mock_scan_service.dart`: Chứa logic giả lập phân tích ảnh 4 mẫu (book, laptop, apple, coffee), nhưng `ScanCameraPage` đã chuyển sang dùng `ScanApiService` thật nên file này không còn nơi nào import.
3. `lib/features/vocabulary/data/vocabulary_api_service.dart`: Được cài đặt đầy đủ phương thức cho `/vocab` nhưng không có màn hình nào sử dụng.

---

## 9. DANH MỤC KHUYẾN NGHỊ ƯU TIÊN TRƯỚC KHI BẢO VỆ ĐỒ ÁN (ACTIONABLE RECOMMENDATIONS)

Dưới đây là các hạng mục khuyến nghị được phân loại theo mức độ ưu tiên để nhóm hoàn thiện ứng dụng đạt điểm tối đa trước hội đồng chấm đồ án:

### Mức độ 1: Cực kỳ khẩn cấp (Critical - Phục vụ Demo & Tránh Crash)
1. **Khắc phục lỗi chặn mạng Android HTTP Cleartext**:
   Thêm `android:usesCleartextTraffic="true"` vào thẻ `<application>` trong `android/app/src/main/AndroidManifest.xml` để đảm bảo máy ảo Android gọi được API Backend `http://10.0.2.2:8000`.
2. **Bổ sung quyền hạn bắt buộc trong `ios/Runner/Info.plist`**:
   Thêm `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`, `NSMicrophoneUsageDescription` để ứng dụng không bị crash khi test trên thiết bị iOS / Simulator.
3. **Sửa file test mặc định (`test/widget_test.dart`)**:
   Viết lại smoke test bọc trong `ProviderScope`, kiểm tra màn hình Welcome hoặc Login render thành công thay vì test bộ đếm counter demo.

### Mức độ 2: Nghiệp vụ trọng tâm (High Priority - Nâng tầm đồ án)
4. **Kết nối Module Lộ trình học (`features/learning/`) với Backend API**:
   - Thay thế `MockLearningRepository` bằng một repository gọi `GET /api/v1/learning/paths` và `GET /api/v1/learning/lessons/{id}`.
   - Tại `LessonResultPage`, bổ sung lệnh gọi `POST /api/v1/learning/lessons/{id}/submit` gửi `score` và `time_spent_seconds` để Backend ghi nhận XP và cập nhật streak vào cơ sở dữ liệu thật.
5. **Đồng bộ hóa phiên bản Dio Client**:
   Chuyển các lời gọi API tự tạo Dio tại `LoginPage`, `RegisterPage`, `EmailVerificationPage` sang dùng chung `AppApi.instance.dio`.
6. **Kết nối Danh mục tra cứu từ vựng (`VocabularyApiService`) vào `VocabularyPage`**:
   Tích hợp tính năng tìm kiếm từ vựng thật từ catalog Backend (`GET /vocab?search=...`) bên cạnh danh sách từ quét từ AI.

### Mức độ 3: Hoàn thiện trải nghiệm (Medium Priority - Điểm cộng đồ án)
7. **Lưu trữ ghi chú từ vựng bền vững**:
   Tạo bảng lưu ghi chú cá nhân ở backend hoặc lưu vào `shared_preferences` trên máy, tránh việc ghi chú bị mất khi reload widget.
8. **Hoàn thiện màn hình Hồ sơ & Xóa tài khoản**:
   Thêm dialog xác nhận "DELETE_MY_ACCOUNT" gọi `DELETE /users/me` và form cập nhật tên gọi `PATCH /users/me` theo đúng các endpoint backend đã hỗ trợ sẵn.
9. **Cấu hình Google Sign-In**:
   Tạo Firebase Project và đưa file `google-services.json` vào `android/app/` nếu muốn trình chiếu tính năng Social Login một chạm trong buổi bảo vệ.

---
*Báo cáo được lập tự động bởi Agent Teamwork Explorer Frontend dựa trên rà soát mã nguồn tĩnh.*
