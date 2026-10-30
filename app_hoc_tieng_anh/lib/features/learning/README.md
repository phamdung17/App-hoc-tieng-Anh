# features/learning/

Lộ trình, nội dung bài học, tiến trình làm bài, phản hồi và tổng kết. Bao gồm giao diện 04–11. Lesson shell dùng chung điều phối các dạng bài thay vì lặp lại thanh tiến trình và logic phản hồi ở từng bài tập.

## Plugin dự kiến

- `speech_to_text`: nhận dạng giọng nói cho giao diện 09; dùng cho một lượt nói ngắn, không phải thu âm nền liên tục.
- `flutter_tts`: phát âm từ/câu mẫu cho bài tập.
- `just_audio`: chỉ dùng nếu bài nghe có audio thu sẵn. Nếu dùng TTS cho câu seed, không cần audio player ở bước đầu.
- `flutter_animate`: hiệu ứng phản hồi/hoàn thành; `shimmer` có thể dùng khi tải nội dung.
- `cached_network_image`: ảnh lựa chọn trong bài tập nếu lấy từ Backend/CDN.

Ngưỡng speaking cần thống nhất giữa FE và BE (75% trong FE, 0.6 trong BE) trước triển khai. Bài nghe/nói là bài tập seed sẵn; các plugin chỉ phát hoặc nhận dạng nội dung đó.
