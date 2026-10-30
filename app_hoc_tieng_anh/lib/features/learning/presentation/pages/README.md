# Đặc tả giao diện 04–05 và 11: Lộ trình và bài học

## 04. Bản đồ lộ trình (Home Path)

**Mục tiêu:** cho người học biết tiến độ hôm nay, các chặng/bài đã mở và bắt đầu bài tiếp theo.

**Bố cục**
- Thanh trên cùng sticky: biểu tượng lửa + số ngày streak bên trái; tổng XP bên phải.
- Thẻ **Mục tiêu hôm nay** được ghim: XP hiện tại/mục tiêu và số lượt AI còn/đã dùng trong ngày (nếu backend cung cấp summary/quota).
- Nội dung cuộn dọc: các banner Unit/Chặng; các nút bài học xếp đường đi hình chữ S.
- Nút bài học có ba trạng thái: hoàn thành (vàng), hiện tại (xanh, có tiến độ), khóa (xám).
- Chạm bài mở bottom sheet: tiêu đề, mẹo ngữ pháp, mẫu câu và nút **Bắt đầu (+10 XP)** theo nội dung bài.

**Hành vi**
- Tải lộ trình từ `/path`; trạng thái khóa/mở/hoàn tất theo response backend.
- Chạm bài bị khóa: giải thích điều kiện cần hoàn thành, không điều hướng vào lesson.
- Chạm bài mở → bottom sheet; **Bắt đầu** tải lesson và mở giao diện 05.
- Pull-to-refresh hoặc nút thử lại khi tải lỗi; giữ vị trí cuộn khi quay lại từ bài.

**Dữ liệu**
- XP, streak và mục tiêu lấy từ progress summary; quota lấy từ scan quota/summary. Không tính các số liệu này bằng biến UI làm nguồn chính.

## 05. Khung bài học và phản hồi (Lesson Shell)

**Mục tiêu:** cung cấp cùng một khung điều khiển cho 5 loại bài tập, đồng thời xử lý câu sai và phản hồi.

**Bố cục**
- Trên cùng: nút đóng X và thanh tiến trình.
- Vùng giữa: render exercise theo `type` từ lesson: image choice, word bank, listening, speaking hoặc match pairs.
- Dưới: nút **Kiểm tra** hoặc nút tiếp tục tùy trạng thái.
- Sau kiểm tra: banner trượt lên. Đúng: nền xanh, lời khen, **Tiếp tục**. Sai: nền đỏ, đáp án đúng/giải thích ngắn, **Đã hiểu**.

**Luồng câu hỏi**
- Duy trì queue câu hỏi và lượt thử; trả lời đúng thì tiến độ tăng.
- Trả lời sai không chặn bài; ghi nhận đáp án và đưa câu vào cuối queue để làm lại, gắn nhãn **Làm lại câu sai**.
- Không tăng tiến độ khi sai; kết thúc chỉ khi các câu trong queue đã đạt điều kiện hoàn tất.
- Ghi `try_no`, `exercise_id`, câu trả lời và kết quả cục bộ để gửi khi complete theo hợp đồng backend.

**Thoát bài**
- X hoặc nút Back hệ thống mở dialog: **Nếu thoát bây giờ, tiến trình bài học này sẽ không được lưu**.
- Chọn ở lại đóng dialog; xác nhận thoát quay về 04. Dùng PopScope để xử lý nút Back/gesture được hỗ trợ.

**Trạng thái lỗi**
- Tải lesson thất bại: thử lại/quay lại.
- Mất mạng khi đang làm: giữ state hiện tại trong bộ nhớ và báo rõ; hành vi khôi phục sau khi đóng app cần quyết định riêng vì tài liệu nói tiến trình dở dang không lưu.

## 06. Chọn hình ảnh

- Hiển thị từ vựng, IPA và nút loa ở phần đầu.
- Lưới 2×2 gồm hình và nhãn dưới mỗi hình (Anh hoặc Việt tùy exercise content).
- Chọn một thẻ: viền/trạng thái selected đổi; có thể phát âm từ tương ứng.
- **Kiểm tra** thuộc lesson shell; widget bài chỉ cung cấp lựa chọn hiện tại và trạng thái.
- Chặn kiểm tra nếu chưa chọn; hỗ trợ tải placeholder/lỗi ảnh.

## 07. Ghép từ thành câu

- Linh vật và câu gốc ở phía trên; từ có gợi ý nghĩa nhận diện được là tương tác.
- Vùng 2–3 dòng để ráp câu; bên dưới là ngân hàng từ đã xáo trộn, gồm từ đúng và từ nhiễu.
- Chạm từ ngân hàng đưa từ lên vùng câu; chạm từ đã chọn đưa về ngân hàng.
- Duy trì thứ tự từ; không thêm cùng một chip nhiều lần nếu content không cho phép.
- Kiểm tra qua lesson shell; gửi mảng đáp án theo định dạng exercise.

## 08. Luyện nghe và điền từ

- Có chỉ dẫn **Nghe và chọn/gõ lại câu bạn nghe được**.
- Nút loa phát tốc độ chuẩn 1.0x và nút rùa phát chậm 0.7x; hiển thị loading khi audio chưa sẵn sàng.
- Theo exercise: ô nhập văn bản/câu khuyết hoặc chip từ lựa chọn.
- Cho phát lại nhiều lần; kiểm tra không được thực hiện nếu câu trả lời rỗng.
- Audio lỗi cần có thông báo/thử lại; không biến lỗi audio thành đáp án sai.

## 09. Luyện phát âm

- Hiển thị câu mẫu tiếng Anh, IPA, micro lớn, hiệu ứng sóng và trạng thái nhận diện trực tiếp.
- **Mình không tiện nói lúc này** bỏ qua câu nói theo quy tắc sản phẩm (đề xuất: bỏ qua các câu speaking trong phiên/15 phút theo tài liệu FE).
- Xin quyền micro bằng rationale trước khi gọi system permission; nếu bị từ chối vĩnh viễn, cung cấp nút mở Cài đặt.
- Khi thu: trạng thái đang nghe, có thể dừng/hủy; sau nhận diện tô xanh từ khớp và thể hiện score.
- Tài liệu FE ghi đạt ≥75%, Backend ghi score ≥0.6; cần chốt một ngưỡng trước khi code. Kết quả cuối phải khớp logic backend.

## 10. Ghép cặp thẻ từ

- Hướng dẫn chạm các cặp tương ứng; lưới 2 cột × 5 hàng, 5 từ tiếng Anh và bản dịch Việt đã xáo trộn.
- Chọn thẻ đầu rồi thẻ đối ứng; đúng thì nháy xanh, mờ/vô hiệu hóa; sai thì nháy đỏ và rung nhẹ.
- Không chọn lại thẻ đã ghép; tránh nhận nhiều lần chạm trong animation.
- Nút **Tiếp tục** chỉ hoạt động khi đủ 5 cặp; gửi cấu trúc cặp và kết quả theo contract.

## 11. Tổng kết bài học

**Bố cục:** linh vật ăn mừng/pháo giấy; ba thẻ XP, độ chính xác, thời gian; khối streak và tiến độ mục tiêu ngày; nút **Tiếp tục**.

**Dữ liệu/hành vi**
- Khi kết thúc, gửi attempt ID, thời gian, answers và try number lên endpoint complete.
- Hiển thị kết quả server trả: XP thực nhận, accuracy, duration, streak, daily goal, next lesson.
- Backend cập nhật tiến độ/mở bài và mistakes; UI không tự cộng XP lần nữa.
- Nút tiếp tục quay về giao diện 04 và refresh lộ trình/summary.
- Nếu submit timeout, cần tránh tạo attempt trùng; dùng attempt ID idempotent để thử lại.
