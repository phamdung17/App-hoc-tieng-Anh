# app/seed_data/

## Mục đích
Nguồn dữ liệu nội dung do đội ngũ quản lý. Đây là dữ liệu tĩnh được seed trước khi app sử dụng, không phải generator lúc runtime.

## Quy trình
1. Biên soạn CSV/JSON/YAML và validate schema.
2. Duyệt chính tả, cấp độ, answer key, dịch Việt và quyền sử dụng media.
3. Gán stable IDs/slugs và version.
4. Chạy loader trong môi trường dev/staging; kiểm tra quan hệ FK và unique keys.
5. Deploy seed có kiểm soát; không xóa/sửa progress người dùng.

Tách `words/`, `courses/`, `exercises/`. Ghi provenance/license bên cạnh data hoặc metadata fields. API content chỉ đọc DB đã seed.
