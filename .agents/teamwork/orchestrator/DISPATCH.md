## 2026-11-03T12:27:51Z

Kiểm tra và đánh giá toàn diện tiến độ, chất lượng dự án học tiếng Anh gồm Frontend Flutter và Backend FastAPI theo tiêu chuẩn đồ án môn học / tốt nghiệp, lập báo cáo phân tích chi tiết các phần đã hoàn thiện và các phần còn thiếu mà không sửa đổi mã nguồn.

Working directory: d:\LapTrinhMoBa\do_an_moba
Integrity mode: development

## Requirements

### R1. Rà soát hiện trạng và đối chiếu tính năng Frontend - Backend
Kiểm tra toàn bộ mã nguồn Backend FastAPI (`backend_app/backend/`) và Frontend Flutter (`app_hoc_tieng_anh/`), bao gồm các module đã triển khai: auth (social Google), scan (Gemini AI), users, vocab, learning, progress, migrations và các màn hình bài tập / practice hub / camera / profile. Đối chiếu sự tương thích và đồng bộ giữa các API endpoints của Backend với các service gọi API của Frontend.

### R2. Đánh giá chất lượng và tiến độ theo tiêu chuẩn đồ án
Đánh giá mức độ hoàn thiện của từng luồng nghiệp vụ (user flows) phục vụ kịch bản demo và bảo vệ đồ án, độ ổn định của kiến trúc, xử lý lỗi (error handling, token refresh) và chất lượng mã nguồn. Xác định rõ ràng các chức năng đã hoàn thiện đạt yêu cầu, các chức năng còn dang dở, và các chức năng còn thiếu cần bổ sung.

### R3. Lập báo cáo kiểm tra chi tiết (Project Audit & Gap Analysis Report)
Xuất một tài liệu báo cáo kiểm tra toàn diện bằng Markdown lưu tại thư mục gốc của dự án (`AUDIT_REPORT.md`). Báo cáo phải bao gồm: bảng tổng hợp tiến độ từng module/màn hình, ma trận đối chiếu API Backend và Frontend (đã kết nối, thiếu kết nối, lệch schema), danh sách các lỗi tiềm ẩn/thiếu sót phát hiện được, và danh sách các hạng mục khuyến nghị ưu tiên cần làm tiếp trước khi bảo vệ đồ án. Không thực hiện chỉnh sửa hoặc can thiệp vào mã nguồn dự án hiện tại.

## Acceptance Criteria

### Tính toàn diện của báo cáo đánh giá
- [ ] Báo cáo `AUDIT_REPORT.md` được tạo tại thư mục gốc dự án và ghi nhận đầy đủ hiện trạng của toàn bộ các module Backend (`backend_app/backend/`) và Frontend (`app_hoc_tieng_anh/`) được liệt kê trong yêu cầu.
- [ ] Có bảng ma trận đối chiếu giữa các API endpoint backend (auth, scan, users, vocab, learning, progress) và các service client frontend tương ứng, chỉ rõ trạng thái kết nối và sự sai lệch nếu có.
- [ ] Phân định rõ ràng thành các mục riêng biệt: các phần đã hoàn thiện đạt yêu cầu, các phần chưa hoàn thiện hoặc chưa đồng bộ, và các phần còn thiếu cho một đồ án tốt nghiệp/môn học hoàn chỉnh.

### Kiểm định khách quan và tính toàn vẹn mã nguồn
- [ ] Báo cáo chỉ ra được các lỗi cú pháp, lint, type check hoặc import issue (nếu có) thông qua phân tích tĩnh hoặc chạy công cụ kiểm tra của dự án (ví dụ: `pytest`, `flutter analyze` hoặc kiểm tra cú pháp).
- [ ] Không có file mã nguồn nào của dự án (ngoại trừ file báo cáo `AUDIT_REPORT.md`) bị thay đổi nội dung.


## 2026-11-03T13:48:39Z

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
