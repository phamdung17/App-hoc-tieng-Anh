# tests/fixtures/

Dữ liệu/factory phục vụ test: guest, verified user, lesson/exercise từng type, scans/quota, words và review cards. Fixture phải nhỏ, deterministic, độc lập seed production.

Không chứa email/password thật, JWT dùng thật, ảnh người dùng hoặc credentials. Dùng factory tạo state theo test để tránh phụ thuộc thứ tự chạy.
