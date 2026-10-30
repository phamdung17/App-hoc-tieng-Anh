# Đặc tả giao diện 16–17: Ôn tập

## 16. Trung tâm ôn tập (Practice Hub)

**Mục tiêu:** chọn nhanh loại ôn cần làm và xem khối lượng đang chờ.

**Bố cục**
1. Hộp thư lỗi sai: số câu chờ, preview một số câu, nút **Ôn lại ngay**.
2. Luyện nghe nhanh: 10 câu từ các chặng đã học.
3. Luyện nói nhanh: 10 câu phát âm.
4. Flashcard ảnh cá nhân: số từ đến hạn ôn hôm nay và nút mở phiên.

**Hành vi**
- Tải danh sách lỗi sai và số từ đến hạn; empty state khi không có câu sai: **Tuyệt vời! Bạn không có câu sai nào tồn đọng**.
- Ôn lỗi sai mở lesson-style shell với các câu tương ứng. Khi trả lời đúng, backend cập nhật resolved state; sau refresh câu đã giải quyết biến mất.
- Luyện nghe/nói gọi endpoint practice với limit 10; ưu tiên câu sai nếu backend trả như vậy.
- Hoàn tất phiên gửi kết quả; XP/giới hạn phiên lấy từ response backend.
- Flashcard yêu cầu tài khoản đã xác minh theo backend; nếu không đủ quyền, hiển thị hướng đăng nhập/xác minh.

## 17. Flashcard và Quiz từ ảnh cá nhân

**Mục tiêu:** luyện nhớ từ đã lưu bằng lật thẻ hoặc kiểm tra chủ động.

**Bố cục**
- Thanh chuyển chế độ **Flashcard** / **Quiz**.
- Flashcard: mặt trước ảnh người dùng chụp; mặt sau từ, IPA, nghĩa, audio, câu ví dụ.
- Sau khi lật: ba nút **Quên**, **Hơi nhớ**, **Nhớ rõ**.
- Quiz: ảnh và bốn đáp án (một đúng, ba nhiễu) hoặc nhập từ.

**Hành vi và quy tắc**
- Lấy phiên và danh sách từ đến hạn từ backend; dùng `session_id`, `user_word_id` khi gửi câu trả lời.
- **Quên**: ôn lại ngay; **Hơi nhớ**: lịch theo quy tắc server; **Nhớ rõ**: lịch theo quy tắc server. FE không tự ghi ngày ôn.
- Quiz trắc nghiệm chỉ mở khi có tối thiểu 4 từ; dưới 4 từ cho lật thẻ và gõ từ.
- Sau mỗi đáp án, chuyển thẻ tiếp theo; có thể cho xem tiến độ phiên (ví dụ 3/10).
- Hoàn tất phiên gọi endpoint complete, hiển thị tổng kết/XP server trả về.
- Back hoặc đóng khi phiên dở dang cần dialog xác nhận theo yêu cầu FE.

**Trạng thái**
- Không có từ đến hạn: thông báo và nút quay về kho.
- 1–3 từ: quiz chọn đáp án disabled, giải thích cần tối thiểu 4 từ.
- Lỗi tải/nộp: giữ thẻ hiện tại và cho thử lại, tránh gửi câu trả lời trùng.
