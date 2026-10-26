# 📅 Kế Hoạch 1 Tuần — Tích Hợp Gemini API & Nền Tảng Backend

> **Ngày bắt đầu**: 20/10/2026 (Thứ Ba)  
> **Mục tiêu**: Hoàn thành tích hợp Gemini API thay thế YOLO-World **và** đặt nền tảng backend có thể chạy được.

---

## Bối Cảnh

Dự án hiện ở trạng thái **scaffold chỉ có README + `.gitkeep`** — chưa có file Python hoặc Dart nào thực thi. Kế hoạch này tập trung vào backend trước (ưu tiên cao hơn), và song song bắt đầu nền tảng Flutter phần thiết yếu nhất.

### Phạm vi tuần này
| Hạng mục | Trạng thái mục tiêu cuối tuần |
|---|---|
| Backend: Nền tảng (config, main, dependencies) | ✅ Chạy được |
| Backend: Gemini integration (`integrations/gemini/`) | ✅ Code + unit test |
| Backend: Scan module core (`modules/scan/service.py`) | ✅ Logic chính |
| Backend: Docker Compose + `.env.example` | ✅ Dev environment |
| Backend: Database schema + Alembic | ✅ Migration chạy được |
| Tài liệu: Cập nhật README/FileMap/project_review | ✅ Phản ánh Gemini |
| Flutter: Core (theme, router, main_shell) | 🟡 Khởi đầu |

---

## 🗓️ Chi Tiết Theo Ngày

---

### **Ngày 1 — Thứ Ba 20/10: Nền Tảng Backend**

**Mục tiêu**: Backend có thể khởi động, kết nối DB/Redis, không bị lỗi import.

#### Task B1.1 — Tạo `pyproject.toml` / `requirements.txt`
```
backend/
├── pyproject.toml   # hoặc requirements.txt
├── .env.example
└── README.md        # cập nhật stack: YOLO-World → Gemini API
```

Dependencies cần khai báo:
```toml
[tool.poetry.dependencies]
python = "^3.11"
fastapi = "^0.115"
uvicorn = {extras = ["standard"], version = "^0.32"}
pydantic = {extras = ["email"], version = "^2.9"}
pydantic-settings = "^2.5"
httpx = "^0.27"
sqlalchemy = {extras = ["asyncio"], version = "^2.0"}
asyncpg = "^0.30"
alembic = "^1.13"
redis = {extras = ["hiredis"], version = "^5.1"}
arq = "^0.26"
pillow = "^11.0"
python-multipart = "^0.0.12"
python-jose = {extras = ["cryptography"], version = "^3.3"}
passlib = {extras = ["bcrypt"], version = "^1.7"}
```

#### Task B1.2 — Tạo `core/config/settings.py`
```python
# backend/app/core/config/settings.py
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    # App
    APP_ENV: str = "development"
    DEBUG: bool = False
    API_V1_PREFIX: str = "/api/v1"

    # PostgreSQL
    DATABASE_URL: str

    # Redis
    REDIS_URL: str = "redis://localhost:6379"

    # Auth
    JWT_SECRET_KEY: str
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 15
    REFRESH_TOKEN_EXPIRE_DAYS: int = 30

    # Storage (S3/R2)
    STORAGE_ENDPOINT: str
    STORAGE_BUCKET_PRIVATE: str = "scans-private"
    STORAGE_BUCKET_PUBLIC: str = "content-public"
    STORAGE_ACCESS_KEY: str
    STORAGE_SECRET_KEY: str
    STORAGE_PRESIGN_TTL: int = 3600

    # Gemini API ← MỚI (thay thế DETECTOR_URL)
    GEMINI_API_KEY: str
    GEMINI_MODEL: str = "gemini-2.0-flash"
    GEMINI_TIMEOUT: int = 30

    # AI Safety
    SCAN_QUOTA_PER_USER_DAILY: int = 10
    SCAN_SYSTEM_BUDGET_DAILY: int = 500

settings = Settings()
```

#### Task B1.3 — Tạo `app/main.py`
```python
# backend/app/main.py
from fastapi import FastAPI
from app.core.config.settings import settings

app = FastAPI(
    title="English Learning AI Backend",
    version="1.0.0",
    debug=settings.DEBUG,
)

@app.get("/health")
async def health():
    return {"status": "ok", "env": settings.APP_ENV}
```

#### Task B1.4 — Tạo `.env.example`
```env
# App
APP_ENV=development
DEBUG=true
API_V1_PREFIX=/api/v1

# Database
DATABASE_URL=postgresql+asyncpg://postgres:password@localhost:5432/english_ai

# Redis
REDIS_URL=redis://localhost:6379

# Auth
JWT_SECRET_KEY=your-secret-key-here-min-32-chars

# Storage
STORAGE_ENDPOINT=https://your-r2-endpoint.r2.cloudflarestorage.com
STORAGE_BUCKET_PRIVATE=scans-private
STORAGE_BUCKET_PUBLIC=content-public
STORAGE_ACCESS_KEY=your-access-key
STORAGE_SECRET_KEY=your-secret-key

# Gemini API (https://aistudio.google.com/apikey)
GEMINI_API_KEY=AIza...your-key-here
GEMINI_MODEL=gemini-2.0-flash
GEMINI_TIMEOUT=30
```

#### Task B1.5 — Tạo `docker-compose.yml`
```yaml
services:
  backend:
    build: ./backend
    ports: ["8000:8000"]
    env_file: ./backend/.env
    depends_on: [postgres, redis]

  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: english_ai
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: password
    ports: ["5432:5432"]
    volumes: [postgres_data:/var/lib/postgresql/data]

  redis:
    image: redis:7-alpine
    ports: ["6379:6379"]

# Không còn container yolo-world!

volumes:
  postgres_data:
```

**✅ Verification Ngày 1**: `uvicorn app.main:app` khởi động, `/health` trả `200 OK`.

---

### **Ngày 2 — Thứ Tư 21/10: Gemini Integration**

**Mục tiêu**: Tạo toàn bộ `integrations/gemini/`, viết unit tests mock.

#### Task B2.1 — Tạo 5 files trong `integrations/gemini/`

**File cần tạo** (code chi tiết đã có trong `gemini_api_integration_plan.md`):

| File | Nội dung |
|---|---|
| `__init__.py` | Export `GeminiClient` |
| `client.py` | HTTP client gọi `generateContent` |
| `prompts.py` | `OBJECT_DETECTION_PROMPT` |
| `schemas.py` | `BoundingBox`, `DetectedObject`, `GeminiDetectionResponse` |
| `errors.py` | `GeminiTimeoutError`, `GeminiUnavailableError`, `GeminiInvalidResponseError`, `GeminiQuotaExceededError` |

> [!IMPORTANT]
> Prompt trong `prompts.py` cần điều chỉnh so với plan gốc: scan README yêu cầu thêm `pos` (part of speech), `meaning_vi`, `example_en`, `example_vi`, `topic` — phong phú hơn plan gốc chỉ có `label_vi` + `ipa` + `example_sentence`.

**Prompt cập nhật** (align với scan README):
```python
OBJECT_DETECTION_PROMPT = """
You are an object detection assistant for an English learning app.
Analyze the image and identify real-world objects visible in the photo.
Return a JSON object with this EXACT structure:
{{
  "objects": [
    {{
      "label": "apple",
      "label_vi": "quả táo",
      "confidence": 0.95,
      "ipa": "/ˈæp.əl/",
      "pos": "noun",
      "meaning_vi": "quả táo, loại trái cây tròn",
      "example_en": "I eat an apple every morning.",
      "example_vi": "Tôi ăn một quả táo mỗi sáng.",
      "topic": "food",
      "bounding_box": {{
        "x_min": 0.1, "y_min": 0.2,
        "x_max": 0.5, "y_max": 0.7
      }}
    }}
  ]
}}
Rules:
- Return at most {max_objects} objects.
- label: single common English noun (lowercase).
- confidence: 0.0 to 1.0.
- bounding_box: normalized 0.0 to 1.0.
- Exclude people, faces, documents, logos.
- If no objects found: return {{"objects": []}}.
- Return ONLY the JSON, no extra text.
"""
```

#### Task B2.2 — Viết Unit Tests
```
backend/tests/
├── __init__.py
└── integrations/
    └── test_gemini_client.py
```

Test cases cần cover:
- ✅ `test_detect_objects_success` — mock response hợp lệ → list DetectedObject
- ✅ `test_detect_objects_timeout` → `GeminiTimeoutError`
- ✅ `test_detect_objects_rate_limit` (429) → `GeminiQuotaExceededError`
- ✅ `test_detect_objects_invalid_json` → `GeminiInvalidResponseError`
- ✅ `test_detect_objects_empty` → empty list (no crash)
- ✅ `test_bounding_box_validation` — x_max ≤ x_min → ValidationError

**✅ Verification Ngày 2**: `pytest tests/integrations/` — tất cả pass.

---

### **Ngày 3 — Thứ Năm 22/10: Database Schema + Alembic**

**Mục tiêu**: Models SQLAlchemy cho `scan` module, migration chạy được.

#### Task B3.1 — Tạo Database Models
```
backend/app/core/
├── database.py      # async engine + session
└── models/
    ├── __init__.py
    ├── base.py      # Base declarative
    ├── user.py      # User model
    ├── scan.py      # Scan + ScanItem models
    └── word.py      # Word (vocabulary catalog) model
```

**Scan models** (từ scan README):
```python
# models/scan.py
class Scan(Base):
    __tablename__ = "scans"
    id: Mapped[UUID] = mapped_column(primary_key=True, default=uuid4)
    user_id: Mapped[UUID] = mapped_column(ForeignKey("users.id"))
    image_url: Mapped[str]         # presigned URL sau khi upload
    status: Mapped[str]            # "ok" | "no_object" | "failed"
    created_at: Mapped[datetime]

class ScanItem(Base):
    __tablename__ = "scan_items"
    id: Mapped[UUID] = mapped_column(primary_key=True, default=uuid4)
    scan_id: Mapped[UUID] = mapped_column(ForeignKey("scans.id"))
    word_id: Mapped[UUID | None] = mapped_column(ForeignKey("words.id"))
    label: Mapped[str]
    label_vi: Mapped[str]
    confidence: Mapped[float]
    bbox_x: Mapped[float]
    bbox_y: Mapped[float]
    bbox_w: Mapped[float]
    bbox_h: Mapped[float]
    ipa: Mapped[str]
    pos: Mapped[str]
    meaning_vi: Mapped[str]
    example_en: Mapped[str]
    example_vi: Mapped[str]
    topic: Mapped[str]
```

#### Task B3.2 — Cấu hình Alembic
```bash
alembic init alembic
# Cập nhật alembic/env.py để dùng async engine + import models
alembic revision --autogenerate -m "initial_schema"
alembic upgrade head
```

**✅ Verification Ngày 3**: `alembic upgrade head` chạy không lỗi, tables xuất hiện trong DB.

---

### **Ngày 4 — Thứ Sáu 23/10: Scan Service + API Endpoint**

**Mục tiêu**: `POST /scans` hoạt động end-to-end.

#### Task B4.1 — Scan Service
```
backend/app/modules/scan/
├── __init__.py
├── router.py        # FastAPI router
├── service.py       # Business logic
├── schemas.py       # Pydantic request/response cho API
└── errors.py        # ScanFailedError, QuotaExceededError...
```

**service.py** (theo scan README flow):
```python
class ScanService:
    async def create_scan(
        self, user_id: UUID, image_bytes: bytes, mime_type: str
    ) -> ScanResponse:
        # 1. Check quota atomically (Redis)
        # 2. Validate + resize ảnh (Pillow, max 1280px)
        # 3. Upload lên S3/R2
        # 4. Gọi GeminiClient.detect_objects()
        # 5. Validate + dedupe + limit 8 items
        # 6. Tra lemma trong words catalog
        # 7. Lưu Scan + ScanItem vào DB
        # 8. Tăng quota chỉ sau khi thành công
        # 9. Trả presigned URL + items
```

#### Task B4.2 — Router
```python
# router.py
router = APIRouter(prefix="/scans", tags=["scan"])

@router.get("/quota")
async def get_quota(current_user: User = Depends(require_ai_user)): ...

@router.post("", status_code=201)
async def create_scan(
    image: UploadFile,
    current_user: User = Depends(require_ai_user),
    service: ScanService = Depends()
): ...
```

#### Task B4.3 — Error Handling
Map `GeminiError` → HTTP responses:
| Exception | HTTP Code | Error Code |
|---|---|---|
| `GeminiTimeoutError` | 503 | `SCAN_FAILED` |
| `GeminiUnavailableError` | 503 | `AI_TEMPORARILY_UNAVAILABLE` |
| `GeminiQuotaExceededError` | 503 | `AI_TEMPORARILY_UNAVAILABLE` |
| `GeminiInvalidResponseError` (sau retry) | 503 | `SCAN_FAILED` |

**✅ Verification Ngày 4**: Gọi `POST /scans` với ảnh thật → nhận response có items.

---

### **Ngày 5 — Thứ Bảy 24/10: Auth Module + Quota/Redis**

**Mục tiêu**: Auth hoạt động (register/login/token), Redis quota tracking.

#### Task B5.1 — Auth Module
```
backend/app/modules/auth/
├── router.py    # POST /auth/register, /auth/login, /auth/refresh
├── service.py   # Hash password, tạo JWT, verify email
└── schemas.py   # RegisterRequest, LoginRequest, TokenResponse
```

#### Task B5.2 — Quota Management (Redis)
```python
# core/deps/quota.py
async def check_and_increment_scan_quota(
    user_id: UUID, redis: Redis
) -> None:
    key = f"scan_quota:{user_id}:{today()}"
    count = await redis.incr(key)
    if count == 1:
        await redis.expire(key, 86400)  # TTL 24h
    if count > settings.SCAN_QUOTA_PER_USER_DAILY:
        raise QuotaExceededError(remaining=0)
```

#### Task B5.3 — `require_ai_user` dependency
```python
# Kiểm tra: authenticated + email verified
async def require_ai_user(
    current_user: User = Depends(get_current_user)
) -> User:
    if not current_user.email_verified:
        raise EmailNotVerifiedError()
    return current_user
```

**✅ Verification Ngày 5**: Register → Login → lấy token → dùng token gọi `POST /scans`.

---

### **Ngày 6 — Chủ Nhật 25/10: Cập Nhật Tài Liệu + Flutter Core**

**Mục tiêu**: Tài liệu sạch, bắt đầu Flutter foundation.

#### Task D1 — Cập Nhật Tài Liệu (Backend)

| File | Thay đổi |
|---|---|
| [`project_review.md`](file:///d:/LapTrinhMoBa/do_an_moba/project_review.md) | Đổi "YOLO-World" → "Gemini API", cập nhật trạng thái Phase 1 |
| [`FileMap.md`](file:///d:/LapTrinhMoBa/do_an_moba/app_hoc_tieng_anh/FIleMap.md) | `integrations/detector/` → `integrations/gemini/`; bỏ dòng cấm gọi Gemini |
| [`backend/README.md`](file:///d:/LapTrinhMoBa/do_an_moba/backend_app/backend/README.md) | Stack: bỏ YOLO-World container, thêm Gemini API |
| [`integrations/README.md`](file:///d:/LapTrinhMoBa/do_an_moba/backend_app/backend/app/integrations/README.md) | Thêm adapter gemini, bỏ detector |
| `integrations/detector/README.md` | Đánh dấu deprecated → di chuyển sang `integrations/gemini/` |

#### Task F1 — Flutter Core Foundation

**Chọn State Management**: Riverpod (khuyến nghị vì null-safe, code gen, test-friendly)

```yaml
# pubspec.yaml additions
dependencies:
  flutter_riverpod: ^2.5
  riverpod_annotation: ^2.3
  go_router: ^14.2
  dio: ^5.7
  flutter_secure_storage: ^9.2
  cached_network_image: ^3.4

dev_dependencies:
  riverpod_generator: ^2.4
  build_runner: ^2.4
```

Tạo:
- `lib/core/theme/app_theme.dart` — MaterialTheme
- `lib/app/router.dart` — GoRouter với routes cơ bản
- `lib/app/app.dart` — `ProviderScope` + `MaterialApp.router`
- Sửa `lib/main.dart` — lỗi cú pháp, khởi động app

**✅ Verification Ngày 6**: Flutter `flutter run` không crash, splash screen hiện lên.

---

### **Ngày 7 — Thứ Hai 26/10: Integration Testing + Polish**

**Mục tiêu**: End-to-end test, đảm bảo pipeline scan hoạt động hoàn toàn.

#### Task T1 — Integration Test End-to-End
```
backend/tests/
├── integration/
│   └── test_scan_flow.py    # Test toàn bộ flow POST /scans
└── conftest.py              # Fixtures: test DB, mock Redis, mock Gemini
```

Test scenarios:
- ✅ Scan thành công với ảnh có vật thể → 201 + items
- ✅ Scan ảnh không có vật thể → 200 `status=no_object`, không trừ quota
- ✅ Gemini timeout → 503 `SCAN_FAILED`, không trừ quota
- ✅ Quota vượt 10 lần/ngày → 429 `SCAN_LIMIT_REACHED`
- ✅ User chưa xác minh email → 403 `EMAIL_NOT_VERIFIED`

#### Task T2 — Test Thực Tế với Gemini API
1. Lấy API key từ [Google AI Studio](https://aistudio.google.com/apikey)
2. Chạy script test manual:
```python
# tests/manual/test_real_gemini.py
import asyncio
from app.integrations.gemini.client import GeminiClient

async def test():
    client = GeminiClient()
    with open("tests/fixtures/test_apple.jpg", "rb") as f:
        image_bytes = f.read()
    results = await client.detect_objects(image_bytes)
    print(f"Found {len(results)} objects:")
    for obj in results:
        print(f"  - {obj.label} ({obj.confidence:.2f}): {obj.meaning_vi}")

asyncio.run(test())
```
3. Kiểm tra: latency < 5s, label chính xác, bounding box hợp lý

#### Task T3 — Xóa Folder `detector/` Cũ
```diff
- backend/app/integrations/detector/   # Toàn bộ folder
+ backend/app/integrations/gemini/     # Đã tạo từ Ngày 2
```

**✅ Verification Ngày 7**: Full integration test pass, real API call thành công.

---

## 📊 Tổng Quan Files Sẽ Tạo/Sửa

### Files MỚI
```
backend/
├── pyproject.toml
├── .env.example
├── docker-compose.yml
├── app/
│   ├── main.py
│   ├── core/
│   │   ├── config/
│   │   │   ├── __init__.py
│   │   │   └── settings.py                ← Ngày 1
│   │   ├── database.py                    ← Ngày 3
│   │   ├── models/
│   │   │   ├── base.py, user.py           ← Ngày 3
│   │   │   ├── scan.py, word.py           ← Ngày 3
│   │   └── deps/
│   │       ├── auth.py                    ← Ngày 5
│   │       └── quota.py                   ← Ngày 5
│   ├── integrations/
│   │   └── gemini/
│   │       ├── __init__.py                ← Ngày 2
│   │       ├── client.py                  ← Ngày 2
│   │       ├── prompts.py                 ← Ngày 2
│   │       ├── schemas.py                 ← Ngày 2
│   │       └── errors.py                  ← Ngày 2
│   └── modules/
│       ├── auth/
│       │   ├── router.py, service.py      ← Ngày 5
│       └── scan/
│           ├── router.py                  ← Ngày 4
│           ├── service.py                 ← Ngày 4
│           └── schemas.py                 ← Ngày 4
├── tests/
│   ├── integrations/
│   │   └── test_gemini_client.py          ← Ngày 2
│   └── integration/
│       └── test_scan_flow.py              ← Ngày 7
└── alembic/                               ← Ngày 3
```

### Files SỬA
```
project_review.md                          ← Ngày 6
app_hoc_tieng_anh/FIleMap.md              ← Ngày 6
backend_app/backend/README.md              ← Ngày 6
backend_app/backend/app/integrations/README.md ← Ngày 6
app_hoc_tieng_anh/pubspec.yaml             ← Ngày 6
app_hoc_tieng_anh/lib/main.dart            ← Ngày 6
```

### Files XÓA
```
backend/app/integrations/detector/         ← Ngày 7
```

---

## ⚠️ Vấn Đề Cần Xác Nhận Trước Khi Thực Hiện

> [!IMPORTANT]
> **1. Prompt Schema**: `gemini_api_integration_plan.md` dùng `label_vi + ipa + example_sentence`, nhưng `scan/README.md` yêu cầu thêm `pos + meaning_vi + example_en + example_vi + topic`. Kế hoạch này **ưu tiên dùng schema đầy đủ hơn** từ scan README — xác nhận không?

> [!IMPORTANT]
> **2. Storage**: Scan service cần upload ảnh lên S3/R2. Bạn đã có Cloudflare R2 / AWS S3 bucket chưa, hay cần mock tạm trong dev?

> [!IMPORTANT]
> **3. Email verification**: Auth module cần gửi email xác minh (Resend API). Bạn có API key Resend chưa, hay tạm thời bỏ qua bước này trong tuần đầu?

> [!WARNING]
> **4. Flutter State Management**: Kế hoạch đề xuất **Riverpod**. Nếu bạn ưa Bloc hơn, cần thay đổi cấu trúc `lib/features/`. Nên chốt trước khi bắt đầu Ngày 6.

---

## 📈 Verification Plan Tổng Thể

### Automated Tests
```bash
# Unit tests (Ngày 2)
cd backend && pytest tests/integrations/ -v

# Integration tests (Ngày 7)
cd backend && pytest tests/integration/ -v --cov=app --cov-report=html
```

### Manual Verification
1. `docker compose up` → tất cả containers healthy
2. `GET /health` → `{"status": "ok"}`
3. `POST /auth/register` → tạo user thành công
4. `POST /auth/login` → nhận JWT token
5. `POST /scans` (với token + ảnh thật) → nhận items từ Gemini
6. Flutter `flutter run` → app khởi động, không crash

---

## 🎯 Mục Tiêu Cuối Tuần

Cuối Thứ Hai 26/10, dự án sẽ có:
- ✅ Backend chạy được với Docker Compose
- ✅ Gemini API tích hợp hoàn chỉnh (thay YOLO-World)
- ✅ `POST /scans` hoạt động end-to-end thực tế
- ✅ Unit tests + integration tests pass
- ✅ Auth cơ bản (register/login)
- ✅ Tài liệu cập nhật chính xác
- ✅ Flutter app khởi động được (không crash)
