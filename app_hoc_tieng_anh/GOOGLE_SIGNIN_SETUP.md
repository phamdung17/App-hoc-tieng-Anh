# Hướng dẫn cấu hình Google Sign-In

## Tổng quan luồng
```
App Flutter  ──(1) chọn TK Google──►  Google OAuth
             ◄──(2) idToken──────────  Google OAuth
             ──(3) POST /auth/social/google {id_token}──►  FastAPI Backend
             ◄──(4) {tokens: {access_token, refresh_token}}──  FastAPI Backend
             ──lưu token──►  FlutterSecureStorage
```

---

## Bước 1 — Tạo OAuth 2.0 Client trong Google Cloud Console

1. Vào https://console.cloud.google.com → Tạo/chọn project.
2. Menu **APIs & Services → Credentials → Create Credentials → OAuth 2.0 Client ID**.
3. Tạo **2 Client ID**:
   - **Android**: package name `com.example.app_hoc_tieng_anh`, SHA-1 fingerprint debug.
   - **iOS**: Bundle ID `com.example.appHocTiengAnh`.
4. Tải file **`google-services.json`** (Android) và **`GoogleService-Info.plist`** (iOS).

### Lấy SHA-1 (Android debug)
```bash
cd android
./gradlew signingReport
# Hoặc:
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

---

## Bước 2 — Cấu hình Android

### 2a. Đặt file google-services.json
```
android/app/google-services.json   ← đặt ở đây
```

### 2b. Sửa android/build.gradle (project-level)
```gradle
buildscript {
  dependencies {
    classpath 'com.google.gms:google-services:4.4.2'   // thêm dòng này
  }
}
```

### 2c. Sửa android/app/build.gradle (app-level)
```gradle
apply plugin: 'com.google.gms.google-services'   // thêm ở cuối file
```

### 2d. Kiểm tra minSdk
Trong `android/app/build.gradle`, đảm bảo:
```gradle
defaultConfig {
  minSdkVersion 21   // tối thiểu 21
}
```

---

## Bước 3 — Cấu hình iOS

### 3a. Đặt file GoogleService-Info.plist
```
ios/Runner/GoogleService-Info.plist   ← đặt ở đây
```
Mở bằng Xcode hoặc VSCode để thêm vào Runner target.

### 3b. Thêm URL Scheme vào Info.plist
Mở `ios/Runner/Info.plist`, thêm vào `<dict>`:
```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <!-- Lấy giá trị REVERSED_CLIENT_ID từ GoogleService-Info.plist -->
      <string>com.googleusercontent.apps.YOUR_REVERSED_CLIENT_ID</string>
    </array>
  </dict>
</array>
```

---

## Bước 4 — Cấu hình Backend FastAPI

Backend cần endpoint `POST /api/v1/auth/social/google` nhận `id_token` và xác minh với Google:

```python
# backend_app/backend/app/modules/auth/router.py  (thêm endpoint)
from google.oauth2 import id_token
from google.auth.transport import requests as google_requests

@router.post("/social/google")
async def google_social_login(
    body: GoogleSocialLoginRequest,
    db: AsyncSession = Depends(get_db),
):
    # Xác minh idToken với Google
    GOOGLE_CLIENT_ID = settings.GOOGLE_CLIENT_ID  # thêm vào .env
    info = id_token.verify_oauth2_token(
        body.id_token,
        google_requests.Request(),
        GOOGLE_CLIENT_ID,
    )
    email = info["email"]
    name = info.get("name", "")
    # Tìm hoặc tạo user...
    # Trả về tokens
```

### Thêm vào .env
```env
GOOGLE_CLIENT_ID=YOUR_WEB_CLIENT_ID.apps.googleusercontent.com
```

### Thêm dependency Python
```toml
# pyproject.toml
google-auth = "^2.35"
```

---

## Bước 5 — Kiểm tra

### Android (emulator/thiết bị thật)
```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
```

### iOS Simulator
```bash
# Lưu ý: Google Sign-In trên iOS Simulator cần thiết bị thật hoặc
# dùng tài khoản Google thật
flutter run
```

---

## Lưu ý quan trọng

- **SHA-1 Release**: Khi build production, cần thêm SHA-1 của keystore release vào Firebase Console.
- **Apple Sign-In**: Xem cấu hình tương tự trong `APPLE_SIGNIN_SETUP.md` (sẽ bổ sung sau).
- **Web Client ID**: Cần dùng Web Client ID (không phải Android/iOS Client ID) khi gửi lên backend.
- File `google-services.json` và `GoogleService-Info.plist` **KHÔNG được commit lên Git** — thêm vào `.gitignore`.

