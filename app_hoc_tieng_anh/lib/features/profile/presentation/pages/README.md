# Đặc tả giao diện 18: Hồ sơ, Thống kê và Cài đặt

## 18. Hồ sơ, Thống kê và Cài đặt

**Mục tiêu:** xem thông tin cá nhân/tiến độ và điều chỉnh trải nghiệm học.

**Bố cục cuộn dọc**
1. **Thông tin cá nhân:** ảnh đại diện, tên hiển thị, email, ngày bắt đầu học.
2. **Thống kê:** ba thẻ streak hiện tại, tổng XP, tổng số từ ảnh đã lưu.
3. **Lịch streak:** calendar heatmap, ngày có học/ôn được tô màu cam.
4. **Cài đặt:** giờ nhắc học, mục tiêu 5/10/15/20 phút, giao diện sáng/tối, hiệu ứng âm thanh, đăng xuất, xóa tài khoản.

**Hành vi**
- Tải profile từ `/me`, số liệu từ progress summary, lịch từ progress calendar theo tháng.
- Đổi mục tiêu/theme/âm thanh lưu và báo thành công; mục tiêu ngày đồng bộ backend. Theme/âm thanh có thể áp dụng tức thì và lưu cục bộ để phản hồi nhanh.
- Chọn giờ nhắc: mở time picker; khi bật nhắc, xin quyền thông báo sau khi giải thích lý do, rồi đăng ký lịch local/push theo kiến trúc đã chọn. Khi tắt, hủy lịch tương ứng.
- Đổi tháng lịch: tải dữ liệu tháng mới; hiển thị loading nhẹ, ngày không hoạt động giữ nền mặc định.
- **Đăng xuất:** xác nhận nếu cần, gọi `/auth/logout` để thu hồi refresh token, xóa token cục bộ và điều hướng về welcome.
- **Xóa tài khoản:** chữ đỏ; xác nhận hai bước, gọi DELETE `/me`, thông báo kết quả và xóa phiên khi backend xác nhận.

**Trạng thái và lỗi**
- Guest có thể không có email/avatar; hiển thị nội dung phù hợp và CTA tạo/liên kết tài khoản.
- Lỗi tải từng vùng không nhất thiết làm hỏng cả trang; có thể thử lại profile hoặc calendar riêng.
- Nếu quyền thông báo bị từ chối vĩnh viễn, cung cấp nút mở cài đặt hệ thống.

**Tiêu chí hoàn thành**
- Giá trị được chọn khớp giá trị sau khi tải lại app.
- Ngày streak dựa trên timezone người dùng/backend, không tự quy đổi theo UTC ở client.
- Xóa tài khoản không giả lập thành công trước khi server chấp nhận yêu cầu.
