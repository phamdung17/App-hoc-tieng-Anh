# modules/scan/

## Endpoints
- `GET /scans/quota`: lượt còn lại và thời điểm reset.
- `POST /scans`: multipart image scan.
- `GET /scans?cursor=` và `GET /scans/{id}`: lịch sử/chi tiết.
- `PATCH /scan-items/{id}`: đổi nhãn sang một word có trong catalog.
- `POST /scan-items/{id}/save`: lưu vào kho, crop ảnh ở bước này.
- `POST /scan-items/{id}/report`: báo nhãn sai.

## Flow POST /scans
1. `require_ai_user`: chặn guest (`AUTH_REQUIRED_FOR_AI`) và email chưa xác minh (`EMAIL_NOT_VERIFIED`).
2. Atomically kiểm `ai_usage_daily < 10` và `ai_budget_daily` còn ngân sách.
3. Nhận JPEG/PNG/HEIC tối đa 5 MB; Pillow decode/validate, resize tối đa 1280px và nén JPEG.
4. Upload ảnh vào `scans-private`.
5. Gửi ảnh + prompt cố định tới Gemini API một lần; yêu cầu structured JSON gồm `lemma`, `box_2d`, `confidence` và card fields (`ipa`, `pos`, `meaning_vi`, `example_en`, `example_vi`, `topic`).
6. Validate bằng Pydantic; nếu JSON lỗi thì thử lại một lần. Chuẩn hóa bbox `[ymin,xmin,ymax,xmax]` 0..1000 thành x/y/w/h 0..1; loại bbox hỏng/nhãn trùng, tối đa 8 vật thể.
7. Tra lemma trong `words`: đã có thì tái sử dụng card đã cache; chưa có thì lưu card Gemini vừa tạo vào catalog chung. Không để kết quả mới ghi đè mục đã có.
8. Lưu scan/items; chỉ tăng quota sau thành công; trả presigned image URL cùng items/cards.

## Kết quả và lỗi
- Không có vật thể: `200`, `status=no_object`, không trừ lượt.
- Gemini timeout/lỗi hoặc JSON sai sau một lần retry: `503 SCAN_FAILED`, không trừ lượt.
- User quota hết: `429 SCAN_LIMIT_REACHED` + remaining/reset_at.
- System budget hoặc Google 429: `503 AI_TEMPORARILY_UNAVAILABLE`, không trừ lượt.
- Gemini safety filter từ chối ảnh: `422 IMAGE_REJECTED`, không trừ lượt.

## Lưu và sửa nhãn
Crop chỉ tạo khi save. Nếu từ đã có trong kho user, trả `409 WORD_EXISTS`; FE có thể hỏi `replace_image=true`. XP duy nhất một lần mỗi từ, giới hạn 5 từ/ngày theo xp ledger.

PATCH hiện chỉ cho chọn một lemma đã có trong bảng `words`. FE doc mới vẫn yêu cầu hai ô nhập từ Anh/Việt tự do; cần chốt hợp đồng trước khi code (FE dùng search chọn catalog, hoặc BE hỗ trợ tạo/cập nhật label tùy ý). Không gọi Gemini lần hai cho thao tác sửa.

## Bảo mật/quyền riêng tư
API key Gemini chỉ ở Backend environment. Ảnh người dùng được gửi tới Google; product/privacy copy và điều khoản áp dụng cho gói API cần được rà soát trước phát hành.
