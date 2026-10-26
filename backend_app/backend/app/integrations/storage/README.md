# integrations/storage/

## Vai trò
Adapter S3-compatible cho R2/MinIO; tách bucket scan-private và content-public.

## Thao tác dự kiến
Upload scan, tạo presigned URL có hạn 1 giờ, upload crop lúc user lưu từ, xóa asset, kiểm tra object tồn tại. Key dùng ID khó đoán và không chứa email/tên cá nhân.

## Quy tắc
- Scan/photo người dùng luôn private; không public bucket.
- Content đã duyệt có thể phục vụ CDN/public.
- DB chỉ lưu object key, không lưu presigned URL vì URL hết hạn.
- Xóa tài khoản/scan cần xóa ảnh đồng bộ qua worker với retry.
- Validate content type/size trước upload; không tin extension do client gửi.
