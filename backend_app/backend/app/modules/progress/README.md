# modules/progress/

## Endpoint
`GET /progress/summary`, `GET /progress/calendar?month=`; có thể cung cấp service tổng hợp dùng chung cho lesson result/home.

## Nguồn dữ liệu
`daily_activity` theo user/date, `xp_ledger`, lesson progress. Streak không có cột riêng; tính từ ngày có XP > 0 theo `users.timezone`.

## Quy tắc
- Hôm nay chưa có hoạt động thì streak hiện tại chưa đứt ngay; chỉ đứt sau khi qua ngày địa phương mà không học.
- Tổng XP phải khớp ledger.
- Mục tiêu phút cộng thời gian lesson, review, practice và scan theo rule backend.
- Calendar trả dấu hoạt động theo timezone user; validate tháng và phân trang/kích thước response.

Không nhận giá trị streak/xp do Flutter tự tính làm nguồn dữ liệu.
