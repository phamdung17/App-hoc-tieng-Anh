# BÁO CÁO KHẢO SÁT & THIẾT KẾ KIẾN TRÚC FRONTEND FLUTTER
## (Frontend Deep Investigation & Architectural Blueprint)

**Dự án:** Ứng dụng Học Tiếng Anh Thông Minh LingoUp (`app_hoc_tieng_anh`)  
**Tác giả:** explorer_survey_2 (Teamwork Explorer Subagent)  
**Thời gian khảo sát:** 03/11/2026  
**Chế độ thực thi:** Read-Only Investigation (100% không can thiệp sửa đổi mã nguồn repository)

---

## MỤC LỤC
1. [Tổng quan khảo sát (Executive Summary)](#1-tổng-quan-khảo-sát-executive-summary)
2. [Khảo sát 1: Cấu hình mạng Android (`AndroidManifest.xml`)](#2-khảo-sát-1-cấu-hình-mạng-android-androidmanifestxml)
3. [Khảo sát 2: Khai báo quyền phần cứng iOS (`Info.plist`)](#3-khảo-sát-2-khai-báo-quyền-phần-cứng-ios-infoplist)
4. [Khảo sát 3: Chuẩn hóa Base URL, RFC 3986 & Hợp nhất HTTP Client Dio](#4-khảo-sát-3-chuẩn-hóa-base-url-rfc-3986--hợp-nhất-http-client-dio)
5. [Khảo sát 4: Kiến trúc Lộ trình học (Learning Module) & Cơ chế Fallback Dữ liệu Mẫu](#5-khảo-sát-4-kiến-trúc-lộ-trình-học-learning-module--cơ-chế-fallback-dữ-liệu-mẫu)
6. [Khảo sát 5: Chiến lược Kiểm thử tự động Frontend (`flutter test`)](#6-khảo-sát-5-chiến-lược-kiểm-thử-tự-động-frontend-flutter-test)
7. [Kế hoạch hành động & Danh mục công việc chi tiết cho Implementer](#7-kế-hoạch-hành-động--danh-mục-công-việc-chi-tiết-cho-implementer)

---

## 1. TỔNG QUAN KHẢO SÁT (EXECUTIVE SUMMARY)

Qua quá trình rà soát toàn bộ cây mã nguồn Frontend Flutter (`app_hoc_tieng_anh/`), nhóm khảo sát đã xác định các phát hiện cốt lõi sau:
1. **Lỗi chặn P0 Mạng Android:** `AndroidManifest.xml` thiếu cờ `android:usesCleartextTraffic="true"`, khiến hệ điều hành Android (từ API 28 trở lên) chặn 100% kết nối HTTP nội bộ tới Backend `http://10.0.2.2:8000`.
2. **Lỗi chặn P1 Crash iOS:** `ios/Runner/Info.plist` hoàn toàn thiếu 3 khóa mô tả quyền truy cập phần cứng (`NSCameraUsageDescription`, `NSMicrophoneUsageDescription`, `NSPhotoLibraryUsageDescription`). Ứng dụng sẽ bị iOS crash cưỡng chế (`SIGABRT`) khi mở camera quét AI hoặc làm bài tập nói.
3. **Lỗi phân mảnh & Bất cập đường dẫn API (RFC 3986):**
   - Hiện tại có 4 màn hình xác thực (`LoginPage`, `RegisterPage`, `EmailVerificationPage`, `PasswordRecoveryPage`) tự khởi tạo instance `Dio` riêng rẽ với `AppConfig.baseUrl`, phá vỡ kiến trúc singleton của `AppApi`.
   - Cấu hình `AppConfig.baseUrl` mặc định trỏ về `'http://10.0.2.2:8000/api/v1'`. Toàn bộ các service và màn hình gọi endpoint bắt đầu bằng `/` (`/auth/login`, `/scans/quota`, `/vocab`, v.v.). Nếu cấu hình không đồng bộ hoặc khi ghép nối với các service mới gọi `/api/v1/...`, hệ thống sẽ gặp lỗi nhân đôi tiền tố `/api/v1/api/v1/...` hoặc lỗi xóa mất `/api/v1` theo chuẩn RFC 3986. Cần một cơ chế chuẩn hóa URL resolver và Interceptor thống nhất.
4. **Đứt gãy phân hệ Lộ trình học (Learning Feature):**
   - Toàn bộ màn hình `LearningPathPage` và `LessonPage` hiện đang phụ thuộc trực tiếp vào `MockLearningRepository.instance` trong RAM, hoàn toàn chưa kết nối với 4 endpoint của Backend (`/paths`, `/paths/{id}`, `/lessons/{id}`, `/lessons/{id}/submit`).
   - Cần xây dựng `LearningApiService` và `LearningRepository` có khả năng tải dữ liệu thật từ Backend khi có mạng, phân giải nội dung bài tập 5 dạng từ JSONB, đồng thời tự động chuyển đổi mượt mà sang `MockLearningRepository` khi mất kết nối mạng hoặc Backend chưa có dữ liệu mà tuyệt đối không gây crash ứng dụng.

---

## 2. KHẢO SÁT 1: CẤU HÌNH MẠNG ANDROID (`AndroidManifest.xml`)

### 2.1. Vị trí & Hiện trạng quan sát được
- **Tập tin:** `app_hoc_tieng_anh/android/app/src/main/AndroidManifest.xml`
- **Dòng mã quan sát:** Dòng 5–8
```xml
    <application
        android:label="LingoUp"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
```
Thẻ `<application>` hiện chỉ có 3 thuộc tính: `android:label`, `android:name`, `android:icon`. Hoàn toàn không có thuộc tính `android:usesCleartextTraffic`.

### 2.2. Phân tích nguyên nhân & Rủi ro
- Kể từ Android 9.0 (API Level 28 - Pie), hệ điều hành Android kích hoạt chính sách Network Security Config mặc định từ chối tất cả lưu lượng mạng văn bản thuần (Cleartext HTTP).
- Khi lập trình và chạy ứng dụng trên máy ảo Android Emulator, địa chỉ IP kết nối tới máy chủ phát triển cục bộ là `http://10.0.2.2:8000` (hoặc `http://192.168.x.x:8000` trên thiết bị thật qua Wi-Fi nội bộ). Do các URL này chạy giao thức `http://` (không có TLS/SSL mã hóa `https://`), tầng mạng Android native sẽ chặn cuộc gọi ngay lập tức với biệt lệ:
  ```
  java.io.IOException: Cleartext HTTP traffic to 10.0.2.2 not permitted
  ```
- Kết quả: Dio bắn ra ngoại lệ `DioException [connection error]`, người dùng không thể thực hiện bất kỳ thao tác mạng nào dù Backend đang chạy bình thường.

### 2.3. Giải pháp đề xuất cho Implementer
Thêm thuộc tính `android:usesCleartextTraffic="true"` vào thẻ `<application>`:
```xml
<!-- app_hoc_tieng_anh/android/app/src/main/AndroidManifest.xml (Dòng 5-9) -->
    <application
        android:label="LingoUp"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher"
        android:usesCleartextTraffic="true">
```

---

## 3. KHẢO SÁT 2: KHAI BÁO QUYỀN PHẦN CỨNG IOS (`Info.plist`)

### 3.1. Vị trí & Hiện trạng quan sát được
- **Tập tin:** `app_hoc_tieng_anh/ios/Runner/Info.plist`
- **Dòng mã quan sát:** Dòng 4–69 (thẻ `<dict>...</dict>`)
Trong cấu trúc từ điển `<dict>` của `Info.plist`, hoàn toàn không có bất kỳ khóa nào liên quan đến Camera (`NSCameraUsageDescription`), Thư viện ảnh (`NSPhotoLibraryUsageDescription`), hay Microphone (`NSMicrophoneUsageDescription`).

### 3.2. Phân tích nguyên nhân & Rủi ro
- Trong ứng dụng LingoUp, có 2 tính năng trọng tâm tương tác với phần cứng thiết bị:
  1. **Quét AI Vật thể (`features/scan`):** Sử dụng gói `image_picker` để chụp ảnh từ Camera (`ImageSource.camera`) hoặc chọn ảnh từ bộ sưu tập (`ImageSource.gallery`) gửi lên Google Gemini 2.0 Flash AI.
  2. **Luyện tập Phát âm (`features/learning/presentation/exercises/speaking_exercise_widget.dart`):** Bài tập nói yêu cầu thu âm giọng đọc của người học qua micro.
- Trên hệ điều hành iOS (Apple iOS 10+), cơ chế bảo mật sandbox quy định: Bất kỳ ứng dụng nào cố gắng khởi tạo API truy cập Camera, Thư viện ảnh hoặc Microphone mà không khai báo chuỗi giải trình lý do trong `Info.plist` sẽ bị kernel iOS dừng tiến trình ngay lập tức với tín hiệu kết thúc lỗi `SIGABRT`:
  ```
  This app has crashed because it attempted to access privacy-sensitive data without a usage description. 
  The app's Info.plist must contain an NSCameraUsageDescription key with a string value explaining to the user how the app uses this data.
  ```

### 3.3. Giải pháp đề xuất cho Implementer
Bổ sung đầy đủ 3 khóa quyền vào cấu trúc `<dict>` trong `app_hoc_tieng_anh/ios/Runner/Info.plist`:
```xml
	<!-- Khai báo quyền phần cứng cho AI Scan & Luyện phát âm -->
	<key>NSCameraUsageDescription</key>
	<string>LingoUp cần quyền truy cập camera để chụp ảnh và quét đồ vật học từ vựng bằng AI.</string>
	<key>NSPhotoLibraryUsageDescription</key>
	<string>LingoUp cần quyền truy cập thư viện ảnh để bạn chọn hình ảnh quét từ vựng.</string>
	<key>NSMicrophoneUsageDescription</key>
	<string>LingoUp cần quyền sử dụng micro để bạn thực hiện các bài tập luyện phát âm.</string>
```

---

## 4. KHẢO SÁT 3: CHUẨN HÓA BASE URL, RFC 3986 & HỢP NHẤT HTTP CLIENT DIO

### 4.1. Điều tra hiện trạng các vị trí khởi tạo & gọi API Dio trong dự án

Kiểm tra toàn bộ mã nguồn `lib/` phát hiện các vị trí thực hiện gọi API như sau:

| STT | Tập tin | Cách thức khởi tạo Dio | Endpoint gọi API |
|:---:|---|---|---|
| 1 | `lib/core/network/app_api.dart` | Singleton `AppApi.instance.dio` (kèm Interceptor Auth & Refresh 401) | Tự gọi `/auth/refresh` khi token hết hạn |
| 2 | `lib/features/auth/presentation/pages/login_page.dart` (dòng 31) | Tự tạo `final _dio = Dio(BaseOptions(baseUrl: AppConfig.baseUrl))` | `_dio.post('/auth/login')`, `_dio.post('/auth/register')` |
| 3 | `lib/features/auth/presentation/pages/register_page.dart` (dòng 27) | Tự tạo `final _dio = Dio(BaseOptions(baseUrl: AppConfig.baseUrl))` | `_dio.post('/auth/register')` |
| 4 | `lib/features/auth/presentation/pages/email_verification_page.dart` (dòng 34) | Tự tạo `late final Dio _dio = Dio(BaseOptions(baseUrl: AppConfig.baseUrl))` | `_dio.post('/auth/verify-email')`, `_dio.post('/auth/resend-verify')` |
| 5 | `lib/features/auth/presentation/pages/password_recovery_page.dart` (dòng 24) | Tự tạo `late final Dio _dio = Dio(BaseOptions(baseUrl: AppConfig.baseUrl))` | `_dio.post('/auth/forgot-password')`, `_dio.post('/auth/reset-password')` |
| 6 | `lib/core/auth/google_auth_service.dart` (dòng 45) | Dùng `AppApi.instance.dio` | `AppApi.instance.dio.post('/auth/social/google')` |
| 7 | `lib/features/scan/data/scan_api_service.dart` (dòng 26-61) | Dùng `AppApi.instance.dio` | `GET /scans/quota`, `POST /scans`, `PATCH /scans/items/$id/saved`, `GET /scans/saved-words` |
| 8 | `lib/features/vocabulary/data/vocabulary_api_service.dart` (dòng 26-65) | Dùng `AppApi.instance.dio` | `GET /vocab`, `GET /vocab/topics`, `GET /vocab/$id`, `GET /vocab/lemma/$lemma` |
| 9 | `lib/features/vocabulary/presentation/pages/vocabulary_page.dart` (dòng 20) | Dùng `AppApi.instance.dio` | `GET /scans/saved-words` |
| 10 | `lib/features/vocabulary/presentation/pages/vocabulary_detail_page.dart` (dòng 33) | Dùng `AppApi.instance.dio` | `GET /scans/saved-words` |
| 11 | `lib/features/profile/presentation/pages/profile_page.dart` (dòng 40) | Dùng `AppApi.instance.dio` | `GET /auth/me` |
| 12 | `lib/features/review/presentation/pages/review_page.dart` (dòng 34) | Dùng `AppApi.instance.dio` | `GET /scans/saved-words` |

### 4.2. Phân tích chuyên sâu cơ chế lỗi RFC 3986 & Nguy cơ nhân đôi tiền tố `/api/v1/api/v1`

1. **Cấu hình hiện tại:**
   - Trong `app_config.dart` (dòng 22–25):
     ```dart
     static const String baseUrl = String.fromEnvironment(
       'API_BASE_URL',
       defaultValue: 'http://10.0.2.2:8000/api/v1',
     );
     ```
2. **Cơ chế phân giải URL nội bộ của Dio (kiểm tra thực tế từ `dio-5.11.1/lib/src/options.dart`, dòng 662–677):**
   ```dart
   Uri get uri {
     String url = path;
     if (!url.startsWith(RegExp(r'https?:'))) {
       url = baseUrl + url;
       final s = url.split(':/');
       if (s.length == 2) {
         url = '${s[0]}:/${s[1].replaceAll('//', '/')}';
       }
     }
     ...
     return Uri.parse(url).normalizePath();
   }
   ```
3. **Hai cạm bẫy kỹ thuật xuất hiện:**
   - **Cạm bẫy 1 (Chuẩn RFC 3986 & `Uri.resolve`):** Theo tiêu chuẩn RFC 3986 mục 5.2.2, phương thức chuẩn `Uri.parse(baseUrl).resolve(path)` của Dart khi gặp một đường dẫn bắt đầu bằng dấu gạch chéo `/` (ví dụ `'/auth/login'`) sẽ xem đó là đường dẫn tuyệt đối bắt đầu từ máy chủ (host-relative), do đó xóa bỏ toàn bộ path component của base URL (`/api/v1`) và chuyển thành `http://10.0.2.2:8000/auth/login`. Khi viết unit test hoặc khi chạy qua các công cụ chuẩn RFC 3986, toàn bộ request sẽ bị 404.
   - **Cạm bẫy 2 (Nguy cơ nhân đôi tiền tố `/api/v1/api/v1` trong Dio):** Do hàm `get uri` của Dio ghép chuỗi trực tiếp `baseUrl + url`:
     - Nếu `baseUrl` là `'http://10.0.2.2:8000/api/v1'` và lập trình viên gọi endpoint đầy đủ `/api/v1/learning/paths` (như mẫu trong báo cáo trước đây), chuỗi tạo thành sẽ là:
       $$\text{http://10.0.2.2:8000/api/v1/api/v1/learning/paths}$$
       Hậu quả: Backend FastAPI trả về **404 Not Found** do dư thừa tiền tố!
     - Ngược lại, nếu đổi `baseUrl` thành `http://10.0.2.2:8000`, thì 12 vị trí gọi API hiện có (đang gọi `'/auth/login'`, `'/scans/quota'`, `'/vocab'`) lại bị thiếu `/api/v1` và biến thành `http://10.0.2.2:8000/auth/login` -> Tiếp tục bị **404 Not Found**!
   - **Cạm bẫy 3 (Phân mảnh Instance Dio):** Các trang `LoginPage`, `RegisterPage`, `EmailVerificationPage`, `PasswordRecoveryPage` tự tạo instance `Dio` cục bộ, nên nếu chỉ thêm Interceptor vào `AppApi.instance.dio`, các trang xác thực sẽ hoàn toàn không được thừa hưởng logic xử lý prefix!

### 4.3. Giải pháp Kiến trúc Tối ưu & Bền vững (Bulletproof URL Architecture)

Để giải quyết triệt để và an toàn tuyệt đối mọi kịch bản (kể cả khi chạy môi trường dev, test hay production), kiến trúc đề xuất gồm 3 trụ cột:

#### Trụ cột 1: Chuẩn hóa `AppConfig.baseUrl` về Host Root kèm hàm làm sạch tiền tố
Trong `app_config.dart`, quy ước `baseUrl` là host authority gốc (mặc định `'http://10.0.2.2:8000'`). Đồng thời cung cấp phương thức `cleanBaseUrl` để loại bỏ an toàn các hậu tố `/api/v1` hoặc dấu gạch chéo `/` dư thừa nếu người dùng truyền qua `--dart-define=API_BASE_URL=...`:
```dart
class AppConfig {
  AppConfig._();

  static const String _rawBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  /// Base URL gốc của server (luôn đảm bảo không có trailing slash hay /api/v1 thừa)
  static String get baseUrl => cleanBaseUrl(_rawBaseUrl);

  static const String apiV1Prefix = '/api/v1';

  static String cleanBaseUrl(String url) {
    var cleaned = url.trim();
    while (cleaned.endsWith('/')) {
      cleaned = cleaned.substring(0, cleaned.length - 1);
    }
    if (cleaned.endsWith('/api/v1')) {
      cleaned = cleaned.substring(0, cleaned.length - '/api/v1'.length);
    }
    while (cleaned.endsWith('/')) {
      cleaned = cleaned.substring(0, cleaned.length - 1);
    }
    return cleaned;
  }
}
```

#### Trụ cột 2: Hàm URL Normalizer chuẩn hóa đường dẫn trong `AppApi`
Trong `lib/core/network/app_api.dart`, triển khai phương thức tĩnh `normalizePath` phục vụ cả Interceptor lẫn bộ kiểm thử tự động `flutter test`:
```dart
class AppApi {
  // ...
  
  /// Chuẩn hóa đường dẫn endpoint:
  /// - Giữ nguyên URL tuyệt đối (http:// hoặc https://)
  /// - Giữ nguyên các endpoint đặc biệt ở root nếu có (ví dụ '/health')
  /// - Đảm bảo tiền tố /api/v1 luôn xuất hiện đúng 1 lần duy nhất, không trùng lặp
  static String normalizePath(String path) {
    final trimmed = path.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }

    // Đảm bảo có leading slash
    final cleanPath = trimmed.startsWith('/') ? trimmed : '/$trimmed';

    // Trường hợp endpoint hệ thống ở root (như /health)
    if (cleanPath == '/health') {
      return cleanPath;
    }

    // Nếu đã có sẵn /api/v1 thì giữ nguyên
    if (cleanPath.startsWith('/api/v1/') || cleanPath == '/api/v1') {
      return cleanPath;
    }

    // Bổ sung tiền tố /api/v1
    return '/api/v1$cleanPath';
  }

  /// Trả về URL đầy đủ đã phân giải chính xác
  static String resolveUrl(String path, {String? customBaseUrl}) {
    final base = AppConfig.cleanBaseUrl(customBaseUrl ?? AppConfig.baseUrl);
    final normPath = normalizePath(path);
    if (normPath.startsWith('http://') || normPath.startsWith('https://')) {
      return normPath;
    }
    return '$base$normPath';
  }
}
```

#### Trụ cột 3: Request Interceptor tự động chuẩn hóa mọi request & Hợp nhất Dio
Trong `AppApi._()`:
1. Thêm Interceptor đầu tiên trong hàng đợi `dio.interceptors`:
   ```dart
   dio.interceptors.add(
     InterceptorsWrapper(
       onRequest: (options, handler) {
         options.path = normalizePath(options.path);
         handler.next(options);
       },
     ),
   );
   ```
2. Đổi các trang xác thực (`LoginPage`, `RegisterPage`, `EmailVerificationPage`, `PasswordRecoveryPage`) từ việc tự tạo `final _dio = Dio(...)` sang sử dụng trực tiếp `AppApi.instance.dio` (hoặc `AppApi.instance.publicDio`). Điều này giúp loại bỏ hoàn toàn sự phân mảnh, tái sử dụng cấu hình timeout và tự động hưởng lợi từ `normalizePath`.

---

## 5. KHẢO SÁT 4: KIẾN TRÚC LỘ TRÌNH HỌC (LEARNING MODULE) & CƠ CHẾ FALLBACK DỮ LIỆU MẪU

### 5.1. Hiện trạng phân hệ Learning trên Frontend & Đối chiếu với Backend FastAPI

#### Mô hình dữ liệu Frontend hiện tại:
- `LearningUnit`: `id`, `number`, `title`, `description`, `lessons: List<LessonNode>`.
- `LessonNode`: `id`, `unitId`, `title`, `description`, `order`, `xpReward`, `status: LessonStatus (completed | current | locked)`, `exerciseCount`.
- `LessonDetail`: `id`, `title`, `unitTitle`, `xpReward`, `exercises: List<Exercise>`.
- `Exercise`: Lớp trừu tượng với 5 lớp con:
  1. `ChoiceExercise`: `targetWord`, `ipa`, `options: List<ChoiceOption>`, `correctOptionIndex`, `explanation`.
  2. `WordBankExercise`: `vietnameseSentence`, `correctWords`, `availableWords`, `explanation`.
  3. `MatchPairsExercise`: `pairs: List<WordPair>`, `explanation`.
  4. `ListeningExercise`: `audioText`, `answer`.
  5. `SpeakingExercise`: `phrase`.
- `LessonResult`: `lessonId`, `lessonTitle`, `xpEarned`, `accuracyPercentage`, `totalQuestions`, `correctCount`, `durationSeconds`, `streakDays`.

#### Mô hình dữ liệu Backend FastAPI (`app/modules/learning/`):
- `GET /learning/paths`: Trả về `list[LearningPathSummary]` (`id`, `title`, `level`, `total_lessons`, `completed_lessons`).
- `GET /learning/paths/{path_id}`: Trả về `LearningPathResponse` chứa danh sách `units: list[UnitResponse]`. Mỗi unit có `lessons: list[LessonSummary]`.
  - Trạng thái bài học trên Backend: `"locked" | "available" | "completed"`.
- `GET /learning/lessons/{lesson_id}`: Trả về `LessonDetailResponse` (`id`, `title`, `lesson_type`, `xp_reward`, `content_data`, `status`, `best_score`).
  - Trong đó `content_data` lưu trữ cấu trúc JSONB chứa danh sách bài tập.
- `POST /learning/lessons/{lesson_id}/submit`: Nhận `{"score": int, "time_spent_seconds": int}`, trả về `{"xp_earned": int, "new_total_xp": int, "streak_days": int, "lesson_status": str, "unlocked_lessons": list[str]}`.

#### Bảng Ánh Xạ Trạng Thái & Dữ Liệu (Mapping Matrix):
| Thuộc tính Backend | Kiểu dữ liệu Backend | Thuộc tính Frontend | Kiểu dữ liệu Frontend | Quy tắc chuyển đổi |
|---|---|---|---|---|
| `UnitResponse.order_index` | `int` | `LearningUnit.number` | `int` | `order_index + 1` |
| `LessonSummary.status` | `str` (`"completed"`) | `LessonNode.status` | `LessonStatus` | `LessonStatus.completed` |
| `LessonSummary.status` | `str` (`"available"`) | `LessonNode.status` | `LessonStatus` | `LessonStatus.current` |
| `LessonSummary.status` | `str` (`"locked"`) | `LessonNode.status` | `LessonStatus` | `LessonStatus.locked` |
| `Lesson.content_data["exercises"]` | `list[dict]` | `LessonDetail.exercises` | `List<Exercise>` | Parse theo trường `type` (`choice`, `word_bank`, `match_pairs`, `listening`, `speaking`) |

### 5.2. Thiết kế chi tiết `learning_api_service.dart`

Tạo tập tin mới: `app_hoc_tieng_anh/lib/features/learning/data/learning_api_service.dart`.
Áp dụng mẫu Singleton (đồng bộ phong cách với `ScanApiService` và `VocabularyApiService`), đồng thời có thể cung cấp Provider Riverpod wrapper:

```dart
// lib/features/learning/data/learning_api_service.dart
import '../../../../core/network/app_api.dart';

class LearningApiService {
  LearningApiService._();
  static final LearningApiService instance = LearningApiService._();

  final _api = AppApi.instance;

  /// Lấy danh sách các lộ trình học đang active
  Future<List<Map<String, dynamic>>> getPaths() async {
    final response = await _api.dio.get<List<dynamic>>('/learning/paths');
    return (response.data ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
  }

  /// Lấy chi tiết lộ trình kèm các Unit và danh sách Lesson tóm tắt
  Future<Map<String, dynamic>> getPathDetail(String pathId) async {
    final response = await _api.dio.get<Map<String, dynamic>>('/learning/paths/$pathId');
    return response.data ?? const <String, dynamic>{};
  }

  /// Lấy chi tiết bài học kèm content_data (danh sách bài tập tương tác)
  Future<Map<String, dynamic>> getLessonDetail(String lessonId) async {
    final response = await _api.dio.get<Map<String, dynamic>>('/learning/lessons/$lessonId');
    return response.data ?? const <String, dynamic>{};
  }

  /// Nộp kết quả làm bài tập để chấm điểm, nhận XP, streak và mở khóa bài tiếp
  Future<Map<String, dynamic>> submitLesson({
    required String lessonId,
    required int score,
    required int timeSpentSeconds,
  }) async {
    final response = await _api.dio.post<Map<String, dynamic>>(
      '/learning/lessons/$lessonId/submit',
      data: {
        'score': score,
        'time_spent_seconds': timeSpentSeconds,
      },
    );
    return response.data ?? const <String, dynamic>{};
  }
}
```

### 5.3. Thiết kế tầng `LearningRepository` & Cơ chế Fallback Không Gây Crash

Để các màn hình không phải xử lý phức tạp việc bắt ngoại lệ và ghép nối dữ liệu mẫu, ta xây dựng lớp `LearningRepository` đóng vai trò điều phối (Facade / Offline-First Fallback):

```
┌──────────────────────────────────────────────────────────────┐
│            UI (LearningPathPage / LessonPage)                │
└───────────────────────────────┬──────────────────────────────┘
                                │ Gọi dữ liệu qua Repository
                                ▼
┌──────────────────────────────────────────────────────────────┐
│                     LearningRepository                       │
│  - Thử tải từ Backend qua LearningApiService                 │
│  - Bắt mọi lỗi: Network Offline, HTTP 401/404/500, Timeout   │
│  - Tự động chuyển đổi mượt mà sang MockLearningRepository    │
└───────────────┬──────────────────────────────┬───────────────┘
                │ (Thành công)                 │ (Khi gặp lỗi)
                ▼                              ▼
┌───────────────────────────────┐  ┌───────────────────────────┐
│     Backend FastAPI (/api/v1) │  │  MockLearningRepository   │
│ (PostgreSQL, Streak, Activity)│  │ (Dữ liệu mẫu nội bộ RAM)  │
└───────────────────────────────┘  └───────────────────────────┘
```

#### Quy tắc an toàn (Zero-Crash Principles):
1. **Kiểm tra định dạng UUID:** Khi người dùng bấm vào bài học có ID là chuỗi mock (như `'unit1_lesson1'`), Repository không gọi Backend bằng ID không phải UUID (tránh gây lỗi 422 Unprocessable Entity trên FastAPI) mà nạp trực tiếp mock detail.
2. **Xử lý danh sách rỗng (Empty Fallback):** Nếu Backend kết nối thành công nhưng chưa có dữ liệu seed (trả về `[]` paths hoặc `[]` units), Repository tự động fallback sang `MockLearningRepository.instance.getUnits()`.
3. **Bộ chuyển đổi JSON Exercises linh hoạt (`ExerciseParser`):** Phân tích an toàn từng bài tập trong `content_data['exercises']`. Nếu có bài tập bị lỗi cấu trúc, ghi nhận log và bỏ qua hoặc bổ sung bài tập mẫu, đảm bảo `exercises` không bao giờ rỗng.

### 5.4. Kịch bản tích hợp vào `LearningPathPage`
1. Thay thế lời gọi đồng bộ `_repository.getUnits()` bằng cơ chế bất đồng bộ có trạng thái tải:
   - Thêm cờ `bool _isLoading = true;`
   - Trong `initState()`, gọi hàm `_loadData()`.
   - Trong `_loadData()`, gọi `await LearningRepository.instance.getUnits()`, cập nhật `_units`, điểm streak và XP.
   - Thao tác kéo để làm mới (`RefreshIndicator`) gọi lại `_loadData()` để đồng bộ với server.

### 5.5. Kịch bản tích hợp vào `LessonPage` & `LessonResultPage`
1. Tại `LessonPage`:
   - `initState()` kích hoạt `_loadLesson(widget.lessonId)`.
   - Hiển thị thanh vòng tròn tiến độ (`CircularProgressIndicator`) trong lúc chờ dữ liệu nạp từ Backend hoặc Mock.
   - Khi hoàn thành bài (`_finishLesson`):
     - Gọi `await LearningRepository.instance.submitLesson(...)`.
     - Lấy `streak_days` và `xp_earned` thật từ phản hồi của Backend truyền vào `LessonResult`.
     - Nếu submit thất bại (mất mạng khi nộp), ghi nhận vào mock repository cục bộ và vẫn cho phép người học xem kết quả bình thường.

---

## 6. KHẢO SÁT 5: CHIẾN LƯỢC KIỂM THỬ TỰ ĐỘNG FRONTEND (`flutter test`)

### 6.1. Hiện trạng tập tin kiểm thử mặc định
- **Tập tin:** `app_hoc_tieng_anh/test/widget_test.dart`
- **Hiện trạng:** Mã nguồn sinh tự động của mẫu Flutter Counter (`Counter increments smoke test`), tìm kiếm nút `Icons.add` và chuỗi `'0'`, `'1'`. Tập tin này hoàn toàn không tương thích với `LingoUpApp` (dùng Riverpod và GoRouter) và sẽ fail ngay khi chạy `flutter test`.

### 6.2. Kế hoạch bổ sung 3 bộ kiểm thử tự động đạt tiêu chuẩn nghiệm thu R4

#### Bộ kiểm thử 1: Smoke Test Ứng Dụng Khởi Tạo (`test/widget_test.dart`)
- Sửa lại test để bọc `LingoUpApp` bên trong `ProviderScope`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_hoc_tieng_anh/app/app.dart';

void main() {
  testWidgets('LingoUpApp smoke test - verifies initialization without crash', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: LingoUpApp(),
      ),
    );
    await tester.pump();
    expect(find.byType(LingoUpApp), findsOneWidget);
  });
}
```

#### Bộ kiểm thử 2: Kiểm thử URL Resolver & Path Normalizer (`test/core/network/app_api_test.dart`)
Kiểm tra toàn diện tất cả các ca biên (edge cases) của URL Normalizer theo yêu cầu nghiệm thu:
1. Đường dẫn thông thường bắt đầu bằng `/`: `'/auth/login'` -> `'/api/v1/auth/login'`.
2. Đường dẫn không có leading slash: `'auth/login'` -> `'/api/v1/auth/login'`.
3. Đường dẫn đã có sẵn `/api/v1`: `'/api/v1/learning/paths'` -> `'/api/v1/learning/paths'` (không bị duplicate thành `/api/v1/api/v1`).
4. Đường dẫn đặc biệt: `'/health'` -> `'/health'`.
5. Đường dẫn tuyệt đối: `'https://example.com/api'` -> `'https://example.com/api'`.
6. Base URL làm sạch hậu tố thừa: `'http://10.0.2.2:8000/api/v1/'` -> `'http://10.0.2.2:8000'`.

#### Bộ kiểm thử 3: Kiểm thử Repository Lộ trình học & Fallback Mock (`test/features/learning/learning_repository_test.dart`)
1. Kiểm tra khi API trả về lỗi kết nối mạng (SocketException / DioException) -> `LearningRepository` trả về dữ liệu mock hợp lệ gồm 3 units không bị ném ngoại lệ.
2. Kiểm tra khi nộp bài học offline -> điểm số XP và kết quả vẫn được tính toán và trả về `LessonResult` hợp lệ.

---

## 7. KẾ HOẠCH HÀNH ĐỘNG & DANH MỤC CÔNG VIỆC CHI TIẾT CHO IMPLEMENTER

| Bước | Hạng mục | Tập tin mục tiêu | Nội dung triển khai cụ thể |
|:---:|---|---|---|
| **1** | Bật Cleartext Traffic | `app_hoc_tieng_anh/android/app/src/main/AndroidManifest.xml` | Bổ sung `android:usesCleartextTraffic="true"` vào `<application>`. |
| **2** | Khai báo quyền iOS | `app_hoc_tieng_anh/ios/Runner/Info.plist` | Thêm `NSCameraUsageDescription`, `NSMicrophoneUsageDescription`, `NSPhotoLibraryUsageDescription`. |
| **3** | Chuẩn hóa Base URL | `app_hoc_tieng_anh/lib/core/config/app_config.dart` | Đặt default `API_BASE_URL` là `'http://10.0.2.2:8000'`, thêm hàm `cleanBaseUrl`. |
| **4** | Chuẩn hóa URL Resolver & Interceptor | `app_hoc_tieng_anh/lib/core/network/app_api.dart` | Bổ sung phương thức `normalizePath`, `resolveUrl`, thêm Request Interceptor tự động tiền tố `/api/v1`. |
| **5** | Hợp nhất HTTP Client Dio | `login_page.dart`, `register_page.dart`, `email_verification_page.dart`, `password_recovery_page.dart` | Thay thế các instance `Dio(...)` độc lập bằng `AppApi.instance.dio`. |
| **6** | Xây dựng Service Lộ trình học | `app_hoc_tieng_anh/lib/features/learning/data/learning_api_service.dart` | Tạo mới service gọi 4 endpoints `/learning/paths`, `/paths/{id}`, `/lessons/{id}`, `/submit`. |
| **7** | Xây dựng Repository & Offline Fallback | `app_hoc_tieng_anh/lib/features/learning/data/learning_repository.dart` | Tạo mới repository bọc `LearningApiService` và `MockLearningRepository`, phân giải 5 dạng bài tập. |
| **8** | Kết nối Giao diện Lộ trình | `app_hoc_tieng_anh/lib/features/learning/presentation/pages/learning_path_page.dart` | Thêm async data loader và `RefreshIndicator`, hiển thị dữ liệu từ repository. |
| **9** | Kết nối Giao diện Bài học | `app_hoc_tieng_anh/lib/features/learning/presentation/pages/lesson_page.dart` | Thêm loading state, gọi submit kết quả về Backend khi hoàn thành bài. |
| **10** | Viết Kiểm thử Tự động | `test/widget_test.dart`<br>`test/core/network/app_api_test.dart`<br>`test/features/learning/learning_repository_test.dart` | Sửa smoke test và bổ sung 2 file unit test kiểm tra URL resolver và fallback mock. |

