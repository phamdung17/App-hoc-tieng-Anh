# Đặc tả giao diện 14–15: Kho từ vựng

## 14. Kho từ vựng hình ảnh

**Mục tiêu:** duyệt, tìm và lọc các từ người dùng đã lưu; đưa người dùng vào ôn tập.

**Bố cục**
- Tiêu đề **Kho từ của tôi** và tổng số từ.
- Search hỗ trợ tìm tiếng Anh/Việt.
- Chip chủ đề (Tất cả, Đồ gia dụng, Đồ ăn, Học tập...) và mức độ thuộc (Mới lưu, Đang học, Đã thuộc).
- Lưới 2 cột: ảnh, từ tiếng Anh, nghĩa tiếng Việt, nút loa nhỏ, chấm màu mastery.
- Nút nổi **Ôn tập kho từ của tôi**.

**Hành vi**
- Tải trang đầu và phân trang cursor khi cuộn; debounce tìm kiếm để không gọi API mỗi ký tự.
- Thay đổi query/filter đặt lại cursor và tải kết quả mới.
- Chạm card mở giao diện 15; loa phát âm không điều hướng.
- Kho trống: linh vật, nội dung khuyến khích và nút **Chụp đồ vật đầu tiên ngay** sang 12.
- Lỗi tải: giữ filter, hiện thử lại; ảnh lỗi dùng placeholder.
- Nút ôn tập vào giao diện 17 hoặc 16 tùy flow; nếu không đủ từ làm quiz, vẫn cho flashcard/gõ từ theo quy định.

## 15. Chi tiết từ vựng

**Bố cục**
- Ảnh đồ vật lớn; nút sửa và xóa ở góc.
- Từ tiếng Anh lớn, IPA, từ loại; nút nghe chuẩn và nghe chậm.
- Nghĩa Việt, câu ví dụ tiếng Anh và bản dịch.
- Mức độ thuộc (ví dụ cấp 3/5, ngày ôn tiếp theo).
- Khu vực ghi chú cá nhân để thêm/sửa ghi chú.

**Hành vi**
- Sửa mở form điền nội dung; validate trước khi PATCH.
- Xóa yêu cầu xác nhận, sau thành công quay về kho và refresh số lượng.
- Lưu ghi chú có loading và phản hồi thành công/lỗi; tránh mất nội dung khi API tạm lỗi.
- Ngày ôn và mastery lấy từ backend; không tự cập nhật lịch SRS ở giao diện này.
- Presigned URL ảnh có thể hết hạn; nếu tải ảnh lỗi thì yêu cầu dữ liệu mới theo ID.

**Tiêu chí hoàn thành chung**
- Loading, empty, error, loaded được phân biệt.
- Tìm kiếm/filter không hiển thị nhầm kết quả cũ sau khi request mới hoàn thành.
- Chặn quyền kho từ cho tài khoản không được phép theo trạng thái backend.
