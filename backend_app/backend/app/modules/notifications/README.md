# modules/notifications/

## Phạm vi
Đăng ký token thiết bị và điều phối cài đặt nhắc học; endpoint user device token là `POST /me/device-token`. Push được gửi qua FCM integration/worker.

## Quy tắc nhắc học
Worker chạy mỗi 15 phút, so `reminder_time` theo timezone user, chỉ gửi nếu chưa có activity hôm nay và có device token. Nội dung nhắc liên quan chụp vật thể chỉ gửi verified member.

## Bảo mật/vận hành
Token FCM gắn user/device/platform; xử lý token invalid và hủy token. Không gửi notification khi permission chưa cấp nếu client cung cấp trạng thái đó. Không lưu service credential trong module hoặc trả token cho user khác.
