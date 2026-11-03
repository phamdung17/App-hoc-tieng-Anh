# BÁO CÁO KHẢO SÁT & THIẾT KẾ KỸ THUẬT BACKEND (FASTAPI & DATABASE)
## Module Survey Report: Settings, Docker, Alembic, Learning & Seed Data

**Thực hiện:** `explorer_survey_1` (teamwork_explorer)  
**Thời gian:** 03/11/2026  
**Chế độ:** Strict Read-Only Investigation  
**Phạm vi:** `backend_app/backend/` và cấu hình triển khai hạ tầng (`docker-compose.yml`)

---

## 1. TỔNG QUAN PHÁT HIỆN CHÍNH (EXECUTIVE FINDINGS)

Qua khảo sát toàn diện mã nguồn Backend FastAPI, hệ thống cấu hình, lược đồ cơ sở dữ liệu Alembic và các mô hình dữ liệu SQLAlchemy, nhóm khảo sát ghi nhận 4 điểm nghẽn kỹ thuật then chốt và xây dựng bản đặc tả thiết kế dữ liệu mẫu (Seed Data) chuẩn xác:

| Hạng mục khảo sát | Hiện trạng mã nguồn thực tế | Đánh giá tác động | Giải pháp kỹ thuật chuẩn hóa |
|---|---|---|---|
| **1. CORS_ORIGINS & Settings** | `CORS_ORIGINS: list[str]` trong `settings.py:31` đối chiếu với `.env:13` dạng chuỗi phân tách dấu phẩy. | 🔴 **FATAL P0** — Gây `JSONDecodeError` làm crash toàn bộ Backend ngay tại module import time. | Đổi kiểu thành `list[str] \| str` và nâng cấp validator `parse_cors_origins` xử lý cả chuỗi phẩy lẫn mảng JSON. |
| **2. Docker Compose** | `docker-compose.yml` trỏ `./backend` thay vì `./backend_app/backend`. | 🔴 **FATAL P0** — `docker compose up` thất bại 100% do thiếu ngữ cảnh thư mục và `.env`. | Sửa toàn bộ đường dẫn build context, `env_file`, volumes về `./backend_app/backend`. |
| **3. Alembic Dialect Conflict** | `alembic/env.py:39, 81` thay thế URL thành psycopg2 rồi truyền vào `async_engine_from_config`. | 🟡 **BLOCKER P1** — Ném `InvalidRequestError: asyncpg dialect required`, thiếu psycopg2. | Dùng trực tiếp `settings.DATABASE_URL` (asyncpg) trong `run_async_migrations`. |
| **4. Learning ↔ Progress Integration** | `submit_lesson` không gọi `record_activity`, đồng thời phát hiện nguy cơ cộng trùng XP. | 🟡 **BLOCKER P1** — Bảng `user_daily_activities` rỗng, streak và calendar không cập nhật. | Gọi `ProgressService.record_activity`, bỏ `update(User)` dư thừa trong `submit_lesson` tránh double XP. |
| **5. Seed Data Architecture** | Bảng `learning_paths`, `units`, `lessons`, `words` hiện có 0 bản ghi thật. | 🟡 **GAP R3** — Frontend không có dữ liệu thật để hiển thị lộ trình học và từ vựng. | Thiết kế kịch bản seeder nạp 2 Paths, 5 Units, 9 Lessons (đủ 5 dạng bài tập), 28 Words (4 topics). |

---

## 2. CHI TIẾT KHẢO SÁT & GIẢI PHÁP TỪNG HẠNG MỤC

### 2.1. Khảo sát Cấu hình Settings & `CORS_ORIGINS` (Lỗi Chặn P0-1)

#### A. Đối chiếu mã nguồn thực tế
1. **Tại `backend_app/backend/app/core/config/settings.py` (dòng 31, 34–40):**
   ```python
   # Line 31:
   CORS_ORIGINS: list[str] = ["http://localhost:3000"]

   # Lines 34-40:
   @field_validator("CORS_ORIGINS", mode="before")
   @classmethod
   def parse_cors_origins(cls, v: str | list[str]) -> list[str]:
       """Chấp nhận chuỗi phân tách bằng dấu phẩy hoặc list."""
       if isinstance(v, str):
           return [origin.strip() for origin in v.split(",") if origin.strip()]
       return v
   ```

2. **Tại `backend_app/backend/.env` (dòng 13):**
   ```bash
   CORS_ORIGINS=http://localhost:3000,http://localhost:8000
   ```

3. **Tại `backend_app/backend/app/core/config/settings.py` (dòng 120):**
   ```python
   settings: Settings = get_settings()
   ```

#### B. Cơ chế sinh lỗi (Root Cause Analysis)
- Trong Pydantic Settings v2 (`pydantic_settings`), khi một trường được khai báo với kiểu phức tạp (chẳng hạn `list[str]`), bộ nạp môi trường (`DotEnvSettingsSource` / `EnvSettingsSource`) sẽ tự động giả định giá trị môi trường là một chuỗi JSON hợp lệ và gọi `json.loads(raw_value)` **trước khi** dữ liệu được chuyển đến bất kỳ hàm validator nào (`mode="before"`).
- Chuỗi `http://localhost:3000,http://localhost:8000` trong file `.env` không phải là định dạng JSON mảng (không có cặp ngoặc vuông `[...]` và dấu ngoặc kép `"` bao quanh từng phần tử).
- Do đó, phương thức `json.loads()` lập tức ném ngoại lệ:
  ```text
  pydantic_settings.exceptions.SettingsError: error parsing value for field "CORS_ORIGINS" from source "DotEnvSettingsSource"
  json.decoder.JSONDecodeError: Expecting value: line 1 column 1 (char 0)
  ```
- Vì `settings: Settings = get_settings()` được khởi tạo ngay tại cấp độ module (module-level singleton), bất kỳ tệp nào import `settings` (bao gồm `app.main`, `GeminiClient`, router, và toàn bộ test suites `pytest`) đều bị crash ngay lập tức tại thời điểm nạp mã.

#### C. Giải pháp khắc phục khuyến nghị
Mở rộng kiểu dữ liệu tại trường định nghĩa để Pydantic nhận diện kiểu chuỗi thuần túy (`str`) là kiểu dữ liệu hợp lệ trước khi phân giải, từ đó chuyển giao trực tiếp chuỗi gốc cho validator:
```python
# Sửa tại: backend_app/backend/app/core/config/settings.py (dòng 31–41)

CORS_ORIGINS: list[str] | str = ["http://localhost:3000"]

@field_validator("CORS_ORIGINS", mode="before")
@classmethod
def parse_cors_origins(cls, v: Any) -> list[str]:
    """Chấp nhận chuỗi phân tách bằng dấu phẩy, mảng JSON hoặc list[str]."""
    if isinstance(v, str):
        v_str = v.strip()
        if v_str.startswith("[") and v_str.endswith("]"):
            try:
                import json
                parsed = json.loads(v_str)
                if isinstance(parsed, list):
                    return [str(origin).strip() for origin in parsed if str(origin).strip()]
            except Exception:
                pass
        return [origin.strip() for origin in v_str.split(",") if origin.strip()]
    if isinstance(v, (list, tuple, set)):
        return [str(origin).strip() for origin in v if str(origin).strip()]
    return v
```

---

### 2.2. Khảo sát Cấu hình `docker-compose.yml` (Lỗi Chặn P0-4)

#### A. Đối chiếu mã nguồn thực tế
Tại file `docker-compose.yml` ở thư mục gốc dự án:
- Dòng 13: `context: ./backend`
- Dòng 19: `env_file: - ./backend/.env`
- Dòng 30: `volumes: - ./backend:/app`
- Dòng 71 (worker commented): `context: ./backend`
- Dòng 75 (worker commented): `env_file: - ./backend/.env`
- Dòng 5 (comment hướng dẫn): `cp backend/.env.example backend/.env`

#### B. Cơ chế sinh lỗi (Root Cause Analysis)
Cấu trúc thư mục thực tế của repository là `backend_app/backend/`. Không tồn tại thư mục `./backend` tại thư mục gốc. Khi chạy lệnh `docker compose up -d --build`, Docker daemon sẽ dừng khẩn cấp với thông báo:
```text
ERROR: failed to solve: failed to read dockerfile: open /var/lib/docker/tmp/.../backend/Dockerfile: no such file or directory
# hoặc
open ./backend/.env: no such file or directory
```

#### C. Giải pháp khắc phục khuyến nghị
Cập nhật toàn bộ các tham chiếu đường dẫn trong `docker-compose.yml`:
```yaml
# Sửa tại: docker-compose.yml
services:
  backend:
    build:
      context: ./backend_app/backend
      dockerfile: Dockerfile
    container_name: english_ai_backend
    ports:
      - "8000:8000"
    env_file:
      - ./backend_app/backend/.env
    environment:
      - DATABASE_URL=postgresql+asyncpg://postgres:password@postgres:5432/english_ai
      - REDIS_URL=redis://redis:6379/0
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    volumes:
      - ./backend_app/backend:/app   # Hot reload trong dev
    command: uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
    restart: unless-stopped
```

---

### 2.3. Khảo sát Cấu hình Dialect trong `alembic/env.py` (Lỗi Chặn P1-3)

#### A. Đối chiếu mã nguồn thực tế
Tại `backend_app/backend/alembic/env.py`:
- Dòng 39–41:
  ```python
  _sync_url = settings.DATABASE_URL.replace(
      "postgresql+asyncpg://", "postgresql+psycopg2://"
  )
  ```
- Dòng 80–87 trong hàm `run_async_migrations()`:
  ```python
  async def run_async_migrations() -> None:
      """Chạy migration với async engine."""
      configuration = config.get_section(config.config_ini_section, {})
      configuration["sqlalchemy.url"] = _sync_url

      connectable = async_engine_from_config(
          configuration,
          prefix="sqlalchemy.",
          poolclass=pool.NullPool,
      )
  ```

#### B. Cơ chế sinh lỗi (Root Cause Analysis)
1. Trong SQLAlchemy 2.0, hàm `async_engine_from_config` khởi tạo một `AsyncEngine`. Engine bất đồng bộ này **bắt buộc** phải sử dụng driver DBAPI bất đồng bộ tương thích (ở đây là dialect `asyncpg`).
2. Việc cố tình gán `_sync_url` (vốn đã bị chuyển đổi tiền tố thành `postgresql+psycopg2://`) vào cấu hình của `async_engine_from_config` khiến SQLAlchemy ném lỗi nghiêm trọng:
   ```text
   sqlalchemy.exc.InvalidRequestError: The asyncpg dialect is required for async engines, got psycopg2
   ```
3. Ngoài ra, thư viện `psycopg2` thậm chí **không hề được khai báo** trong danh sách dependencies của `pyproject.toml` (dự án định hướng 100% async với `asyncpg = "^0.30"`). Nếu hệ thống cố import psycopg2, lỗi `ModuleNotFoundError: No module named 'psycopg2'` sẽ xuất hiện.

#### C. Giải pháp khắc phục khuyến nghị
Sử dụng trực tiếp `settings.DATABASE_URL` (vốn đã có dialect `postgresql+asyncpg://`) cho `run_async_migrations`:
```python
# Sửa tại: backend_app/backend/alembic/env.py

# Dòng 39-41 (offline mode url):
_offline_url = settings.DATABASE_URL.replace("+asyncpg", "")

def run_migrations_offline() -> None:
    context.configure(
        url=_offline_url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
        compare_type=True,
        compare_server_default=True,
    )
    with context.begin_transaction():
        context.run_migrations()

async def run_async_migrations() -> None:
    """Chạy migration với async engine (asyncpg)."""
    configuration = config.get_section(config.config_ini_section, {})
    # Sử dụng trực tiếp asyncpg URL từ settings
    configuration["sqlalchemy.url"] = settings.DATABASE_URL

    connectable = async_engine_from_config(
        configuration,
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )

    async with connectable.connect() as connection:
        await connection.run_sync(do_run_migrations)

    await connectable.dispose()
```

---

### 2.4. Khảo sát Tích Hợp `submit_lesson` & `record_activity` (Lỗi Chặn P1-2)

#### A. Đối chiếu mã nguồn thực tế
1. **Tại `backend_app/backend/app/modules/learning/service.py` (dòng 328–378):**
   ```python
   # 4. Cộng XP vào user
   if xp_earned > 0:
       await self.db.execute(
           update(User)
           .where(User.id == user_id)
           .values(xp_total=User.xp_total + xp_earned)
       )

   # 5. Update / create progress record
   ...
   # 6. Unlock bài tiếp theo
   ...
   # Lấy xp_total mới nhất và streak_days
   user_result = await self.db.execute(
       select(User.xp_total, User.streak_days).where(User.id == user_id)
   )
   row = user_result.one_or_none()
   new_total_xp = row.xp_total if row else 0
   streak_days = row.streak_days if row else 0

   await self.db.commit()
   ```

2. **Tại `backend_app/backend/app/modules/progress/service.py` (dòng 157–225):**
   ```python
   async def record_activity(
       self,
       user_id: uuid.UUID,
       xp_earned: int,
       lessons_completed: int = 1,
       minutes_studied: int = 5,
   ) -> None:
       ...
       # Upsert UserDailyActivity hôm nay
       ...
       if user is not None:
           # Tính streak và cập nhật last_activity_date
           ...
           # DÒNG 223: CỘNG XP TỔNG!
           user.xp_total += xp_earned

       await self._db.flush()
   ```

#### B. Phát hiện mấu chốt & Nguy cơ Cộng Trùng XP (Double XP Vulnerability)
1. **Hậu quả của hiện trạng:**
   - Hàm `submit_lesson` không gọi `record_activity`. Do đó bảng `user_daily_activities` luôn có 0 bản ghi.
   - `User.streak_days` không bao giờ được tăng lên.
   - API `/progress/summary` và `/progress/calendar` trả về dữ liệu rỗng.
2. **Cảnh báo cực kỳ quan trọng cho người cài đặt (Implementer Warning):**
   - Lưu ý dòng 223 của `app/modules/progress/service.py`: `user.xp_total += xp_earned`.
   - Nếu trong `submit_lesson`, lập trình viên vừa giữ nguyên câu lệnh SQL:
     `await self.db.execute(update(User).where(User.id == user_id).values(xp_total=User.xp_total + xp_earned))`
     vừa gọi thêm `await progress_service.record_activity(...)`, thì số điểm kinh nghiệm `xp_earned` sẽ **bị cộng dồn 2 lần (Double XP)**!
3. **Cơ chế hoạt động đúng chuẩn:**
   - `LearningService` và `ProgressService` đều sử dụng cùng một phiên làm việc cơ sở dữ liệu `AsyncSession` (`self.db`).
   - Loại bỏ câu lệnh SQL `update(User)` riêng lẻ tại `submit_lesson`.
   - Ủy thác toàn bộ việc ghi nhận hoạt động ngày, tăng số bài học hoàn thành, tính chuỗi Streak và cộng điểm kinh nghiệm `User.xp_total` cho `ProgressService.record_activity`.
   - Sau khi `record_activity` gọi `await self._db.flush()`, câu lệnh `select(User.xp_total, User.streak_days)` ở cuối hàm `submit_lesson` sẽ đọc được chính xác dữ liệu vừa cập nhật để phản hồi cho client.

#### C. Giải pháp khắc phục khuyến nghị
```python
# Sửa tại: backend_app/backend/app/modules/learning/service.py

# Thêm import ở đầu file:
from app.modules.progress.service import ProgressService

# Trong hàm submit_lesson:
# Thay thế khối '4. Cộng XP vào user' (dòng 328-335) bằng lời gọi record_activity:

is_first_completion = passed and not was_completed

# Ghi nhận hoạt động vào user_daily_activities, cập nhật streak_days & xp_total
progress_service = ProgressService(self.db)
await progress_service.record_activity(
    user_id=user_id,
    xp_earned=xp_earned,
    lessons_completed=1 if is_first_completion else 0,
    minutes_studied=max(1, time_spent_seconds // 60),
)
```

> **Khuyến nghị bổ sung:** Trong hàm `get_path_detail` (`learning/service.py:174`), cần bổ sung thêm lời gọi `await self._ensure_first_lesson_available(path_id, user_id)` (tương tự như trong `list_paths`), đảm bảo khi người dùng truy cập trực tiếp vào chi tiết một lộ trình học, bài học đầu tiên luôn ở trạng thái `available` thay vì `locked`.

---

## 3. THIẾT KẾ ĐẶC TẢ DỮ LIỆU MẪU (SEED DATA ARCHITECTURE)

Yêu cầu theo `ORIGINAL_REQUEST.md`: Tạo kịch bản nạp dữ liệu mẫu ban đầu gồm 1–2 lộ trình học (Learning Paths), mỗi lộ trình 2–3 Units, các bài học mẫu kèm đầy đủ 5 dạng bài tập tương tác, và 20–30 từ vựng theo chủ đề.

### 3.1. Phân Tích Mô Hình Dữ Liệu & Ràng Buộc CSDL

| Bảng CSDL | Model Class SQLAlchemy | Các trường bắt buộc & Kiểu dữ liệu | Quan hệ Khóa ngoại & Index |
|---|---|---|---|
| `learning_paths` | `LearningPath` (`app/core/models/learning.py`) | `id` (UUID, PK)<br>`title` (String 100)<br>`level` (String 10, e.g. "A1", "A2")<br>`is_active` (Boolean, default True)<br>`thumbnail_url` (String 500, optional)<br>`description` (Text, optional) | 1-N tới `units` (`back_populates="path"`, cascade delete) |
| `units` | `Unit` (`app/core/models/learning.py`) | `id` (UUID, PK)<br>`path_id` (UUID, FK `learning_paths.id`)<br>`title` (String 100)<br>`order_index` (Integer)<br>`description` (Text, optional) | FK `learning_paths.id` on delete CASCADE. Index `ix_units_path_id`. 1-N tới `lessons`. |
| `lessons` | `Lesson` (`app/core/models/learning.py`) | `id` (UUID, PK)<br>`unit_id` (UUID, FK `units.id`)<br>`title` (String 100)<br>`lesson_type` (String 20: "vocabulary", "grammar", "listening", "speaking")<br>`xp_reward` (Integer, e.g. 15, 20)<br>`order_index` (Integer)<br>`icon_name` (String 50, e.g. "book-open", "coffee")<br>`content_data` (JSONB: chứa mảng exercises) | FK `units.id` on delete CASCADE. Index `ix_lessons_unit_id`. |
| `words` | `Word` (`app/core/models/word.py`) | `id` (UUID, PK)<br>`lemma` (String 50, UNIQUE, lowercase)<br>`ipa` (String 50)<br>`pos` (String 20: "noun", "verb", "adj")<br>`meaning_vi` (Text)<br>`example_en` (Text)<br>`example_vi` (Text)<br>`topic` (String 50: "greeting", "food", "travel", "daily")<br>`is_seeded` (Boolean=True)<br>`is_ai_generated` (Boolean=False) | Unique index `ix_words_lemma`. Không dùng bảng riêng cho Topic; endpoint `/vocab/topics` tự động `SELECT DISTINCT topic FROM words`. |

---

### 3.2. Cấu Trúc Chi Tiết 5 Dạng Bài Tập Trong `content_data` JSONB

Cấu trúc JSON trong trường `content_data` của bảng `lessons` được chuẩn hóa theo định dạng `{ "exercises": [ ... ] }` tương thích hoàn toàn với các widget của Flutter:

```json
{
  "exercises": [
    {
      "id": "ex_choice_01",
      "type": "choice",
      "prompt": "Chọn nghĩa đúng của từ sau:",
      "targetWord": "Student",
      "ipa": "/ˈstjuː.dənt/",
      "options": [
        {"text": "Giáo viên"},
        {"text": "Học sinh, sinh viên"},
        {"text": "Bác sĩ"},
        {"text": "Kỹ sư"}
      ],
      "correctOptionIndex": 1,
      "explanation": "\"Student\" có nghĩa là học sinh hoặc sinh viên."
    },
    {
      "id": "ex_wordbank_01",
      "type": "wordBank",
      "prompt": "Sắp xếp các từ để hoàn thành câu:",
      "vietnameseSentence": "Tôi là một học sinh.",
      "correctWords": ["I", "am", "a", "student"],
      "availableWords": ["a", "am", "teacher", "I", "student", "is", "very"],
      "explanation": "Cấu trúc: I + am + a/an + danh từ nghề nghiệp."
    },
    {
      "id": "ex_match_01",
      "type": "matchPairs",
      "prompt": "Ghép các cặp từ tương ứng:",
      "pairs": [
        {"english": "Hello", "vietnamese": "Xin chào"},
        {"english": "Goodbye", "vietnamese": "Tạm biệt"},
        {"english": "Thank you", "vietnamese": "Cảm ơn"},
        {"english": "Friend", "vietnamese": "Bạn bè"}
      ],
      "explanation": "Các cặp từ chào hỏi và giao tiếp cơ bản."
    },
    {
      "id": "ex_listen_01",
      "type": "listening",
      "prompt": "Nghe và điền từ còn thiếu:",
      "audioText": "I am a student",
      "answer": "student"
    },
    {
      "id": "ex_speak_01",
      "type": "speaking",
      "prompt": "Đọc câu sau thành tiếng:",
      "phrase": "Nice to meet you"
    }
  ]
}
```

---

### 3.3. Thiết Kế Bộ Dữ Liệu Lộ Trình Học Mẫu (Learning Paths & Units & Lessons)

Nhóm thiết kế đề xuất tạo **2 Lộ trình học (Learning Paths)** hoàn chỉnh với định danh Deterministic UUID (sử dụng UUIDv5 dựa trên namespace để đảm bảo tính Idempotent khi chạy seed nhiều lần không sinh bản ghi trùng lặp):

```
LỘ TRÌNH 1: Tiếng Anh Giao Tiếp Cơ Bản (Level A1)
├── UNIT 1: Chào hỏi & Làm quen (order_index=1)
│   ├── Lesson 1.1: Chào hỏi cơ bản (order=1, xp=15, type=vocabulary)
│   │   └── Exercises: choice, matchPairs, wordBank
│   ├── Lesson 1.2: Giới thiệu bản thân (order=2, xp=20, type=vocabulary)
│   │   └── Exercises: choice, wordBank, matchPairs, listening, speaking
│   └── Lesson 1.3: Luyện nghe & Ôn tập Unit 1 (order=3, xp=25, type=listening)
│       └── Exercises: listening, speaking, wordBank
├── UNIT 2: Đồ ăn & Thức uống (order_index=2)
│   ├── Lesson 2.1: Thực phẩm hàng ngày (order=1, xp=20, type=vocabulary)
│   │   └── Exercises: choice, matchPairs, wordBank
│   └── Lesson 2.2: Đặt món tại quán (order=2, xp=25, type=speaking)
│       └── Exercises: speaking, choice, wordBank
└── UNIT 3: Đời sống Hàng ngày (order_index=3)
    ├── Lesson 3.1: Đồ vật trong gia đình (order=1, xp=20, type=vocabulary)
    │   └── Exercises: choice, matchPairs
    └── Lesson 3.2: Thói quen sinh hoạt (order=2, xp=25, type=grammar)
        └── Exercises: wordBank, choice, listening

LỘ TRÌNH 2: Tiếng Anh Sơ Cấp (Level A2)
├── UNIT 1: Du lịch & Phương tiện (order_index=1)
│   ├── Lesson 1.1: Hỏi đường đi (order=1, xp=25, type=speaking)
│   │   └── Exercises: choice, wordBank, speaking
│   └── Lesson 1.2: Tại sân bay & ga tàu (order=2, xp=25, type=listening)
│       └── Exercises: listening, matchPairs, wordBank
└── UNIT 2: Mua sắm & Giá cả (order_index=2)
    └── Lesson 2.1: Mua sắm tại siêu thị (order=1, xp=25, type=vocabulary)
        └── Exercises: choice, matchPairs, wordBank
```

**Thống kê:**
- **2** Lộ trình học (Paths)
- **5** Đơn vị bài học (Units)
- **9** Bài học chi tiết (Lessons)
- **32** Bài tập tương tác (Exercises) phân bổ đủ 5 loại.

---

### 3.4. Thiết Kế Bộ Từ Vựng Mẫu (Vocabulary Catalog — 28 Từ Chuẩn)

Bảng phân bổ 28 từ vựng thuộc 4 chủ đề thiết thực, có đầy đủ phiên âm quốc tế IPA, từ loại, định nghĩa tiếng Việt chuẩn xác và cặp ví dụ câu song ngữ:

| STT | Lemma (Key) | IPA | Part of Speech | Topic | Nghĩa tiếng Việt (`meaning_vi`) | Ví dụ tiếng Anh (`example_en`) | Dịch ví dụ (`example_vi`) |
|:---:|---|---|:---:|:---:|---|---|---|
| **Chủ đề 1: `greeting` (Chào hỏi & Làm quen)** |
| 1 | `hello` | `/həˈloʊ/` | noun | greeting | Lời chào thân thiện khi gặp mặt | Hello, how are you today? | Xin chào, hôm nay bạn thế nào? |
| 2 | `goodbye` | `/ˌɡʊdˈbaɪ/` | noun | greeting | Lời chào tạm biệt khi chia tay | Goodbye, see you tomorrow! | Tạm biệt, hẹn gặp lại bạn ngày mai! |
| 3 | `student` | `/ˈstuː.dənt/` | noun | greeting | Học sinh, sinh viên đang đi học | She is a university student. | Cô ấy là một sinh viên đại học. |
| 4 | `teacher` | `/ˈtiː.tʃər/` | noun | greeting | Giáo viên, người giảng dạy | My teacher is very helpful. | Giáo viên của tôi rất nhiệt tình giúp đỡ. |
| 5 | `friend` | `/frend/` | noun | greeting | Bạn bè, người bạn quen biết thân thiết | A good friend is always by your side. | Một người bạn tốt luôn ở bên cạnh bạn. |
| 6 | `name` | `/neɪm/` | noun | greeting | Tên gọi của một người hoặc sự vật | What is your name? | Tên của bạn là gì? |
| 7 | `welcome` | `/ˈwel.kəm/` | verb | greeting | Chào mừng, đón tiếp nồng hậu | Welcome to our English class! | Chào mừng bạn đến với lớp học tiếng Anh! |
| **Chủ đề 2: `food` (Thực phẩm & Ăn uống)** |
| 8 | `bread` | `/bred/` | noun | food | Bánh mì làm từ bột nướng | I eat bread with eggs for breakfast. | Tôi ăn bánh mì với trứng cho bữa sáng. |
| 9 | `milk` | `/mɪlk/` | noun | food | Sữa tươi giàu dinh dưỡng | Drinking milk helps build strong bones. | Uống sữa giúp phát triển xương chắc khỏe. |
| 10 | `water` | `/ˈwɑː.tər/` | noun | food | Nước uống tinh khiết không màu | Drink enough water every day. | Hãy uống đủ nước mỗi ngày. |
| 11 | `apple` | `/ˈæp.əl/` | noun | food | Quả táo vỏ đỏ hoặc xanh | An apple a day keeps the doctor away. | Mỗi ngày một quả táo giúp tránh xa bác sĩ. |
| 12 | `coffee` | `/ˈkɔː.fi/` | noun | food | Cà phê, thức uống thơm giúp tỉnh táo | He drinks hot coffee every morning. | Anh ấy uống cà phê nóng mỗi sáng. |
| 13 | `rice` | `/raɪs/` | noun | food | Cơm, hạt gạo nấu chín | Rice is the staple food in Vietnam. | Cơm là món ăn chính tại Việt Nam. |
| 14 | `tea` | `/tiː/` | noun | food | Trà, nước hãm lá chè | Would you like a cup of green tea? | Bạn có muốn dùng một tách trà xanh không? |
| **Chủ đề 3: `travel` (Du lịch & Phương tiện)** |
| 15 | `airport` | `/ˈer.pɔːrt/` | noun | travel | Sân bay, phi trường cất hạ cánh máy bay | We arrived at the airport two hours early. | Chúng tôi đến sân bay trước hai tiếng. |
| 16 | `hotel` | `/hoʊˈtel/` | noun | travel | Khách sạn phục vụ lưu trú | They booked a room at a seaside hotel. | Họ đã đặt phòng tại một khách sạn ven biển. |
| 17 | `ticket` | `/ˈtɪk.ɪt/` | noun | travel | Vé đi xe, vé máy bay hoặc vé vào cửa | Please show your flight ticket at the gate. | Vui lòng xuất trình vé máy bay tại cửa khởi hành. |
| 18 | `passport` | `/ˈpæs.pɔːrt/` | noun | travel | Hộ chiếu do chính phủ cấp để xuất nhập cảnh | Keep your passport in a safe place. | Hãy giữ hộ chiếu ở nơi an toàn. |
| 19 | `street` | `/striːt/` | noun | travel | Con đường, phố xá trong đô thị | Walk along this street to find the station. | Đi dọc con đường này để tìm nhà ga. |
| 20 | `map` | `/mæp/` | noun | travel | Bản đồ chỉ đường | She used a digital map to navigate the city. | Cô ấy dùng bản đồ số để tìm đường trong thành phố. |
| 21 | `luggage` | `/ˈlʌɡ.ɪdʒ/` | noun | travel | Hành lý, vali chứa đồ khi đi xa | Pack your luggage before the trip. | Hãy xếp gọn hành lý trước chuyến đi. |
| **Chủ đề 4: `daily` (Đời sống & Đồ vật quanh ta)** |
| 22 | `house` | `/haʊs/` | noun | daily | Ngôi nhà ở gia đình | They live in a small comfortable house. | Họ sống trong một ngôi nhà nhỏ tiện nghi. |
| 23 | `book` | `/bʊk/` | noun | daily | Quyển sách chứa chữ viết hoặc hình ảnh | Reading a good book opens your mind. | Đọc một quyển sách hay giúp mở rộng tâm trí. |
| 24 | `phone` | `/foʊn/` | noun | daily | Điện thoại di động liên lạc | She answered a phone call from her father. | Cô ấy nghe cuộc gọi điện thoại từ bố. |
| 25 | `clock` | `/klɑːk/` | noun | daily | Đồng hồ treo tường hoặc để bàn | The wall clock shows nine o'clock. | Chiếc đồng hồ treo tường chỉ đúng 9 giờ. |
| 26 | `chair` | `/tʃer/` | noun | daily | Chiếc ghế ngồi có lưng tựa | Please take a seat on this chair. | Xin mời ngồi vào chiếc ghế này. |
| 27 | `table` | `/ˈteɪ.bəl/` | noun | daily | Chiếc bàn làm việc hoặc bàn ăn | The books are neatly placed on the table. | Sách được xếp ngay ngắn trên mặt bàn. |
| 28 | `window` | `/ˈwɪn.doʊ/` | noun | daily | Cửa sổ thông gió lấy ánh sáng | Open the window to let fresh air in. | Hãy mở cửa sổ để đón không khí trong lành. |

---

### 3.5. Kiến Trúc Kịch Bản Nạp Dữ Liệu (`scripts/seed_db.py` hoặc `app/seed_data/seeder.py`)

Kịch bản nạp dữ liệu cần được lập trình như một module độc lập có thể chạy trực tiếp bằng lệnh terminal (CLI):
```bash
python -m app.seed_data.seeder
# hoặc
uv run python scripts/seed_db.py
```

**Nguyên tắc thiết kế script:**
1. **Idempotent (Chạy nhiều lần không trùng dữ liệu):**
   - Với `Word`: Sử dụng `SELECT` theo lemma trước khi `INSERT`, hoặc dùng câu lệnh `insert(Word).on_conflict_do_nothing(index_elements=['lemma'])`.
   - Với `LearningPath`, `Unit`, `Lesson`: Sử dụng Deterministic UUID (hoặc tra cứu theo `title` / `order_index` trong cùng phạm vi cha).
2. **Transaction Integrity:** Toàn bộ quá trình nạp dữ liệu chạy trong một `async with session.begin():`, nếu có bất kỳ lỗi nào xảy ra sẽ rollback hoàn toàn để không để lại dữ liệu rác.
3. **Execution Reporting:** In ra console tổng số lượng Path, Unit, Lesson, và Word đã được thêm mới hoặc bỏ qua.

---

## 4. KẾ HÀCH HÀNH ĐỘNG DÀNH CHO CÁC NHÓM TIẾP THEO (IMPLEMENTATION ROADMAP)

```
                       LỘ TRÌNH THỰC THI BACKEND
  ┌────────────────────────────────────────────────────────────────────────┐
  │ 1. [Fix P0-1] settings.py: Sửa CORS_ORIGINS list[str] | str            │
  │ 2. [Fix P0-4] docker-compose.yml: Đổi ./backend -> ./backend_app/backend│
  │ 3. [Fix P1-3] alembic/env.py: Bỏ psycopg2, dùng settings.DATABASE_URL │
  │ 4. [Fix P1-2] learning/service.py: submit_lesson gọi record_activity   │
  │ 5. [Build R3] Viết seeder.py nạp 2 Paths, 5 Units, 9 Lessons, 28 Words │
  │ 6. [Build R4] Viết pytest: test_settings, test_submit_lesson, test_seed│
  └────────────────────────────────────────────────────────────────────────┘
```

1. **Bước 1 (Implementer Backend):**
   - Áp dụng bản vá cho `settings.py` (CORS).
   - Áp dụng bản vá cho `docker-compose.yml`.
   - Áp dụng bản vá cho `alembic/env.py`.
   - Cập nhật `submit_lesson` trong `learning/service.py` gọi `record_activity` và loại bỏ lệnh cộng XP trùng lặp.
2. **Bước 2 (Seed Data Creator):**
   - Hiện thực hóa file `backend_app/backend/app/seed_data/seeder.py` nạp đúng 28 từ vựng và 2 lộ trình học theo bảng đặc tả ở Mục 3.
3. **Bước 3 (QA / Test Engineer):**
   - Bổ sung các bài kiểm thử tự động `pytest`:
     - `test_settings_cors.py`: Kiểm tra nạp chuỗi `.env` phân tách dấu phẩy không bị lỗi.
     - `test_learning_submit_activity.py`: Kiểm tra nộp bài học tăng streak, ghi nhận vào `user_daily_activities` và cộng đúng 1 lần XP.
     - `test_alembic_async.py`: Kiểm tra chạy `alembic upgrade head` trên async engine thành công.
