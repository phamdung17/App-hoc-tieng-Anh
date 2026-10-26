# Đặc tả giao diện 12–13: AI nhận diện đồ vật

## 12. Máy ảnh và tải ảnh AI

**Mục tiêu:** chụp/chọn ảnh và gửi Backend nhận diện bằng Gemini; người dùng thấy quota, quyền và trạng thái xử lý.

**Bố cục**
- Thanh đầu: Đóng, quota scan còn lại, flash và lịch sử gần đây.
- Giữa: camera preview với khung căn vật thể.
- Dưới: chọn ảnh thư viện và nút chụp.
- Khi xử lý: progress/loading; dự kiến 2–6 giây tùy mạng, timeout client khoảng 30 giây.

**Hành vi**
- Lấy quota từ `/scans/quota`; Backend mới là nguồn chính và kiểm tra quota atomically.
- Xin quyền sau rationale; nếu từ chối vĩnh viễn có nút mở Settings.
- Nén ảnh khoảng 200 KB theo yêu cầu FE, upload multipart. Backend vẫn validate JPEG/PNG/HEIC, max 5 MB, decode, resize max 1280px và nén lại; client compression không thay kiểm tra server.
- Chỉ user đã xác minh email mới được scan. Guest/unverified nhận hướng đăng ký/xác minh.
- Backend gọi Gemini API từ server, không có Gemini key hoặc Gemini SDK trong Flutter.
- Thành công có items → 13. `no_object` → empty result, không trừ quota. Retry khi timeout/mạng lỗi; không retry vô hạn.
- Mã lỗi: `SCAN_LIMIT_REACHED` (429), `AI_TEMPORARILY_UNAVAILABLE` (503), `SCAN_FAILED` (503), `IMAGE_REJECTED` (422). Hiển thị remaining/reset time khi có.

## 13. Kết quả nhận diện AI

**Bố cục**
- Ảnh trên với nhãn/bounding boxes; box đang chọn cần nhấn mạnh.
- Bottom sheet item: crop preview, từ, từ loại, IPA, audio, nghĩa Việt, ví dụ song ngữ.
- Nút **Sửa nhãn / Báo sai**, **Lưu vào Kho từ vựng**, sau lưu có lối tắt ôn hoặc bài liên quan.

**Nguồn kết quả**
Gemini trả trong cùng một response: `lemma`, bbox, confidence và card fields. Backend validate structured JSON bằng Pydantic, retry một lần nếu malformed; lọc trùng và tối đa 8 item. Gemini bbox đầu vào chuẩn hóa 0..1000; Backend chuyển sang x/y/w/h 0..1. Box có thể lệch nhẹ nên FE vẽ gần đúng và cho người dùng sửa nhãn.

**Sửa nhãn – hợp đồng cần chốt**
FE source yêu cầu hai ô nhập từ tiếng Anh/nghĩa Việt tự do; Backend source hiện chỉ chấp nhận chọn lemma có trong `words`. Catalog `words` có seed đã duyệt và cache card Gemini mới; vẫn chưa cho phép nhập tùy ý. Trước khi code cần chọn: (A) FE tìm/chọn từ trong catalog, hoặc (B) Backend mở endpoint cho nhãn user nhập. Không giả định PATCH chấp nhận text tự do.

**Lưu**
- Save mới tạo crop; ảnh gốc private và presigned URL hết hạn sau 1 giờ.
- Nếu từ đã có trong user vault: `WORD_EXISTS`, hỏi thay ảnh và gửi `replace_image=true` nếu đồng ý.
- XP hiển thị theo response server; FE doc cũ ghi +5 XP, BE doc mới ghi +10 XP/từ, max 5 từ/ngày và mỗi từ một lần. Cần chốt con số API/UI.
- Google có thể từ chối ảnh bởi safety filter (`IMAGE_REJECTED`); Gemini/provider 429 hoặc system budget hết → `AI_TEMPORARILY_UNAVAILABLE`.

**Quyền riêng tư**
Ảnh người dùng được upload tới Backend rồi gửi sang Google Gemini để xử lý. UI cần dẫn tới privacy disclosure; product team cần rà soát điều khoản API của gói đang sử dụng.
