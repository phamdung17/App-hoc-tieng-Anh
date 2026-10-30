# modules/vocab/

## Endpoints
`GET /vocab?q=&topic=&cursor=`, `GET/PATCH/DELETE /vocab/{id}`, `GET /words/{id}/related-lessons`; save từ scan nằm dưới scan-items API.

## Dữ liệu
`user_words` nối user với word catalog, scan item, ảnh/crop private, note, Leitner box, review date và counters. Unique `(user_id, word_id)` ngăn duplicate.

## Quy tắc
Tất cả routes yêu cầu verified AI user. Search hỗ trợ lemma/meaning, filters topic/mastery, pagination cursor. PATCH chỉ cho phép field được phép; DELETE không được làm mất audit/ledger cần thiết. Ảnh private trả presigned URL.

Không cho tạo từ tùy ý nếu chính sách content yêu cầu chỉ chọn `words` đã seed.
