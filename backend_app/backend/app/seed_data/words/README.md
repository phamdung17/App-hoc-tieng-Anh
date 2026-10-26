# seed_data/words/

## Hai nguồn dữ liệu của bảng `words`
1. **Seed nền:** từ do nhóm biên soạn/duyệt trước, dùng ổn định trong kho từ và lesson.
2. **Cache từ Gemini:** khi scan trả lemma chưa có, Backend validate card rồi lưu dùng chung; những lần sau tái sử dụng card đã lưu thay vì để Gemini ghi đè.

Gemini cache không đồng nghĩa với tạo bài học tự động: chỉ bổ sung dictionary card phát sinh từ scan; `courses`, `units`, `lessons`, `exercises` vẫn phải seed/duyệt thủ công.

## Fields
`lemma`, `ipa`, `pos`, `meaning_vi`, `example_en`, `example_vi`, `topic`, `audio_url` tùy chọn. Lưu provenance/source để phân biệt curated seed và generated cache nếu cần vận hành/audit.

## Kiểm duyệt và validation
Chuẩn hóa lemma/unique key; validate field length, loại từ, bbox-item mapping và dữ liệu ngôn ngữ trước khi ghi. Seed nền cần human review và attribution/license. Cache Gemini phải dùng structured output + Pydantic validation, giới hạn nội dung, không ghi đè row đã có.
