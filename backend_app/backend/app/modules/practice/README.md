# modules/practice/

## Endpoints
`GET /mistakes`; `GET /practice/listening?limit=10`; `GET /practice/speaking?limit=10`; `POST /practice/complete`.

## Hộp lỗi sai
Mistake upsert theo user/exercise, tăng `wrong_count`, cập nhật `last_wrong_at`; khi trả lời đúng, gán `resolved_at`. Tránh tạo nhiều dòng lỗi cho cùng một exercise/user.

## Luyện nhanh
Chỉ lấy câu từ lesson đã học; ưu tiên mistake chưa resolve. Session giới hạn 10 câu theo request/server policy. Backend chấm theo type đã định nghĩa, cộng XP theo giới hạn 3 phiên/ngày mỗi loại và cập nhật daily minutes.

## Ranh giới
Learning quản lý lesson attempt; practice quản lý session luyện nhanh/hộp sai. Có thể dùng shared scoring service nếu không làm vòng phụ thuộc module.
