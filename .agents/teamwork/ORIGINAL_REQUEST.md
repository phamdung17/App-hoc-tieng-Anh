# Original User Request

## Initial Request — 2026-11-03T13:47:30Z

Hoàn thiện dự án học tiếng Anh LingoUp (cả Frontend Flutter và Backend FastAPI) theo kết quả và lộ trình trong AUDIT_REPORT.md để đưa vào môi trường thực tế (production), bao gồm khắc phục các lỗi chặn P0, giải quyết các khoảng cách kiến trúc P1/P2, thiết lập dữ liệu mẫu và bổ sung các bài kiểm thử tự động.

Working directory: d:\LapTrinhMoBa\do_an_moba
Integrity mode: development

## Requirements

### R1. Khắc phục triệt để các lỗi chặn P0
- Sửa lỗi nạp `CORS_ORIGINS` trong `backend_app/backend/app/core/config/settings.py` để không gây lỗi JSONDecodeError khi khởi động Backend từ biến môi trường `.env`.
- Chuẩn hóa cấu hình base URL và đường dẫn gọi API trong Frontend (`app_config.dart`, `AppApi`, và các service liên quan) để các request không bị mất tiền tố `/api/v1` dẫn đến lỗi 404 theo chuẩn RFC 3986.
- Bổ sung cấu hình `android:usesCleartextTraffic="true"` vào `app_hoc_tieng_anh/android/app/src/main/AndroidManifest.xml` để cho phép kết nối HTTP cục bộ.
- Sửa file `docker-compose.yml` trỏ chính xác vào ngữ cảnh thư mục `backend_app/backend` và file `.env` tương ứng.

### R2. Khắc phục các khoảng cách kiến trúc P1 & P2
- Xây dựng `learning_api_service.dart` và tích hợp vào các màn hình lộ trình học (`learning_path_page.dart`) và chi tiết bài học (`lesson_page.dart`) trên Frontend, kèm cơ chế fallback dữ liệu mẫu an toàn khi không thể kết nối Backend.
- Cập nhật hàm `submit_lesson` trong Backend `app/modules/learning/service.py` để gọi `ProgressService.record_activity`, đảm bảo ghi nhận hoạt động vào `user_daily_activities` và cập nhật chính xác chuỗi ngày học Streak cùng biểu đồ học tập.
- Chuẩn hóa cấu hình dialect trong `alembic/env.py` để lệnh migration CSDL chạy ổn định không bị xung đột giữa sync psycopg2 và asyncpg.
- Bổ sung các quyền phần cứng cần thiết trong `ios/Runner/Info.plist`: camera (`NSCameraUsageDescription`), microphone (`NSMicrophoneUsageDescription`) và thư viện ảnh (`NSPhotoLibraryUsageDescription`).

### R3. Tạo dữ liệu mẫu (Seed Data)
- Tạo kịch bản hoặc cơ chế nạp dữ liệu mẫu ban đầu (seed data) gồm: 1-2 lộ trình học (Learning Paths), mỗi lộ trình có 2-3 Units, các bài học mẫu kèm đầy đủ các dạng bài tập tương tác, và 20-30 từ vựng theo chủ đề vào cơ sở dữ liệu.

### R4. Xây dựng kiểm thử tự động (Automated Verification)
- Xây dựng bài kiểm thử tự động (pytest) cho Backend kiểm tra các luồng xác thực, nạp cấu hình, di chuyển lược đồ, API bài học và cập nhật streak khi hoàn thành bài học.
- Xây dựng bài kiểm thử tự động (flutter test) cho Frontend kiểm tra URL resolver của `AppApi`, service gọi API bài học và cơ chế fallback mock.

## Acceptance Criteria

### Khắc phục lỗi P0 & Cấu hình môi trường
- [ ] Backend khởi động bình thường không gặp ngoại lệ `JSONDecodeError` khi đọc `CORS_ORIGINS` từ file cấu hình môi trường.
- [ ] Mọi yêu cầu API từ Frontend gửi tới Backend giữ nguyên prefix `/api/v1` và không trả về mã lỗi HTTP 404 do định dạng URI.
- [ ] File `app_hoc_tieng_anh/android/app/src/main/AndroidManifest.xml` có thuộc tính `android:usesCleartextTraffic="true"`.
- [ ] File `app_hoc_tieng_anh/ios/Runner/Info.plist` khai báo đầy đủ các khóa quyền camera, microphone và photo library.
- [ ] Cấu hình `docker-compose.yml` build thành công dịch vụ từ thư mục `backend_app/backend`.

### Tích hợp Lộ trình học & Tiến độ
- [ ] Phân hệ Lộ trình học trên Frontend (`learning_path_page.dart`, `lesson_page.dart`) hiển thị dữ liệu bài học lấy từ Backend qua `learning_api_service.dart` khi có kết nối mạng, và tự động chuyển sang mock data nếu kết nối thất bại mà không làm crash ứng dụng.
- [ ] Nộp bài học qua endpoint `POST /lessons/{id}/submit` tạo bản ghi mới trong bảng `user_daily_activities` và cập nhật tăng số ngày streak của người dùng.
- [ ] Lệnh `alembic upgrade head` thực thi thành công từ đầu đến migration mới nhất mà không gặp lỗi dialect.

### Dữ liệu mẫu (Seed Data)
- [ ] Cơ sở dữ liệu chứa ít nhất 1 lộ trình học với tối thiểu 2 Units, các bài học chứa các dạng bài tập tương tác hợp lệ, và ít nhất 20 từ vựng theo chủ đề sẵn sàng sử dụng.

### Kiểm thử tự động (Automated Verification)
- [ ] Bộ kiểm thử `pytest` cho Backend chạy pass 100% các ca kiểm thử mới được bổ sung.
- [ ] Bộ kiểm thử `flutter test` cho Frontend chạy pass 100% các ca kiểm thử mới được bổ sung.
