# integrations/fcm/

## Vai trò
Gửi push từ Backend tới app Flutter bằng Firebase Cloud Messaging.

## File dự kiến
`client.py` khởi tạo SDK/server credential, `schemas.py` kiểu message và `errors.py` map lỗi gửi.

## Quy tắc
Credential chỉ ở môi trường server. Notification worker nhận user/device payload, gửi qua adapter và xử lý token invalid bằng disable/delete. Gửi batch có giới hạn; không đưa nội dung nhạy cảm vào lock screen payload.
