# integrations/mailer/

## Vai trò
Gửi email xác minh và reset mật khẩu qua Resend hoặc SMTP.

## File dự kiến
Provider adapter, template renderer và lỗi mail provider. Auth service tạo token, lưu hash/expiry; mailer chỉ nhận URL/token cần gửi.

## Quy tắc
- Không log URL có token, email body nhạy cảm hoặc credential.
- Timeout/retry hữu hạn; gửi lại có rate limit.
- Template nêu rõ mục đích và thời hạn; link phải trỏ đúng frontend/deep link đã cấu hình.
- Unit test render và integration test bằng mail sandbox/fake.
