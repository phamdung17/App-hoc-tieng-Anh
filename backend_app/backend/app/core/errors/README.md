# app/core/errors/

## Vai trò
Chuẩn hóa lỗi nghiệp vụ và lỗi HTTP thành response `{code, message, details}` để Flutter xử lý ổn định.

## File dự kiến
- `app_error.py`: exception có HTTP status, code, message an toàn, details tùy chọn.
- `handlers.py`: FastAPI handlers cho AppError, validation error, HTTP error và lỗi không mong đợi.
- `codes.py`: constants/enums cho mã lỗi công khai nếu cần.

## Các mã nghiệp vụ đã định nghĩa
`AUTH_REQUIRED_FOR_AI`, `EMAIL_NOT_VERIFIED`, `SCAN_LIMIT_REACHED`, `AI_TEMPORARILY_UNAVAILABLE`, `SCAN_FAILED`, `WORD_EXISTS`, `ATTEMPT_ALREADY_SUBMITTED`.

Không trả SQL, stack trace, secret hay thông tin nhạy cảm cho client. Lỗi không dự kiến cần log correlation/request ID và trả thông báo chung 500.
