# App học tiếng Anh + AI

Repository/project Flutter frontend. Backend là project riêng bên cạnh tại `../backend_app/backend/`.

- [Bản đồ thư mục FE/BE và plugin](FIleMap.md)
- [Đặc tả UI 12–13 và luồng Gemini scan](lib/features/scan/presentation/pages/README.md)
- [Backend README](../backend_app/backend/README.md)

Flutter gọi FastAPI qua HTTPS/JWT. Backend gọi Gemini API để nhận diện và tạo/cache thẻ từ; API key không được đặt trong Flutter. Course, lesson và exercise vẫn seed thủ công; không sinh bài học lúc runtime.
