# tests/integration/

Kiểm tra router HTTP, Pydantic validation, auth dependency, transaction, PostgreSQL constraints và Redis rate limit với service test instances.

Dùng fixture tạo schema riêng và rollback/cleanup; mock external detector/email/storage/FCM trừ khi chạy integration profile chủ động. Bao gồm response status/body đúng API contract và kiểm tra guest/unverified bị chặn ở mọi route AI.
