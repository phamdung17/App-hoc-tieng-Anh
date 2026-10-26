# integrations/detector/ – Gemini Vision adapter (tên thư mục cần đổi)

## Cập nhật kiến trúc
Tài liệu Backend mới bỏ YOLO-World/container detector. Thư mục scaffold hiện vẫn tên `detector`, nhưng khi bắt đầu code nên đổi thành `app/integrations/gemini/` hoặc `gemini_client/` để phản ánh provider thật.

## Vai trò dự kiến
Gửi ảnh đã chuẩn hóa cùng prompt cố định tới Gemini API, yêu cầu structured JSON trả về nhãn, bbox/confidence và thẻ từ. Adapter chỉ lo giao tiếp provider; scan service quản lý auth/quota, validation nghiệp vụ, cache, lưu DB và response HTTP.

## File dự kiến sau khi đổi tên
- `client.py`: khởi tạo Gemini client và gọi model hỗ trợ image + structured output.
- `schemas.py`: kiểu response/provider payload nếu cần tách khỏi schema API công khai.
- `errors.py`: map timeout, provider 429, safety rejection, lỗi provider và malformed JSON.

## Quy tắc
- API key chỉ lấy từ settings/environment Backend; tuyệt đối không gửi vào Flutter hoặc log.
- Một lần gọi cho nhận diện + card; không gọi thêm lần hai chỉ để tra cứu từ.
- Prompt cố định: đồ vật phổ biến; bỏ người/khuôn mặt/giấy tờ; yêu cầu schema định rõ.
- Đặt timeout phù hợp khoảng 30 giây; Google 429/system budget map `AI_TEMPORARILY_UNAVAILABLE`; timeout/provider failure map `SCAN_FAILED`; safety rejection map `IMAGE_REJECTED`.
- Backend validate Pydantic, retry tối đa một lần khi output sai cấu trúc. Không tin JSON từ model trực tiếp.
- Chỉ truyền ảnh cần thiết, không log ảnh/base64. Ghi nhận dữ liệu ảnh gửi sang Google trong chính sách riêng tư.

Folder này là scaffold cũ; chưa có code detector hoặc Gemini client.
