# core/

Hạ tầng và thành phần dùng chung giữa nhiều feature: cấu hình, mạng, lưu trữ, theme, lỗi và widget tổng quát. Chỉ đưa code vào đây khi thực sự được nhiều tính năng dùng; code riêng của một tính năng nên ở `features/`.

## Plugin dự kiến

- `flutter_secure_storage`: lưu access/refresh token an toàn; dùng từ auth/network, không tự lưu token bằng preferences.
- `permission_handler`: dùng cho permission flow chung (camera, microphone, notifications) và nút mở App Settings khi quyền bị từ chối vĩnh viễn.
- `shimmer`: skeleton loading dùng chung nếu nhiều feature cần cùng trạng thái tải.
- `flutter_animate`: hiệu ứng nhỏ dùng chung khi cần; tránh để animation package quyết định logic nghiệp vụ.

Chỉ thêm package khi tính năng tương ứng được triển khai. Các plugin Flutter phải được kiểm tra cấu hình Android/iOS và tương thích SDK trước khi cài.
