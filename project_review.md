# Báo cáo trạng thái dự án

**Ngày rà soát:** 27/10/2026
**Phạm vi:** Flutter app, FastAPI backend, cấu hình chạy, tests và tài liệu trong repository.

## Kết luận

Dự án đã có nền backend và khung Flutter ban đầu, nhưng **chưa hoàn thành theo đặc tả và chưa được xác minh chạy end-to-end**. Phần backend hiện có auth, scan AI, users và một số API vocab. Flutter mới có theme, router và giao diện đăng nhập/đăng ký; chưa kết nối backend và phần lớn màn hình vẫn là placeholder.

Đặc tả kiến trúc feature-first và tách Flutter/backend vẫn là hướng phù hợp. Việc cần làm trước mắt là sửa cấu hình chạy backend, tạo migration đầu tiên, xác minh backend, rồi mới nối luồng auth Flutter.

## Tiến độ hiện tại

| Hạng mục | Trạng thái | Đã có |
|---|---|---|
| Cấu trúc dự án | Đang triển khai | Flutter và FastAPI tách riêng; mã backend chia `core`, `modules`, `integrations`, `workers`. |
| Backend nền tảng | Đã viết, chưa xác minh chạy | FastAPI app, settings, SQLAlchemy models, Redis client, exception handlers và cấu hình dependencies. |
| Auth backend | Đã triển khai một phần | Register, login, refresh, verify/resend email và endpoint thông tin user. |
| AI scan backend | Đã triển khai luồng tạo scan | Kiểm tra user/quota, xử lý ảnh, Gemini, storage private, lưu scan và trả kết quả. |
| Users backend | Đã triển khai cơ bản | Đọc/cập nhật profile, FCM token và xóa mềm tài khoản. |
| Vocab backend | Đã triển khai đọc | Liệt kê, tìm kiếm, xem chi tiết từ. Chưa có luồng quản lý kho từ cá nhân đầy đủ. |
| Integrations | Có code ban đầu | Gemini, S3-compatible storage, mailer và FCM adapter. Một số luồng cần credentials thật để chạy. |
| Background worker | Có khung và một số tác vụ | Có tác vụ dọn tài sản scan/user; chưa được nối hoàn chỉnh vào các luồng nghiệp vụ. |
| Database migration | Chưa hoàn thành | Chưa có migration version khởi tạo schema. |
| Flutter foundation | Đã có một phần | Riverpod dependency, ProviderScope, theme, GoRouter và cấu hình app. |
| Flutter auth UI | UI có, chưa nối API | Có màn đăng nhập/đăng ký; chưa có repository/network/token flow. |
| Các màn học, scan, ôn tập, profile | Chưa triển khai | Router còn dùng placeholder cho các màn này. |
| Kiểm thử | Có test, chưa xác nhận pass | Có unit test Gemini/storage và integration test scan; chưa chạy được trong lần rà soát này. |

## So với đặc tả

### Đã đi đúng hướng

- Flutter là client gọi REST API; backend giữ logic nghiệp vụ và gọi Gemini.
- Backend có kiểm tra email xác minh cho chức năng AI và giới hạn quota scan.
- Ảnh scan lưu ở object storage private; database lưu object key.
- Có phân lớp tính năng ở backend và dependency Riverpod/GoRouter ở Flutter.
- Scan dùng Gemini để nhận diện và trả dữ liệu từ vựng có cấu trúc.

### Còn thiếu so với mục tiêu sản phẩm

- Chưa có API learning/path/lesson/exercises, progress, review/SRS và practice.
- Chưa có đầy đủ scan history/detail, lưu từ scan, sửa nhãn và báo kết quả sai.
- Chưa có UI onboarding, lộ trình, bài học, 5 dạng bài tập, camera/kết quả scan, kho từ, flashcard, tiến độ và hồ sơ.
- Flutter chưa có API client, xử lý access/refresh token, secure token storage hay redirect theo trạng thái đăng nhập.
- Chưa có seed data bài học/bài tập và chưa có migration để dựng database mới.
- Các quy tắc XP, ngưỡng đánh giá speaking và cách sửa nhãn vẫn cần chốt thống nhất trước khi làm các luồng liên quan.

## Điểm cần xử lý trước khi chạy thử

### 1. Đường dẫn Docker Compose không khớp repository

`docker-compose.yml` nằm ở thư mục gốc nhưng đang dùng `./backend` cho build context, `.env` và volume. Backend thực tế ở `./backend_app/backend`. Cần sửa các đường dẫn trong Compose và hướng dẫn chạy cho khớp.

### 2. Chưa có migration database

Thư mục `backend_app/backend/alembic/versions/` chưa có migration thực thi. Cần tạo migration đầu tiên từ các model hiện tại và xác nhận `alembic upgrade head` tạo đủ bảng.

### 3. Cần xác minh scan và quota sau các thay đổi gần đây

Luồeng scan đã được sửa để trả itms, dọn ảnh khi xử lý lỗi và hoàn quota đúng key đã reserve. Cần có test xác nhận các trường hợp thành công, không có vật thể, Gemini lỗi, lỗi storage/DB và request đi qua nửa đêm.

### 4. Cấu hình chạy thật còn phụ thuộc dịch vụ ngoài

Backend cần `.env` hợp lệ, PostgreSQL, Redis, Gemini API key và thông tin S3/R2. Email verification cần Resend key để gửi thật; link xác minh hiện dùng domain mẫu nên cần cấu hình domain app trước khi phát hành.

## Thứ tự triển khai tiếp theo

### Bước 1 — Làm cho backend có thể khởi động lặp lại

1. Sửa đường dẫn Compose sang `backend_app/backend`.
2. Tạo `.env` local từ `.env.example`, không đưa secrets vào Git.
3. Tạo migration đầu tiên và chạy migration trên database sạch.
4. Kiểm tra `/health`, auth và kết nối database/Redis.

**Hoàn tất khi:** Compose build được, các service healthy và migration tạo schema thành công.

### Bước 2 — Chạy và củng cố backend tests

1. Chạy toàn bộ unit tests.
2. Chạy integration tests với database/Redis test hoặc mocks được override đúng cách.
3. Bổ sung assertions cho status code và response body của scan success; thêm ca no-object, quota, email chưa xác minh và lỗi Gemini/storage.
4. Sửa lỗi phát hiện được trước khi bắt đầu nối Flutter.

**Hoàn tất khi:** test suite chạy ổn định trong môi trường có dependency, không dựa vào API key/dịch vụ production.

### Bước 3 — Hoàn thiện Flutter auth và nền tảng mạng

1. Tạo API client và chuẩn hóa lỗi theo response backend.
2. Tạo secure token storage và luồng refresh token.
3. Tạo auth repository/provider, nối login/register/verify.
4. Thêm redirect theo trạng thái chưa đăng nhập, chưa xác minh và đã xác minh.
5. Kiểm tra đăng nhập từ Flutter tới backend local/dev.

**Hoàn tất khi:** người dùng có thể đăng ký, đăng nhập, giữ phiên và đăng xuất qua app.

### Bước 4 — Chốt hợp đồng nghiệp vụ và hoàn thiện API

1. Chốt cách tính XP, ngưỡng speaking và quy tắc sửa nhãn.
2. Triển khai learning/content và tiến độ trước để Flutter có dữ liệu học.
3. Triển khai scan history/detail và các thao tác lưu/báo/sửa theo đặc tả.
4. Triển khai review/SRS, practice và notification sau khi các model/luồng học đã ổn định.

### Bước 5 — Làm UI theo thứ tự phụ thuộc

1. Welcome/onboarding và auth.
2. Learning path, lesson shell, 5 dạng bài tập và kết quả.
3. Camera scan và màn kết quả.
4. Kho từ, flashcard/review, profile/progress.
5. Bổ sung trạng thái loading/error/empty, quyền camera/micro và polish.

## Tình trạng kiểm tra tại lần rà soát này

- `git diff --check` sạch ở commit gần nhất `06bdbb3`.
- Chưa xác nhận được backend tests, Python runtime hoặc Docker Compose: Python/Docker CLI không có trong PATH của môi trường rà soát.
- Đã thử `flutter analyze`, nhưng lệnh không trả kết quả trong hơn hai phút và đã dừng; chưa có kết luận analyzer hoặc widget test pass.
- Vì vậy trạng thái “đã triển khai” trong bảng mô tả **code đã có**, không đồng nghĩa đã xác nhận chạy ổn định.

## Tài liệu cần giữ đồng bộ

- Cập nhật [weekly_implementation_plan.md](weekly_implementation_plan.md) khi hoàn thành từng bước ở trên.
- Cập nhật [FIleMap.md](app_hoc_tieng_anh/FIleMap.md) và README của backend khi cấu trúc/API thay đổi.
- Không đánh dấu một phase hoàn thành cho tới khi có migration, test và luồng chạy được tương ứng.
