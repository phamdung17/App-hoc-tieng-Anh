# app/

## Vai trò
Gói Python của ứng dụng FastAPI. Đây là nơi đặt endpoint, nghiệp vụ, truy cập dữ liệu và tích hợp backend.

## File dự kiến ở cấp app
- `main.py`: khởi tạo app, đăng ký router `/api/v1`, middleware, CORS phù hợp môi trường, exception handlers và `/health`.
- `api.py` hoặc `api/v1/router.py`: gom router module; dùng một prefix/version nhất quán.
- `database.py` (nếu không nằm trong core): engine/session factory; chọn một vị trí duy nhất để tránh cấu hình DB trùng.

## Quy tắc phụ thuộc
`main` lắp các thành phần, router điều phối HTTP, service chứa use case, repository thao tác DB, integration gọi hệ thống ngoài. Tránh vòng phụ thuộc giữa modules; chia sẻ helper ở core hoặc interface trung lập.

Các thư mục con có README giải thích trách nhiệm chi tiết. Không đặt migration Alembic trong `app/`; migration ở `backend/alembic/`.
