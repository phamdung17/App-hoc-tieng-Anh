# seed_data/courses/

## Nội dung
Courses, ordered units, ordered lessons, level gating, grammar tips, sample sentence, XP reward và danh sách liên kết lesson_words.

## Cấu trúc đề xuất
Mỗi course có stable slug; unit/lesson có order number và IDs ổn định. Trình độ mở sẵn xác định theo profile level ở service `/path`, nhưng trạng thái cuối cùng do backend trả.

## Kiểm duyệt
Đảm bảo prerequisite không tạo vòng lặp, lesson order liên tục, grammar tip ngắn và khớp exercise. Nội dung bài cập nhật phải version/migration cẩn thận để attempt cũ còn đọc được.
