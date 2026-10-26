# modules/users/

## Nghiệp vụ
Hồ sơ và cấu hình người dùng; endpoint `GET/PATCH /me`, `DELETE /me`, đăng ký device token và timezone.

## Dữ liệu
`users`, `user_profiles`, `device_tokens` và metadata phục vụ deletion. `/me` trả `is_guest`, trạng thái email verification, display profile, mục tiêu, level, phút/ngày, reminder, sound/theme.

## Trách nhiệm service
Validate lựa chọn khảo sát/cài đặt; cập nhật timezone; gắn FCM token theo thiết bị; soft-delete ngay và xếp job xóa hẳn sau 30 ngày. Không trả password hash/token hash.

## Ranh giới
Auth sở hữu quy trình credential/session; users sở hữu profile/settings. Progress sở hữu summary/activity, scan sở hữu AI quota.
