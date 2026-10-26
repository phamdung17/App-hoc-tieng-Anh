# app/modules/

## Vai trò
Mỗi thư mục con là một bounded context API. Module sở hữu endpoint, schema, service, repository và model liên quan.

## Mẫu file trong một module
- `router.py`: khai báo HTTP method/path, dependency, status code, chuyển request sang service.
- `schemas.py`: Pydantic request/response; không dùng ORM object làm public schema trực tiếp.
- `service.py`: nghiệp vụ, quyền, transaction boundary và gọi integrations qua interface.
- `repository.py`: câu truy vấn SQLAlchemy; không format HTTP response.
- `models.py`: ORM tables thuộc module nếu bảng có chủ sở hữu rõ ràng.

Module nhỏ có thể gom vài file có liên quan, nhưng vẫn giữ ranh giới router → service → repository. Endpoint version đặt dưới router gốc `/api/v1`.
