# app/core/security/

## Phạm vi
Primitive bảo mật nền dùng lại bởi auth và dependencies. Không quyết định quyền nghiệp vụ theo endpoint ở đây.

## File dự kiến
- `passwords.py`: Argon2 hash/verify mật khẩu.
- `tokens.py`: ký/verify access JWT, tạo refresh/email token ngẫu nhiên, hash token trước khi lưu.
- `oauth.py`: verify credential token do Google/Apple gửi về server (nếu auth flow yêu cầu).

## Luồng token
Login phát access token ngắn hạn và refresh token dài hạn. Database giữ hash refresh token; logout thu hồi token hiện tại. Email verification/reset link chứa token một lần, lưu hash, có expiry và `used_at`.

## Ràng buộc
Không tự tin vào email/claims do client gửi. Không log mật khẩu, bearer token, reset link hay OAuth code. Đặt expiry/algorithm từ config; test sai chữ ký, hết hạn, revoked và token dùng lại.
