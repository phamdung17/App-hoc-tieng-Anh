# features/scan/

Chụp/chọn ảnh, upload tới Backend, xem nhãn/thẻ từ Gemini, sửa/báo sai và lưu vào kho. Bao gồm giao diện 12–13. Gemini API key và xử lý model chỉ ở Backend; Flutter không gọi Gemini trực tiếp.

## Luồng AI hiện tại
Flutter lấy quota → chụp/chọn/nén ảnh khoảng 200 KB → POST multipart `/scans` → Backend validate ảnh/quota rồi gọi Gemini một lần cho vật thể + thẻ từ → Backend validate JSON và trả bbox/card → FE vẽ box và hiển thị kết quả. Thời gian thường 2–6 giây tùy mạng; UI cần progress và timeout khoảng 30 giây.

Từ mới Gemini tạo được cache dùng chung trong `words`; đây là dictionary cache từ scan, không phải sinh bài học. Content bài học vẫn được seed sẵn.

## Plugin dự kiến
- `camera`, `image_picker`, `flutter_image_compress`, `cached_network_image`, `permission_handler`.

Không dùng YOLO/ML Kit/TFLite/OpenCV client-side cho luồng scan hiện tại. Backend gửi ảnh sang Google; cần thông báo quyền riêng tư phù hợp.
