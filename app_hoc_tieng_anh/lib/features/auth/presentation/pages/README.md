# Đặc tả giao diện 01–03: Khởi động và tài khoản

Tài liệu này cụ thể hóa ba giao diện đầu của đặc tả FE. Các tên control là yêu cầu chức năng; hình minh họa, màu và animation có thể hoàn thiện theo design system.

## 01. Chào mừng (kèm Splash)

**Mục tiêu:** khởi tạo app, kiểm tra phiên đăng nhập và đưa người dùng đến đúng luồng.

**Thành phần UI**
- Logo và linh vật ở giữa; có animation ngắn khoảng 1–1,5 giây trong lúc kiểm tra phiên.
- Khi chưa có phiên: khẩu hiệu, nút chính **Bắt đầu ngay**, nút phụ **Tôi đã có tài khoản**.
- Có trạng thái loading nếu cần khôi phục phiên/token qua mạng; không để người dùng bấm nhiều lần tạo nhiều luồng.

**Hành vi và điều hướng**
- Token/phiên hợp lệ: vào giao diện 04 (khung tab chính, mặc định tab Lộ trình).
- Không có phiên: hiển thị màn Chào mừng.
- **Bắt đầu ngay**: bắt đầu khảo sát 02. Theo thiết kế backend, có thể tạo guest session trước hoặc sau khảo sát; phải thống nhất luồng để câu trả lời khảo sát gắn đúng user.
- **Tôi đã có tài khoản**: mở giao diện 03 ở tab Đăng nhập.
- Lỗi khôi phục phiên: xóa phiên hỏng hoặc yêu cầu đăng nhập lại, hiển thị thông báo thân thiện.

**Dữ liệu / quy tắc**
- Không chứa thông tin mật khẩu trong local storage.
- Nếu dùng guest account, lưu token guest như phiên bình thường để tiến độ học được đồng bộ.

**Tiêu chí hoàn thành**
- Mỗi lần mở app xác định được trạng thái phiên và chỉ điều hướng một lần.
- Không mắc kẹt ở splash khi API lỗi hoặc mất mạng.

## 02. Khảo sát cá nhân hóa

**Mục tiêu:** thu thập lựa chọn ban đầu để cấu hình lộ trình và mục tiêu học.

**Bố cục**
- Tiến trình 3 bước, nút **Quay lại**, tiêu đề/câu hỏi hiện tại, nhóm lựa chọn dạng card có biểu tượng, nút **Tiếp tục**.
- Các lựa chọn đã chọn cần có trạng thái trực quan; hỗ trợ quay lại mà không mất dữ liệu.

**Ba câu hỏi**
1. Mục tiêu: Giao tiếp, Công việc, Du lịch, Học tập.
2. Trình độ: Mới bắt đầu (mở Chặng 1), Cơ bản (mở Chặng 1–2), Khá (mở Chặng 1–4).
3. Thời lượng mỗi ngày: 5, 10, 15 hoặc 20 phút.

**Hành vi**
- **Tiếp tục** chỉ hoạt động sau khi chọn đáp án của bước hiện tại.
- Bước 1 → 2 → 3; **Quay lại** lùi một bước và giữ lựa chọn.
- Kết thúc khảo sát: người dùng chưa xác thực có thể tiếp tục học dưới dạng khách; đồng bộ cấu hình lên `/me` sau khi có phiên. Nếu sản phẩm bắt buộc đăng nhập trước, điều hướng sang 03 rồi đồng bộ sau auth.

**Dữ liệu**
- Gửi goal, level và `daily_goal_minutes` theo hợp đồng `/me`.
- Trình độ ảnh hưởng trạng thái mở khóa do backend trả về ở `/path`; không tự mở khóa bài chỉ dựa vào UI.

**Tiêu chí hoàn thành**
- Có thể quay lại sửa lựa chọn; không gửi cấu hình thiếu trường.
- Mục tiêu/ngày hiển thị nhất quán ở giao diện 04 và 18.

## 03. Đăng nhập / Đăng ký

**Mục tiêu:** tạo phiên hoặc liên kết tài khoản để lưu tiến độ và mở quyền AI sau xác minh.

**Bố cục**
- Tiêu đề động viên lưu tiến trình; tab **Đăng nhập** / **Đăng ký**.
- Email, mật khẩu; nút hiện/ẩn mật khẩu; nút **Quên mật khẩu?**.
- Nút tiếp tục với Google và Apple.
- Hộp thoại quên mật khẩu nhập email và hiển thị xác nhận gửi link.

**Hành vi**
- Validate email, mật khẩu và trường bắt buộc tại client; lỗi cuối cùng vẫn hiển thị theo phản hồi API.
- Đăng nhập thành công: lưu token an toàn, tải `/me`, chuyển giao diện 04.
- Đăng ký thành công: hiển thị yêu cầu kiểm tra email; gửi lại xác minh khi backend cho phép.
- Đăng nhập Google/Apple: gọi social auth; trường hợp provider xác minh danh tính được backend ghi nhận theo chính sách.
- Khách chọn đăng nhập tài khoản có sẵn: hỏi có gộp tiến độ khách không; chỉ gửi `guest_token` nếu người dùng đồng ý.
- API trả `EMAIL_NOT_VERIFIED`: hiển thị trang/hộp thoại kiểm tra email và nút gửi lại.
- API trả lỗi mạng/credential: thông báo tại form, giữ email để người dùng sửa nhanh nhưng không giữ mật khẩu sau lỗi nghiêm trọng.

**Trạng thái cần có**
- Đang gửi; thành công; email chưa xác minh; sai thông tin; mất mạng; link reset đã gửi.

**Tiêu chí hoàn thành**
- Chặn submit lặp; không ghi token thường vào preferences; hỗ trợ guest → link account và guest → login có hỏi gộp tiến độ.
