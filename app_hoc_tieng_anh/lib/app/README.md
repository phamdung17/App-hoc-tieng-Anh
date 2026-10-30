# app/

Cấu hình và khung điều hướng cấp ứng dụng: `MaterialApp`, router, theme/locale wiring và shell chứa các tab chính. Thư mục này kết nối các feature, không chứa nghiệp vụ riêng như xử lý bài học hoặc quét ảnh.

## Plugin dự kiến

- `cached_network_image`: ảnh minh họa bài học từ CDN/backend; với signed URL, tải lại URL hết hạn theo ID nội dung.
- `flutter_animate`: hiệu ứng linh vật/ăn mừng/feedback nếu cần.
- `shimmer`: skeleton khi tải lộ trình và nội dung bài.

Bottom navigation hiện có thể dùng `NavigationBar` của Flutter; chưa cần thêm `convex_bottom_bar`.
