# tests/

## Mục đích
Bảo vệ nghiệp vụ quan trọng và hợp đồng API. Dùng database/cache test riêng; không gọi production hoặc chứa dữ liệu cá nhân.

## Nhóm kiểm thử
- Unit: service/scoring/quota/SRS.
- Integration: router + PostgreSQL/Redis test.
- Fixtures: factory và data nhỏ.

## Các ca ưu tiên theo BE spec
AI access guest/unverified, 10 scans/day + system budget, no_object/failure quota behavior, server scoring, XP idempotency, streak timezone, guest merge, SRS box transitions, account deletion.
