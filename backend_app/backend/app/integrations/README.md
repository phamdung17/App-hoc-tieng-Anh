# app/integrations/

Adapter cho dịch vụ ngoài; module service gọi qua integrations thay vì chứa SDK/provider-specific code.

- `gemini_client/` (hiện scaffold cũ còn ở `detector/`): image recognition + structured word card, một API call.
- `storage/`: S3-compatible private/public buckets, presigned URLs, crop lúc save.
- `mailer/`: xác minh email/reset password.
- `fcm/`: gửi push qua Firebase Cloud Messaging.

Cấu hình lấy từ `core/config`; timeout và provider errors được map sang lỗi nội bộ. Không log ảnh, token, API keys hoặc dữ liệu nhạy cảm. Gemini key chỉ tồn tại ở server.
