# modules/auth/

## Nghiệp vụ
Email/password, Google/Apple social login, guest session, link account, guest merge, refresh/logout, verify email và forgot/reset password.

## Endpoints
`POST /auth/register`, `/login`, `/social`, `/guest`, `/link`, `/refresh`, `/logout`, `/verify-email`, `/resend-verification`, `/forgot-password`, `/reset-password`.

## File dự kiến
`router.py` nhận request; `schemas.py` định nghĩa payload/response; `service.py` xử lý quy trình; `repository.py` truy vấn users/tokens; có thể có `models.py` nếu auth tables không được sở hữu ở users module.

## Quy tắc quan trọng
- Guest được cấp user và token để tiến độ học cloud.
- Link guest thêm credential vào đúng user; login tài khoản thật có thể nhận `guest_token` để merge rồi xóa guest.
- Chỉ merge khi FE thể hiện đồng ý; merge dữ liệu phải transactional và idempotent.
- Email/password registration chưa được coi là verified đến khi xác minh; Google/Apple xác minh theo token server xác thực.
- Token trong DB lưu hash; resend/reset có rate limit và expiry.

## Kiểm tra
Test đăng ký trùng email, sai password, refresh/revoke, verify token hết hạn/dùng lại và guest merge.
