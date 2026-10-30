# modules/content/

## Nghiệp vụ
Cung cấp catalog đọc cho người học: courses → units → lessons → exercises và từ điển `words`. Nội dung bài học là dữ liệu seed do đội ngũ biên soạn/duyệt; scan AI không tự tạo hoặc sửa lesson/exercise.

## Dữ liệu
- `courses`, `units`, `lessons`, `exercises` (`content` JSONB), `lesson_words`.
- `words`: catalog từ được seed trước, cộng các word cards Gemini cache phát sinh từ scan.
- Ảnh/audio lesson tham chiếu `content-public`/CDN.

## Quy tắc word catalog
Khi Gemini trả lemma đã có, dùng card hiện có, không ghi đè nội dung đã duyệt/cached. Lemma mới được validate rồi lưu thành cache dùng chung để scan sau tái sử dụng. Phân biệt provenance seed và Gemini cache khi cần quản lý/chỉnh sửa dữ liệu. Word cache không phải nội dung khóa học và không thay thế seed 300–500 từ nền.

## File dự kiến
`models.py`, `schemas.py`, repository/service đọc catalog, validator exercise theo 5 type và loader seed riêng. Scan service có thể gọi content repository/service để tìm hoặc tạo cache word; tránh vòng phụ thuộc bằng interface/use case trung lập.

## Ranh giới và bảo vệ đáp án
Content định nghĩa đáp án và payload chuẩn; learning quyết định mở bài, attempt và submit. Với dạng server tự chấm, endpoint lesson không trả answer key. Không gọi LLM khi tải bài hoặc tạo course.
