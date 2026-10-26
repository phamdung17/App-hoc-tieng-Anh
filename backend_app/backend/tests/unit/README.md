# tests/unit/

Test thuần các hàm/service với dependency repository, detector, mailer, storage và FCM được giả lập. Không cần server chạy.

Ưu tiên boundary cases: quota đúng ngưỡng, timezone qua nửa đêm, token hết hạn, first-try accuracy, score ngay trên/dưới ngưỡng, duplicate attempt, review sai về box 1 và XP cap. Mỗi test đặt tên theo điều kiện và kết quả mong đợi.
