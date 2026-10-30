# modules/learning/

## Nghiệp vụ
Lộ trình học và lesson attempts, dùng được cả guest. Cung cấp `GET /path`, `GET /lessons/{id}`, `POST /lessons/{id}/complete`.

## Quy trình complete
1. Validate `attempt_id`, lesson, exercise IDs và timestamp.
2. Chống nộp trùng bằng idempotency/unique constraint; trả `ATTEMPT_ALREADY_SUBMITTED` theo contract.
3. Chấm server-side `image_choice`, `word_bank`, `listening`; speaking dùng score theo ngưỡng đã thống nhất; match_pairs theo quyết định thiết kế.
4. Độ chính xác dựa lần đầu; try > 1 ghi nhận nhưng không cộng vào first-try accuracy.
5. Cập nhật attempt/answers, mistakes, lesson progress, xp_ledger và daily_activity trong transaction.
6. Trả summary cần cho màn tổng kết và lesson tiếp theo.

## File dự kiến
Router/schema/service/repository/models tách theo luồng trên. Không tin XP, `is_correct` hoặc accuracy client nếu server phải tự chấm.
