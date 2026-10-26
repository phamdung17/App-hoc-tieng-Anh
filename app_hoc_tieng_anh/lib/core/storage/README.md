# core/storage/

Lưu dữ liệu cục bộ dùng chung. Token cần lưu bằng giải pháp lưu trữ an toàn; tùy chọn không nhạy cảm có thể dùng preferences. Dữ liệu nghiệp vụ chính như XP và quota phải lấy từ backend.

## Plugin dự kiến

- `flutter_secure_storage` dành cho token phiên.
- `permission_handler` có thể được gọi qua permission service ở tầng app/core; từng feature vẫn chịu trách nhiệm giải thích lý do xin quyền.
- Không lưu XP, streak, quota scan hoặc kết quả bài học làm nguồn dữ liệu chính ở local storage; các dữ liệu đó do Backend quản lý.
