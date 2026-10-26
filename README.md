# App học tiếng Anh

Dự án ứng dụng học tiếng Anh gồm Flutter frontend và FastAPI backend.

## Cấu trúc

- `app_hoc_tieng_anh/`: Flutter app, giao diện và các luồng học.
- `backend_app/backend/`: FastAPI backend, auth, scan AI và các module nghiệp vụ.
- `weekly_implementation_plan.md`: kế hoạch triển khai.
- `project_review.md`: ghi chú rà soát dự án.

## Chạy Flutter app

```powershell
cd app_hoc_tieng_anh
flutter pub get
flutter run
```

Chạy `flutter devices` để xem emulator hoặc thiết bị đang kết nối.

## Backend

Xem hướng dẫn, trạng thái và cấu hình tại [`backend_app/backend/README.md`](backend_app/backend/README.md). Tạo file `.env` từ `.env.example` và điền các cấu hình cần thiết trước khi chạy backend. Không commit `.env`, API key hoặc credentials thật.

## Ghi chú

Một số luồng còn phụ thuộc API/backend chưa triển khai; xem README trong từng module để biết trạng thái và phạm vi hiện tại.
