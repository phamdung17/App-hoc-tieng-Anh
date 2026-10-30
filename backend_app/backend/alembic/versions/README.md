# alembic/versions/

## Vai trò
Lưu từng revision migration. Mỗi file định nghĩa `revision`, `down_revision`, `upgrade()` và `downgrade()`.

## Nội dung migration của app dự kiến
Các nhóm bảng: users/profiles/tokens, course/unit/lesson/exercise, attempts/answers/progress/mistakes/activity/xp ledger, words/scans/scan items/user words/reviews, notifications/device tokens.

## Quy ước
- Một revision tập trung vào một thay đổi logic có tên dễ hiểu.
- Autogenerate chỉ là bản nháp; review constraint/index và thứ tự thao tác.
- Bảng lớn: tránh lock dài; nullable → backfill → constraint theo nhiều bước nếu cần.
- Downgrade phải có chủ đích; không xóa dữ liệu người dùng ngoài ý muốn.
- Không commit migration chứa URL/credential hoặc dữ liệu cá nhân.

Kiểm tra chain `alembic history` và chạy upgrade từ base trước khi merge.
