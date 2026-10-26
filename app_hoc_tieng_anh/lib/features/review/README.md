# features/review/

Ôn câu sai, luyện nhanh nghe/nói và flashcard/quiz từ ảnh cá nhân. Bao gồm giao diện 16–17. Backend quyết định lịch spaced repetition và XP được cấp.

## Plugin dự kiến

- `cached_network_image`: ảnh mặt trước của flashcard nếu ảnh đến từ backend.
- `flutter_tts`: phát âm từ ở mặt sau.
- `just_audio`: chỉ khi review có audio thu sẵn; không cần thêm nếu chỉ dùng TTS.

Lịch Leitner/SRS và thời điểm ôn tiếp theo do Backend trả về; plugin/UI không tự tính lịch.
