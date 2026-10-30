# seed_data/exercises/

## Các type hỗ trợ
`image_choice`, `word_bank`, `listening`, `speaking`, `match_pairs` theo schema backend.

## Mỗi exercise cần
Stable ID, lesson ID, thứ tự, type, prompt/instructions, media refs, payload riêng theo type và answer key phía server cho dạng server-chấm. Listening lưu text/audio reference/correct answer; speaking lưu câu mẫu/IPA/score policy; match pairs lưu cặp hợp lệ.

## Validation
Loader kiểm tra discriminator type, required keys, lựa chọn đúng/sai, số item, media key có tồn tại và đáp án. Không để answer key rơi vào DTO FE nếu endpoint không được phép trả.
