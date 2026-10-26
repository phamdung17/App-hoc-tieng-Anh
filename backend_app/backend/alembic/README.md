# alembic/

## Mục đích
Quản lý phiên bản schema PostgreSQL bằng Alembic/SQLAlchemy. Migration mô tả thay đổi bảng/index/constraint có thể review và deploy lặp lại.

## Thành phần dự kiến
- `backend/alembic.ini`: đường dẫn migration và logging; DB URL nên lấy từ settings/environment, không hardcode secret.
- `alembic/env.py`: đọc metadata SQLAlchemy từ models, cấu hình offline/online migration và transaction behavior.
- `alembic/script.py.mako`: template tạo revision.
- `alembic/versions/`: migration tuần tự có revision ID.

## Quy trình phát triển
1. Thêm/chỉnh ORM model.
2. Sinh revision autogenerate.
3. Đọc và sửa migration thủ công; kiểm tra index, FK, unique, nullable, default và data migration.
4. Chạy `alembic upgrade head` trên DB dev trống và DB có dữ liệu test.
5. Commit revision; deploy migration trước app version cần schema mới.

Không dùng `Base.metadata.create_all()` thay Alembic trên môi trường production. Seed nội dung là bước riêng, không nhồi catalog lớn vào migration schema. Không sửa revision đã chạy ở shared/prod; tạo revision mới.
