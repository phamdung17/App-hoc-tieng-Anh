# features/profile/

Hồ sơ, thống kê được hiển thị cùng hồ sơ, cài đặt nhắc học/theme/âm thanh, đăng xuất và yêu cầu xóa tài khoản. Bao gồm giao diện 18.

## Plugin dự kiến

- `table_calendar`: hiển thị lịch streak theo tháng (giao diện 18).
- `flutter_local_notifications`: lên lịch nhắc học cục bộ theo giờ người dùng chọn.
- `firebase_messaging`: nhận push do Backend/FCM gửi; đăng ký token thiết bị theo API.
- `permission_handler`: xin quyền thông báo đúng thời điểm và mở Settings nếu người dùng đã từ chối.
- `cached_network_image`: ảnh avatar nếu ảnh được tải từ URL.

FCM và local notification có vai trò bổ trợ: FCM nhận thông báo từ server; local notification lên lịch nhắc trên máy. Không thêm OneSignal cùng lúc nếu chưa đổi kiến trúc.
