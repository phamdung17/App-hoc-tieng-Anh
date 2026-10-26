# app/core/

## Vai trò
Nền tảng kỹ thuật dùng chung, không chứa quy tắc riêng của lesson, scan hay vocab.

## Thành phần
- `config/`: đọc và validate settings từ environment.
- `security/`: hash password, JWT, token hashing và xác minh credential.
- `deps/`: dependency injection cho session, current user và quyền AI.
- `errors/`: lỗi ứng dụng và response error thống nhất.

## Quy tắc
Core không import router/module cụ thể. Module có thể dùng core. Không để core trở thành nơi gom tùy tiện mọi tiện ích; logic chỉ có một chủ sở hữu thì đặt trong module đó.
