# modules/review/

## Endpoints
`GET /review/session?limit=10`, `POST /review/answer`, `POST /review/session/{id}/complete`.

## Flow
Tạo session từ từ đến hạn, ưu tiên Leitner box thấp và từ có wrong_count cao. FE nộp `session_id`, `user_word_id`, `is_correct`; server xác minh quyền sở hữu và cập nhật review/box/date. Sai về box 1; đúng lên một box; khoảng cách theo tài liệu là 1/2/4/8/16 ngày.

## XP và tính nhất quán
Session complete mới chốt XP theo giới hạn mỗi loại/ngày; ledger unique chống cộng trùng. Attempt answer phải idempotent hoặc có kiểm tra session/item đã trả lời.

`review_sessions`, `word_reviews`, `user_words` được cập nhật trong transaction. Không nhận next_review_at do client gửi.
