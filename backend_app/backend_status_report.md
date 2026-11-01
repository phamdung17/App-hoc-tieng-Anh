# 📊 Báo Cáo Trạng Thái Backend — 26/10/2026

## ✅ Đã Hoàn Thành

### Ngày 1 — Nền Tảng Backend
| File | Kích thước | Trạng thái |
|---|---|---|
| `backend/pyproject.toml` | 1.3KB | ✅ Đầy đủ dependencies |
| `backend/.env.example` | 2.8KB | ✅ Tất cả biến môi trường |
| `backend/Dockerfile` | 0.5KB | ✅ Python 3.11 + Poetry |
| `docker-compose.yml` (root) | 3.1KB | ✅ postgres + redis (không có yolo-world) |
| `app/__init__.py` | ✅ | |
| `app/main.py` | 3.1KB | ✅ FastAPI app + CORS + scan router đã đăng ký |
| `app/core/__init__.py` | ✅ | |
| `app/core/config/settings.py` | 5.3KB | ✅ Pydantic Settings v2, Gemini config |
| `app/core/config/__init__.py` | ✅ | |

### Ngày 2 — Gemini Integration (5/5 files ✅)
| File | Kích thước | Trạng thái |
|---|---|---|
| `integrations/gemini/__init__.py` | 0.7KB | ✅ Export đầy đủ |
| `integrations/gemini/errors.py` | 1.8KB | ✅ 5 exception classes |
| `integrations/gemini/schemas.py` | 3.7KB | ✅ Schema đầy đủ (pos, meaning_vi, example_vi...) |
| `integrations/gemini/prompts.py` | 2.4KB | ✅ 15 rules, topic enum |
| `integrations/gemini/client.py` | 9.7KB | ✅ Retry logic, safety filter, strip markdown |
| `tests/unit/test_gemini_client.py` | 13.6KB | ✅ 15 test cases (mock) |

### Ngày 3 — Database Schema
| File | Kích thước | Trạng thái |
|---|---|---|
| `app/core/database.py` | 2.4KB | ✅ Async engine + session |
| `app/core/models/base.py` | 0.7KB | ✅ TimestampMixin |
| `app/core/models/user.py` | 4.0KB | ✅ User model đầy đủ |
| `app/core/models/word.py` | 3.8KB | ✅ Word catalog model |
| `app/core/models/scan.py` | 7.4KB | ✅ Scan + ScanItem models |
| `app/core/models/__init__.py` | ✅ | |
| `alembic/env.py` | 3.6KB | ✅ Async Alembic config |
| `alembic.ini` | 0.9KB | ✅ |

> [!NOTE]
> Alembic `versions/` vẫn trống — chưa chạy `alembic revision --autogenerate`
> vì cần DB đang chạy. Sẽ chạy khi `docker compose up`.

### Ngày 4 — Scan Module (4/4 files ✅, nhưng có TODO)
| File | Kích thước | Trạng thái |
|---|---|---|
| `modules/scan/__init__.py` | ✅ | |
| `modules/scan/errors.py` | 1.8KB | ✅ Đủ domain errors |
| `modules/scan/schemas.py` | 1.6KB | ✅ Request/Response schemas |
| `modules/scan/service.py` | 15.5KB | ⚠️ Logic đủ nhưng có TODO |
| `modules/scan/router.py` | 4.4KB | ⚠️ Có TODO auth dependency |

---

## ⚠️ Đang Làm Dở — Cần Hoàn Thiện

### 1. `scan/service.py` — 4 TODO còn lại

| Dòng | TODO | Mô tả |
|---|---|---|
| 75 | `inject StorageClient, RedisClient` | Cần Ngày 5 (Redis quota) |
| 140 | `tăng quota Redis sau khi lưu thành công` | Chưa có Redis client |
| 148 | `đọc quota từ Redis` | `get_quota()` đang trả fake data |
| 208–219 | `_upload_image()` + `_get_presigned_url()` | Đang là placeholder string |

**Ảnh hưởng**: `POST /scans` có thể gọi được nhưng quota sẽ không đếm, ảnh sẽ không upload thật.

### 2. `scan/router.py` — Dòng 42

```python
# TODO: thay bằng require_ai_user thật từ auth module
async def get_current_ai_user() -> uuid.UUID:
    return uuid.UUID("00000000-...")   # ← UUID fake!
```

Mọi request đang chạy với user ID cứng. Cần module auth hoàn thiện.

### 3. `app/main.py` — Dòng 39

```python
# TODO: Khởi tạo DB engine + Redis pool ở đây
```

Lifespan hook chưa init DB/Redis — cần thêm sau khi có connection pool.

---

## ❌ Chưa Bắt Đầu

### Ngày 5 — Auth Module + Redis Quota
- [ ] `modules/auth/router.py` — POST /auth/register, /auth/login, /auth/refresh
- [ ] `modules/auth/service.py` — hash password, JWT, email verify
- [ ] `modules/auth/schemas.py` — RegisterRequest, LoginRequest, TokenResponse
- [ ] `core/deps/auth.py` — `get_current_user`, `require_ai_user`
- [ ] `core/deps/quota.py` — `check_and_increment_scan_quota` (Redis)

### Ngày 6 — Cập Nhật Tài Liệu + Flutter Core
- [ ] Cập nhật `project_review.md` (vẫn còn "YOLO-World" ở dòng 9, 28)
- [ ] Cập nhật `FileMap.md` — integrations/detector → integrations/gemini
- [ ] Flutter: `pubspec.yaml` — thêm riverpod, go_router
- [ ] Flutter: `lib/core/theme/app_theme.dart`
- [ ] Flutter: `lib/app/router.dart`
- [ ] Flutter: sửa `lib/main.dart` (có lỗi cú pháp)

### Ngày 7 — Integration Tests + Cleanup
- [ ] `tests/integration/test_scan_flow.py`
- [ ] Test thực với Gemini API key thật
- [ ] Xóa `integrations/detector/` folder cũ
- [ ] `alembic revision --autogenerate -m "initial_schema"`
- [ ] `alembic upgrade head`

---

## 📋 Tóm Tắt Nhanh

```
Ngày 1 — Nền tảng:       ████████████ 100% ✅
Ngày 2 — Gemini:          ████████████ 100% ✅
Ngày 3 — Database:        ████████░░░░  75% ⚠️  (chưa chạy migration)
Ngày 4 — Scan Service:    ██████████░░  80% ⚠️  (storage + quota là placeholder)
Ngày 5 — Auth + Redis:    ░░░░░░░░░░░░   0% ❌
Ngày 6 — Docs + Flutter:  ░░░░░░░░░░░░   0% ❌
Ngày 7 — Tests + Polish:  ██░░░░░░░░░░  15% (chỉ có unit tests)
```

**Việc tiếp theo quan trọng nhất**: **Ngày 5 — Auth Module + Redis Quota**,
vì đây là dependency để `POST /scans` chạy được với user thật.
