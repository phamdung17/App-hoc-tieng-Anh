"""
app/db/seeds.py

Kịch bản nạp dữ liệu mẫu ban đầu (Seed Data) chuẩn hóa cho LingoUp:
  - 2 Lộ trình học (Learning Paths): A1 (3 Units) và A2 (2 Units)
  - 5 Units với 9 Bài học (Lessons) chi tiết
  - 30+ Bài tập tương tác (Exercises) phủ đủ 5 loại:
      * choice
      * wordBank
      * matchPairs
      * listening
      * speaking
  - 30 Từ vựng mẫu (Words) chia thành 4 chủ đề: greeting, food, travel, daily
  - Đảm bảo tính Idempotent tuyệt đối nhờ Deterministic UUID (uuid5) và logic upsert an toàn.
"""

from __future__ import annotations

import asyncio
import logging
import uuid
from typing import Any

from sqlalchemy import or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import AsyncSessionLocal
from app.core.models.learning import LearningPath, Lesson, Unit
from app.core.models.word import Word

logger = logging.getLogger("app.db.seeds")

# Stable namespace for deterministic UUID generation across environments
SEED_NAMESPACE = uuid.UUID("e7c65306-69a4-4ea8-b808-8df07d1a2935")


def deterministic_uuid(key: str) -> uuid.UUID:
    """Tạo UUID v5 tất định dựa trên khóa ổn định, đảm bảo seed không sinh bản ghi trùng."""
    return uuid.uuid5(SEED_NAMESPACE, key)


# ─────────────────────────────────────────────────────────────────────────────
# 1. DANH SÁCH TỪ VỰNG MẪU (30 WORDS TRÊN 4 CHỦ ĐỀ)
# ─────────────────────────────────────────────────────────────────────────────

SEED_WORDS: list[dict[str, Any]] = [
    # ── Chủ đề 1: greeting (7 từ) ─────────────────────────────────────────────
    {
        "id": deterministic_uuid("word:hello"),
        "lemma": "hello",
        "ipa": "/həˈloʊ/",
        "pos": "noun",
        "meaning_vi": "Lời chào thân thiện khi gặp mặt",
        "example_en": "Hello, how are you today?",
        "example_vi": "Xin chào, hôm nay bạn thế nào?",
        "topic": "greeting",
        "is_seeded": True,
        "is_ai_generated": False,
    },
    {
        "id": deterministic_uuid("word:goodbye"),
        "lemma": "goodbye",
        "ipa": "/ˌɡʊdˈbaɪ/",
        "pos": "noun",
        "meaning_vi": "Lời chào tạm biệt khi chia tay",
        "example_en": "Goodbye, see you tomorrow!",
        "example_vi": "Tạm biệt, hẹn gặp lại bạn ngày mai!",
        "topic": "greeting",
        "is_seeded": True,
        "is_ai_generated": False,
    },
    {
        "id": deterministic_uuid("word:student"),
        "lemma": "student",
        "ipa": "/ˈstuː.dənt/",
        "pos": "noun",
        "meaning_vi": "Học sinh, sinh viên đang đi học",
        "example_en": "She is a university student.",
        "example_vi": "Cô ấy là một sinh viên đại học.",
        "topic": "greeting",
        "is_seeded": True,
        "is_ai_generated": False,
    },
    {
        "id": deterministic_uuid("word:teacher"),
        "lemma": "teacher",
        "ipa": "/ˈtiː.tʃər/",
        "pos": "noun",
        "meaning_vi": "Giáo viên, người giảng dạy",
        "example_en": "My teacher is very helpful.",
        "example_vi": "Giáo viên của tôi rất nhiệt tình giúp đỡ.",
        "topic": "greeting",
        "is_seeded": True,
        "is_ai_generated": False,
    },
    {
        "id": deterministic_uuid("word:friend"),
        "lemma": "friend",
        "ipa": "/frend/",
        "pos": "noun",
        "meaning_vi": "Bạn bè, người bạn quen biết thân thiết",
        "example_en": "A good friend is always by your side.",
        "example_vi": "Một người bạn tốt luôn ở bên cạnh bạn.",
        "topic": "greeting",
        "is_seeded": True,
        "is_ai_generated": False,
    },
    {
        "id": deterministic_uuid("word:name"),
        "lemma": "name",
        "ipa": "/neɪm/",
        "pos": "noun",
        "meaning_vi": "Tên gọi của một người hoặc sự vật",
        "example_en": "What is your name?",
        "example_vi": "Tên của bạn là gì?",
        "topic": "greeting",
        "is_seeded": True,
        "is_ai_generated": False,
    },
    {
        "id": deterministic_uuid("word:welcome"),
        "lemma": "welcome",
        "ipa": "/ˈwel.kəm/",
        "pos": "verb",
        "meaning_vi": "Chào mừng, đón tiếp nồng hậu",
        "example_en": "Welcome to our English class!",
        "example_vi": "Chào mừng bạn đến với lớp học tiếng Anh!",
        "topic": "greeting",
        "is_seeded": True,
        "is_ai_generated": False,
    },

    # ── Chủ đề 2: food (7 từ) ─────────────────────────────────────────────────
    {
        "id": deterministic_uuid("word:bread"),
        "lemma": "bread",
        "ipa": "/bred/",
        "pos": "noun",
        "meaning_vi": "Bánh mì làm từ bột nướng",
        "example_en": "I eat bread with eggs for breakfast.",
        "example_vi": "Tôi ăn bánh mì với trứng cho bữa sáng.",
        "topic": "food",
        "is_seeded": True,
        "is_ai_generated": False,
    },
    {
        "id": deterministic_uuid("word:milk"),
        "lemma": "milk",
        "ipa": "/mɪlk/",
        "pos": "noun",
        "meaning_vi": "Sữa tươi giàu dinh dưỡng",
        "example_en": "Drinking milk helps build strong bones.",
        "example_vi": "Uống sữa giúp phát triển xương chắc khỏe.",
        "topic": "food",
        "is_seeded": True,
        "is_ai_generated": False,
    },
    {
        "id": deterministic_uuid("word:water"),
        "lemma": "water",
        "ipa": "/ˈwɑː.tər/",
        "pos": "noun",
        "meaning_vi": "Nước uống tinh khiết không màu",
        "example_en": "Drink enough water every day.",
        "example_vi": "Hãy uống đủ nước mỗi ngày.",
        "topic": "food",
        "is_seeded": True,
        "is_ai_generated": False,
    },
    {
        "id": deterministic_uuid("word:apple"),
        "lemma": "apple",
        "ipa": "/ˈæp.əl/",
        "pos": "noun",
        "meaning_vi": "Quả táo vỏ đỏ hoặc xanh",
        "example_en": "An apple a day keeps the doctor away.",
        "example_vi": "Mỗi ngày một quả táo giúp tránh xa bác sĩ.",
        "topic": "food",
        "is_seeded": True,
        "is_ai_generated": False,
    },
    {
        "id": deterministic_uuid("word:coffee"),
        "lemma": "coffee",
        "ipa": "/ˈkɔː.fi/",
        "pos": "noun",
        "meaning_vi": "Cà phê, thức uống thơm giúp tỉnh táo",
        "example_en": "He drinks hot coffee every morning.",
        "example_vi": "Anh ấy uống cà phê nóng mỗi sáng.",
        "topic": "food",
        "is_seeded": True,
        "is_ai_generated": False,
    },
    {
        "id": deterministic_uuid("word:rice"),
        "lemma": "rice",
        "ipa": "/raɪs/",
        "pos": "noun",
        "meaning_vi": "Cơm, hạt gạo nấu chín",
        "example_en": "Rice is the staple food in Vietnam.",
        "example_vi": "Cơm là món ăn chính tại Việt Nam.",
        "topic": "food",
        "is_seeded": True,
        "is_ai_generated": False,
    },
    {
        "id": deterministic_uuid("word:tea"),
        "lemma": "tea",
        "ipa": "/tiː/",
        "pos": "noun",
        "meaning_vi": "Trà, nước hãm lá chè",
        "example_en": "Would you like a cup of green tea?",
        "example_vi": "Bạn có muốn dùng một tách trà xanh không?",
        "topic": "food",
        "is_seeded": True,
        "is_ai_generated": False,
    },

    # ── Chủ đề 3: travel (7 từ) ───────────────────────────────────────────────
    {
        "id": deterministic_uuid("word:airport"),
        "lemma": "airport",
        "ipa": "/ˈer.pɔːrt/",
        "pos": "noun",
        "meaning_vi": "Sân bay, phi trường cất hạ cánh máy bay",
        "example_en": "We arrived at the airport two hours early.",
        "example_vi": "Chúng tôi đến sân bay trước hai tiếng.",
        "topic": "travel",
        "is_seeded": True,
        "is_ai_generated": False,
    },
    {
        "id": deterministic_uuid("word:hotel"),
        "lemma": "hotel",
        "ipa": "/hoʊˈtel/ ",
        "pos": "noun",
        "meaning_vi": "Khách sạn phục vụ lưu trú",
        "example_en": "They booked a room at a seaside hotel.",
        "example_vi": "Họ đã đặt phòng tại một khách sạn ven biển.",
        "topic": "travel",
        "is_seeded": True,
        "is_ai_generated": False,
    },
    {
        "id": deterministic_uuid("word:ticket"),
        "lemma": "ticket",
        "ipa": "/ˈtɪk.ɪt/",
        "pos": "noun",
        "meaning_vi": "Vé đi xe, vé máy bay hoặc vé vào cửa",
        "example_en": "Please show your flight ticket at the gate.",
        "example_vi": "Vui lòng xuất trình vé máy bay tại cửa khởi hành.",
        "topic": "travel",
        "is_seeded": True,
        "is_ai_generated": False,
    },
    {
        "id": deterministic_uuid("word:passport"),
        "lemma": "passport",
        "ipa": "/ˈpæs.pɔːrt/",
        "pos": "noun",
        "meaning_vi": "Hộ chiếu do chính phủ cấp để xuất nhập cảnh",
        "example_en": "Keep your passport in a safe place.",
        "example_vi": "Hãy giữ hộ chiếu ở nơi an toàn.",
        "topic": "travel",
        "is_seeded": True,
        "is_ai_generated": False,
    },
    {
        "id": deterministic_uuid("word:street"),
        "lemma": "street",
        "ipa": "/striːt/",
        "pos": "noun",
        "meaning_vi": "Con đường, phố xá trong đô thị",
        "example_en": "Walk along this street to find the station.",
        "example_vi": "Đi dọc con đường này để tìm nhà ga.",
        "topic": "travel",
        "is_seeded": True,
        "is_ai_generated": False,
    },
    {
        "id": deterministic_uuid("word:map"),
        "lemma": "map",
        "ipa": "/mæp/",
        "pos": "noun",
        "meaning_vi": "Bản đồ chỉ đường",
        "example_en": "She used a digital map to navigate the city.",
        "example_vi": "Cô ấy dùng bản đồ số để tìm đường trong thành phố.",
        "topic": "travel",
        "is_seeded": True,
        "is_ai_generated": False,
    },
    {
        "id": deterministic_uuid("word:luggage"),
        "lemma": "luggage",
        "ipa": "/ˈlʌɡ.ɪdʒ/",
        "pos": "noun",
        "meaning_vi": "Hành lý, vali chứa đồ khi đi xa",
        "example_en": "Pack your luggage before the trip.",
        "example_vi": "Hãy xếp gọn hành lý trước chuyến đi.",
        "topic": "travel",
        "is_seeded": True,
        "is_ai_generated": False,
    },

    # ── Chủ đề 4: daily (9 từ) ────────────────────────────────────────────────
    {
        "id": deterministic_uuid("word:house"),
        "lemma": "house",
        "ipa": "/haʊs/",
        "pos": "noun",
        "meaning_vi": "Ngôi nhà ở gia đình",
        "example_en": "They live in a small comfortable house.",
        "example_vi": "Họ sống trong một ngôi nhà nhỏ tiện nghi.",
        "topic": "daily",
        "is_seeded": True,
        "is_ai_generated": False,
    },
    {
        "id": deterministic_uuid("word:book"),
        "lemma": "book",
        "ipa": "/bʊk/",
        "pos": "noun",
        "meaning_vi": "Quyển sách chứa chữ viết hoặc hình ảnh",
        "example_en": "Reading a good book opens your mind.",
        "example_vi": "Đọc một quyển sách hay giúp mở rộng tâm trí.",
        "topic": "daily",
        "is_seeded": True,
        "is_ai_generated": False,
    },
    {
        "id": deterministic_uuid("word:phone"),
        "lemma": "phone",
        "ipa": "/foʊn/",
        "pos": "noun",
        "meaning_vi": "Điện thoại di động liên lạc",
        "example_en": "She answered a phone call from her father.",
        "example_vi": "Cô ấy nghe cuộc gọi điện thoại từ bố.",
        "topic": "daily",
        "is_seeded": True,
        "is_ai_generated": False,
    },
    {
        "id": deterministic_uuid("word:clock"),
        "lemma": "clock",
        "ipa": "/klɑːk/",
        "pos": "noun",
        "meaning_vi": "Đồng hồ treo tường hoặc để bàn",
        "example_en": "The wall clock shows nine o'clock.",
        "example_vi": "Chiếc đồng hồ treo tường chỉ đúng 9 giờ.",
        "topic": "daily",
        "is_seeded": True,
        "is_ai_generated": False,
    },
    {
        "id": deterministic_uuid("word:chair"),
        "lemma": "chair",
        "ipa": "/tʃer/",
        "pos": "noun",
        "meaning_vi": "Chiếc ghế ngồi có lưng tựa",
        "example_en": "Please take a seat on this chair.",
        "example_vi": "Xin mời ngồi vào chiếc ghế này.",
        "topic": "daily",
        "is_seeded": True,
        "is_ai_generated": False,
    },
    {
        "id": deterministic_uuid("word:table"),
        "lemma": "table",
        "ipa": "/ˈteɪ.bəl/",
        "pos": "noun",
        "meaning_vi": "Chiếc bàn làm việc hoặc bàn ăn",
        "example_en": "The books are neatly placed on the table.",
        "example_vi": "Sách được xếp ngay ngắn trên mặt bàn.",
        "topic": "daily",
        "is_seeded": True,
        "is_ai_generated": False,
    },
    {
        "id": deterministic_uuid("word:window"),
        "lemma": "window",
        "ipa": "/ˈwɪn.doʊ/",
        "pos": "noun",
        "meaning_vi": "Cửa sổ thông gió lấy ánh sáng",
        "example_en": "Open the window to let fresh air in.",
        "example_vi": "Hãy mở cửa sổ để đón không khí trong lành.",
        "topic": "daily",
        "is_seeded": True,
        "is_ai_generated": False,
    },
    {
        "id": deterministic_uuid("word:work"),
        "lemma": "work",
        "ipa": "/wɜːrk/",
        "pos": "noun",
        "meaning_vi": "Công việc hoặc nơi làm việc",
        "example_en": "She starts work at eight o'clock.",
        "example_vi": "Cô ấy bắt đầu làm việc lúc tám giờ.",
        "topic": "daily",
        "is_seeded": True,
        "is_ai_generated": False,
    },
    {
        "id": deterministic_uuid("word:routine"),
        "lemma": "routine",
        "ipa": "/ruːˈtiːn/",
        "pos": "noun",
        "meaning_vi": "Thói quen hoặc lịch trình sinh hoạt hàng ngày",
        "example_en": "A healthy morning routine gives you energy.",
        "example_vi": "Một thói quen buổi sáng lành mạnh giúp bạn tràn đầy năng lượng.",
        "topic": "daily",
        "is_seeded": True,
        "is_ai_generated": False,
    },
]


# ─────────────────────────────────────────────────────────────────────────────
# 2. DANH SÁCH LỘ TRÌNH HỌC, UNIT, LESSON VÀ CÁC DẠNG BÀI TẬP (5 TYPES)
# ─────────────────────────────────────────────────────────────────────────────

SEED_PATHS: list[dict[str, Any]] = [
    # ═════════════════════════════════════════════════════════════════════════
    # PATH 1: Level A1 - English Basics & Daily Communication
    # ═════════════════════════════════════════════════════════════════════════
    {
        "id": deterministic_uuid("path:english-basics-a1"),
        "title": "English Basics & Daily Communication",
        "level": "A1",
        "description": "Lộ trình tiếng Anh giao tiếp cơ bản dành cho người mới bắt đầu. Bao gồm chào hỏi, ăn uống và du lịch.",
        "thumbnail_url": "https://images.unsplash.com/photo-1546410531-bb4caa6b424d",
        "is_active": True,
        "units": [
            # ── Unit 1: Greetings & Introductions ─────────────────────────────
            {
                "id": deterministic_uuid("unit:a1-greetings"),
                "title": "Greetings & Introductions",
                "order_index": 1,
                "description": "Học cách chào hỏi, tạm biệt và tự giới thiệu bản thân.",
                "lessons": [
                    {
                        "id": deterministic_uuid("lesson:a1-u1-l1"),
                        "title": "Basic Greetings & Goodbyes",
                        "lesson_type": "vocabulary",
                        "xp_reward": 15,
                        "order_index": 1,
                        "icon_name": "hand-wave",
                        "content_data": {
                            "exercises": [
                                {
                                    "id": "ex_a1_u1_l1_choice",
                                    "type": "choice",
                                    "prompt": "Chọn nghĩa đúng của từ sau:",
                                    "targetWord": "Hello",
                                    "ipa": "/həˈloʊ/",
                                    "options": [
                                        {"text": "Tạm biệt"},
                                        {"text": "Xin chào"},
                                        {"text": "Cảm ơn"},
                                        {"text": "Xin lỗi"},
                                    ],
                                    "correctOptionIndex": 1,
                                    "explanation": "'Hello' là lời chào thân thiện thông dụng nhất trong tiếng Anh.",
                                },
                                {
                                    "id": "ex_a1_u1_l1_match",
                                    "type": "matchPairs",
                                    "prompt": "Ghép các cặp từ chào hỏi tương ứng:",
                                    "pairs": [
                                        {"english": "Hello", "vietnamese": "Xin chào"},
                                        {"english": "Goodbye", "vietnamese": "Tạm biệt"},
                                        {"english": "Thank you", "vietnamese": "Cảm ơn"},
                                        {"english": "Friend", "vietnamese": "Bạn bè"},
                                    ],
                                    "explanation": "Các cặp từ chào hỏi và giao tiếp cơ bản hàng ngày.",
                                },
                                {
                                    "id": "ex_a1_u1_l1_wb",
                                    "type": "wordBank",
                                    "prompt": "Sắp xếp các từ để hoàn thành câu:",
                                    "vietnameseSentence": "Xin chào, tôi là John.",
                                    "correctWords": ["Hello", "I", "am", "John"],
                                    "availableWords": ["am", "John", "Hello", "teacher", "I", "is"],
                                    "explanation": "Cấu trúc câu giới thiệu: Hello, I am + [Tên].",
                                },
                            ]
                        },
                    },
                    {
                        "id": deterministic_uuid("lesson:a1-u1-l2"),
                        "title": "Introducing Yourself",
                        "lesson_type": "speaking",
                        "xp_reward": 20,
                        "order_index": 2,
                        "icon_name": "account-circle",
                        "content_data": {
                            "exercises": [
                                {
                                    "id": "ex_a1_u1_l2_choice",
                                    "type": "choice",
                                    "prompt": "Chọn nghĩa đúng của từ sau:",
                                    "targetWord": "Student",
                                    "ipa": "/ˈstuː.dənt/",
                                    "options": [
                                        {"text": "Giáo viên"},
                                        {"text": "Học sinh, sinh viên"},
                                        {"text": "Bác sĩ"},
                                        {"text": "Kỹ sư"},
                                    ],
                                    "correctOptionIndex": 1,
                                    "explanation": "'Student' có nghĩa là học sinh hoặc sinh viên đang theo học.",
                                },
                                {
                                    "id": "ex_a1_u1_l2_listen",
                                    "type": "listening",
                                    "prompt": "Nghe và điền từ còn thiếu:",
                                    "audioText": "I am a student",
                                    "answer": "student",
                                },
                                {
                                    "id": "ex_a1_u1_l2_speak",
                                    "type": "speaking",
                                    "prompt": "Đọc câu sau thành tiếng:",
                                    "phrase": "Nice to meet you",
                                },
                                {
                                    "id": "ex_a1_u1_l2_wb",
                                    "type": "wordBank",
                                    "prompt": "Sắp xếp các từ để tạo thành câu hoàn chỉnh:",
                                    "vietnameseSentence": "Tên của tôi là Anna.",
                                    "correctWords": ["My", "name", "is", "Anna"],
                                    "availableWords": ["is", "My", "Anna", "name", "are", "welcome"],
                                    "explanation": "Cấu trúc giới thiệu tên: My name is + [Tên].",
                                },
                            ]
                        },
                    },
                    {
                        "id": deterministic_uuid("lesson:a1-u1-l3"),
                        "title": "Review & Practice Greetings",
                        "lesson_type": "listening",
                        "xp_reward": 25,
                        "order_index": 3,
                        "icon_name": "headphones",
                        "content_data": {
                            "exercises": [
                                {
                                    "id": "ex_a1_u1_l3_listen",
                                    "type": "listening",
                                    "prompt": "Nghe đoạn băng và điền từ còn thiếu:",
                                    "audioText": "Welcome to our class",
                                    "answer": "welcome",
                                },
                                {
                                    "id": "ex_a1_u1_l3_speak",
                                    "type": "speaking",
                                    "prompt": "Luyện phát âm câu sau:",
                                    "phrase": "Goodbye, see you tomorrow",
                                },
                                {
                                    "id": "ex_a1_u1_l3_match",
                                    "type": "matchPairs",
                                    "prompt": "Ghép các cặp từ tương ứng:",
                                    "pairs": [
                                        {"english": "Teacher", "vietnamese": "Giáo viên"},
                                        {"english": "Student", "vietnamese": "Học sinh"},
                                        {"english": "Name", "vietnamese": "Tên gọi"},
                                        {"english": "Welcome", "vietnamese": "Chào mừng"},
                                    ],
                                    "explanation": "Tổng hợp các danh từ và động từ trong bài Chào hỏi.",
                                },
                            ]
                        },
                    },
                ],
            },

            # ── Unit 2: Food & Dining ─────────────────────────────────────────
            {
                "id": deterministic_uuid("unit:a1-food"),
                "title": "Food & Dining",
                "order_index": 2,
                "description": "Từ vựng về món ăn, thức uống và cách gọi món trong nhà hàng.",
                "lessons": [
                    {
                        "id": deterministic_uuid("lesson:a1-u2-l1"),
                        "title": "Everyday Food & Drinks",
                        "lesson_type": "vocabulary",
                        "xp_reward": 20,
                        "order_index": 1,
                        "icon_name": "restaurant",
                        "content_data": {
                            "exercises": [
                                {
                                    "id": "ex_a1_u2_l1_choice",
                                    "type": "choice",
                                    "prompt": "Từ nào sau đây có nghĩa là 'Bánh mì'?",
                                    "targetWord": "Bread",
                                    "ipa": "/bred/",
                                    "options": [
                                        {"text": "Bánh mì"},
                                        {"text": "Cơm"},
                                        {"text": "Trứng"},
                                        {"text": "Sữa"},
                                    ],
                                    "correctOptionIndex": 0,
                                    "explanation": "'Bread' là món bánh mì nướng làm từ bột mì.",
                                },
                                {
                                    "id": "ex_a1_u2_l1_match",
                                    "type": "matchPairs",
                                    "prompt": "Ghép các món đồ uống và thức ăn phổ biến:",
                                    "pairs": [
                                        {"english": "Milk", "vietnamese": "Sữa"},
                                        {"english": "Water", "vietnamese": "Nước"},
                                        {"english": "Coffee", "vietnamese": "Cà phê"},
                                        {"english": "Apple", "vietnamese": "Quả táo"},
                                    ],
                                    "explanation": "Từ vựng về đồ uống và trái cây thường ngày.",
                                },
                                {
                                    "id": "ex_a1_u2_l1_wb",
                                    "type": "wordBank",
                                    "prompt": "Sắp xếp các từ để hoàn thiện câu:",
                                    "vietnameseSentence": "Tôi uống nước mỗi ngày.",
                                    "correctWords": ["I", "drink", "water", "every", "day"],
                                    "availableWords": ["water", "I", "day", "drink", "every", "milk", "bread"],
                                    "explanation": "Thì hiện tại đơn diễn tả thói quen: I + drink + water + every day.",
                                },
                            ]
                        },
                    },
                    {
                        "id": deterministic_uuid("lesson:a1-u2-l2"),
                        "title": "Ordering at a Cafe",
                        "lesson_type": "speaking",
                        "xp_reward": 25,
                        "order_index": 2,
                        "icon_name": "local-cafe",
                        "content_data": {
                            "exercises": [
                                {
                                    "id": "ex_a1_u2_l2_speak",
                                    "prompt": "Nói câu gọi cà phê bằng tiếng Anh:",
                                    "type": "speaking",
                                    "phrase": "I would like a cup of coffee",
                                },
                                {
                                    "id": "ex_a1_u2_l2_listen",
                                    "type": "listening",
                                    "prompt": "Nghe và điền từ đồ uống thích hợp:",
                                    "audioText": "Would you like some tea",
                                    "answer": "tea",
                                },
                                {
                                    "id": "ex_a1_u2_l2_choice",
                                    "type": "choice",
                                    "prompt": "Khi muốn hỏi giá một món đồ, bạn dùng câu nào?",
                                    "targetWord": "How much is this?",
                                    "ipa": "/haʊ mʌtʃ ɪz ðɪs/",
                                    "options": [
                                        {"text": "Cái này giá bao nhiêu?"},
                                        {"text": "Cái này ở đâu?"},
                                        {"text": "Bạn tên gì?"},
                                        {"text": "Bây giờ là mấy giờ?"},
                                    ],
                                    "correctOptionIndex": 0,
                                    "explanation": "'How much is this?' là mẫu câu chuẩn để hỏi giá.",
                                },
                            ]
                        },
                    },
                ],
            },

            # ── Unit 3: At the Airport & Travel ───────────────────────────────
            {
                "id": deterministic_uuid("unit:a1-travel"),
                "title": "At the Airport & Travel",
                "order_index": 3,
                "description": "Các tình huống di chuyển, hỏi đường và làm thủ tục tại sân bay.",
                "lessons": [
                    {
                        "id": deterministic_uuid("lesson:a1-u3-l1"),
                        "title": "Airport Essentials",
                        "lesson_type": "vocabulary",
                        "xp_reward": 20,
                        "order_index": 1,
                        "icon_name": "flight-takeoff",
                        "content_data": {
                            "exercises": [
                                {
                                    "id": "ex_a1_u3_l1_choice",
                                    "type": "choice",
                                    "prompt": "Chọn nghĩa chính xác của từ sau:",
                                    "targetWord": "Passport",
                                    "ipa": "/ˈpæs.pɔːrt/",
                                    "options": [
                                        {"text": "Vé máy bay"},
                                        {"text": "Hộ chiếu"},
                                        {"text": "Hành lý"},
                                        {"text": "Khách sạn"},
                                    ],
                                    "correctOptionIndex": 1,
                                    "explanation": "'Passport' là hộ chiếu cá nhân dùng khi xuất nhập cảnh.",
                                },
                                {
                                    "id": "ex_a1_u3_l1_match",
                                    "type": "matchPairs",
                                    "prompt": "Ghép các từ du lịch với bản dịch tiếng Việt:",
                                    "pairs": [
                                        {"english": "Airport", "vietnamese": "Sân bay"},
                                        {"english": "Ticket", "vietnamese": "Vé"},
                                        {"english": "Luggage", "vietnamese": "Hành lý"},
                                        {"english": "Hotel", "vietnamese": "Khách sạn"},
                                    ],
                                    "explanation": "Từ vựng cơ bản phục vụ chuyến đi du lịch.",
                                },
                                {
                                    "id": "ex_a1_u3_l1_wb",
                                    "type": "wordBank",
                                    "prompt": "Sắp xếp câu yêu cầu xuất trình vé:",
                                    "vietnameseSentence": "Làm ơn cho xem vé của bạn.",
                                    "correctWords": ["Please", "show", "your", "ticket"],
                                    "availableWords": ["ticket", "show", "Please", "your", "passport", "hotel"],
                                    "explanation": "Mẫu câu lịch sự: Please show your ticket.",
                                },
                            ]
                        },
                    },
                    {
                        "id": deterministic_uuid("lesson:a1-u3-l2"),
                        "title": "Finding Your Way",
                        "lesson_type": "listening",
                        "xp_reward": 25,
                        "order_index": 2,
                        "icon_name": "map",
                        "content_data": {
                            "exercises": [
                                {
                                    "id": "ex_a1_u3_l2_listen",
                                    "type": "listening",
                                    "prompt": "Nghe và điền địa điểm còn thiếu:",
                                    "audioText": "Where is the airport",
                                    "answer": "airport",
                                },
                                {
                                    "id": "ex_a1_u3_l2_speak",
                                    "type": "speaking",
                                    "prompt": "Luyện nói câu hỏi đường tới khách sạn:",
                                    "phrase": "Excuse me, where is the hotel?",
                                },
                                {
                                    "id": "ex_a1_u3_l2_choice",
                                    "type": "choice",
                                    "prompt": "'Map' mang nghĩa là gì?",
                                    "targetWord": "Map",
                                    "ipa": "/mæp/",
                                    "options": [
                                        {"text": "Con đường"},
                                        {"text": "Bản đồ"},
                                        {"text": "Xe buýt"},
                                        {"text": "Cửa hàng"},
                                    ],
                                    "correctOptionIndex": 1,
                                    "explanation": "'Map' nghĩa là bản đồ chỉ đường.",
                                },
                            ]
                        },
                    },
                ],
            },
        ],
    },

    # ═════════════════════════════════════════════════════════════════════════
    # PATH 2: Level A2 - Elementary English for Work & Life
    # ═════════════════════════════════════════════════════════════════════════
    {
        "id": deterministic_uuid("path:elementary-english-a2"),
        "title": "Elementary English for Work & Life",
        "level": "A2",
        "description": "Nâng cao vốn từ vựng trong công việc, nơi công sở và chia sẻ về cuộc sống, sở thích thường nhật.",
        "thumbnail_url": "https://images.unsplash.com/photo-1522202176988-66273c2fd55f",
        "is_active": True,
        "units": [
            # ── Unit 1: Office & Jobs ─────────────────────────────────────────
            {
                "id": deterministic_uuid("unit:a2-office"),
                "title": "Office & Jobs",
                "order_index": 1,
                "description": "Giao tiếp công sở, trao đổi công việc và thời khóa biểu làm việc.",
                "lessons": [
                    {
                        "id": deterministic_uuid("lesson:a2-u1-l1"),
                        "title": "Workplace Communication",
                        "lesson_type": "speaking",
                        "xp_reward": 25,
                        "order_index": 1,
                        "icon_name": "business-center",
                        "content_data": {
                            "exercises": [
                                {
                                    "id": "ex_a2_u1_l1_choice",
                                    "type": "choice",
                                    "prompt": "Từ nào mang nghĩa 'cuộc gọi điện thoại'?",
                                    "targetWord": "Phone call",
                                    "ipa": "/foʊn kɔːl/",
                                    "options": [
                                        {"text": "Thư tay"},
                                        {"text": "Cuộc gọi điện thoại"},
                                        {"text": "Cuộc họp"},
                                        {"text": "Bản báo cáo"},
                                    ],
                                    "correctOptionIndex": 1,
                                    "explanation": "'Phone call' là cuộc đàm thoại qua điện thoại.",
                                },
                                {
                                    "id": "ex_a2_u1_l1_wb",
                                    "type": "wordBank",
                                    "prompt": "Sắp xếp lời chào đón khách đến văn phòng:",
                                    "vietnameseSentence": "Chào mừng bạn đến với văn phòng chúng tôi.",
                                    "correctWords": ["Welcome", "to", "our", "office"],
                                    "availableWords": ["office", "Welcome", "our", "to", "hotel", "house"],
                                    "explanation": "Cấu trúc chào đón: Welcome to our office.",
                                },
                                {
                                    "id": "ex_a2_u1_l1_speak",
                                    "type": "speaking",
                                    "prompt": "Nói câu chào buổi sáng và đề nghị giúp đỡ đồng nghiệp:",
                                    "phrase": "Good morning, how can I help you?",
                                },
                            ]
                        },
                    },
                    {
                        "id": deterministic_uuid("lesson:a2-u1-l2"),
                        "title": "Meeting & Schedule",
                        "lesson_type": "listening",
                        "xp_reward": 25,
                        "order_index": 2,
                        "icon_name": "calendar-today",
                        "content_data": {
                            "exercises": [
                                {
                                    "id": "ex_a2_u1_l2_listen",
                                    "type": "listening",
                                    "prompt": "Nghe câu sau và điền từ còn thiếu:",
                                    "audioText": "The meeting starts at nine o'clock",
                                    "answer": "clock",
                                },
                                {
                                    "id": "ex_a2_u1_l2_match",
                                    "type": "matchPairs",
                                    "prompt": "Ghép các từ vựng đồ dùng văn phòng:",
                                    "pairs": [
                                        {"english": "Clock", "vietnamese": "Đồng hồ"},
                                        {"english": "Table", "vietnamese": "Cái bàn"},
                                        {"english": "Chair", "vietnamese": "Cái ghế"},
                                        {"english": "Phone", "vietnamese": "Điện thoại"},
                                    ],
                                    "explanation": "Đồ dùng và trang thiết bị hỗ trợ văn phòng.",
                                },
                                {
                                    "id": "ex_a2_u1_l2_choice",
                                    "type": "choice",
                                    "prompt": "Chọn định nghĩa phù hợp của 'Table':",
                                    "targetWord": "Table",
                                    "ipa": "/ˈteɪ.bəl/",
                                    "options": [
                                        {"text": "Cái ghế"},
                                        {"text": "Cái bàn"},
                                        {"text": "Cửa sổ"},
                                        {"text": "Quyển sách"},
                                    ],
                                    "correctOptionIndex": 1,
                                    "explanation": "'Table' là mặt bàn làm việc hoặc bàn ăn.",
                                },
                            ]
                        },
                    },
                ],
            },

            # ── Unit 2: Hobbies & Daily Routine ───────────────────────────────
            {
                "id": deterministic_uuid("unit:a2-hobbies"),
                "title": "Hobbies & Daily Routine",
                "order_index": 2,
                "description": "Chia sẻ về ngôi nhà, thói quen đọc sách và sinh hoạt gia đình.",
                "lessons": [
                    {
                        "id": deterministic_uuid("lesson:a2-u2-l1"),
                        "title": "Home & Leisure",
                        "lesson_type": "vocabulary",
                        "xp_reward": 25,
                        "order_index": 1,
                        "icon_name": "weekend",
                        "content_data": {
                            "exercises": [
                                {
                                    "id": "ex_a2_u2_l1_choice",
                                    "type": "choice",
                                    "prompt": "Từ nào sau đây có nghĩa là 'Quyển sách'?",
                                    "targetWord": "Book",
                                    "ipa": "/bʊk/",
                                    "options": [
                                        {"text": "Bút viết"},
                                        {"text": "Quyển sách"},
                                        {"text": "Ngôi nhà"},
                                        {"text": "Cửa sổ"},
                                    ],
                                    "correctOptionIndex": 1,
                                    "explanation": "'Book' là quyển sách.",
                                },
                                {
                                    "id": "ex_a2_u2_l1_match",
                                    "type": "matchPairs",
                                    "prompt": "Ghép các từ về ngôi nhà và cuộc sống:",
                                    "pairs": [
                                        {"english": "House", "vietnamese": "Ngôi nhà"},
                                        {"english": "Window", "vietnamese": "Cửa sổ"},
                                        {"english": "Book", "vietnamese": "Quyển sách"},
                                        {"english": "Street", "vietnamese": "Con đường"},
                                    ],
                                    "explanation": "Từ vựng về không gian sinh hoạt và nhà cửa.",
                                },
                                {
                                    "id": "ex_a2_u2_l1_wb",
                                    "type": "wordBank",
                                    "prompt": "Sắp xếp câu diễn đạt sở thích đọc sách:",
                                    "vietnameseSentence": "Tôi thích đọc một quyển sách hay.",
                                    "correctWords": ["I", "like", "reading", "a", "good", "book"],
                                    "availableWords": ["book", "reading", "I", "a", "like", "house", "good", "table"],
                                    "explanation": "Cấu trúc: I like reading a good book.",
                                },
                                {
                                    "id": "ex_a2_u2_l1_speak",
                                    "type": "speaking",
                                    "prompt": "Đọc to câu miêu tả cảm xúc khi ở nhà:",
                                    "phrase": "I love staying in my warm house",
                                },
                            ]
                        },
                    },
                ],
            },
        ],
    },
]


# ─────────────────────────────────────────────────────────────────────────────
# 3. HÀM SEEDING IDEMPOTENT (THỰC THI BẤT ĐỒNG BỘ)
# ─────────────────────────────────────────────────────────────────────────────

async def seed_learning_paths(session: AsyncSession) -> dict[str, int]:
    """
    Nạp dữ liệu cho LearningPath, Unit và Lesson.
    Cập nhật dữ liệu nếu bản ghi đã tồn tại theo ID (Upsert Idempotent).
    """
    paths_count = 0
    units_count = 0
    lessons_count = 0

    for path_dict in SEED_PATHS:
        path_data = {k: v for k, v in path_dict.items() if k != "units"}
        path_id = path_data["id"]

        existing_path = await session.get(LearningPath, path_id)
        if existing_path is None:
            session.add(LearningPath(**path_data))
            paths_count += 1
        else:
            for key, val in path_data.items():
                setattr(existing_path, key, val)

        await session.flush()

        for unit_dict in path_dict.get("units", []):
            unit_data = {k: v for k, v in unit_dict.items() if k != "lessons"}
            unit_data["path_id"] = path_id
            unit_id = unit_data["id"]

            existing_unit = await session.get(Unit, unit_id)
            if existing_unit is None:
                session.add(Unit(**unit_data))
                units_count += 1
            else:
                for key, val in unit_data.items():
                    setattr(existing_unit, key, val)

            await session.flush()

            for lesson_dict in unit_dict.get("lessons", []):
                lesson_data = dict(lesson_dict)
                lesson_data["unit_id"] = unit_id
                lesson_id = lesson_data["id"]

                existing_lesson = await session.get(Lesson, lesson_id)
                if existing_lesson is None:
                    session.add(Lesson(**lesson_data))
                    lessons_count += 1
                else:
                    for key, val in lesson_data.items():
                        setattr(existing_lesson, key, val)

            await session.flush()

    return {
        "paths": paths_count,
        "units": units_count,
        "lessons": lessons_count,
    }


async def seed_words(session: AsyncSession) -> dict[str, int]:
    """
    Nạp dữ liệu từ vựng (Word).
    Tra cứu theo lemma hoặc ID để tránh xung đột UniqueConstraint trên `lemma`.
    """
    words_count = 0

    for word_dict in SEED_WORDS:
        word_id = word_dict["id"]
        lemma = word_dict["lemma"]

        # Tra cứu theo ID hoặc lemma duy nhất
        stmt = select(Word).where(or_(Word.id == word_id, Word.lemma == lemma))
        result = await session.execute(stmt)
        existing_word = result.scalars().first()

        if existing_word is None:
            session.add(Word(**word_dict))
            words_count += 1
        else:
            # Cập nhật các trường thông tin nội dung
            for key, val in word_dict.items():
                if key != "id":
                    setattr(existing_word, key, val)

    await session.flush()
    return {"words": words_count}


async def seed_all(session: AsyncSession) -> dict[str, Any]:
    """
    Điểm vào thư viện: Nạp toàn bộ dữ liệu mẫu (Learning Paths, Units, Lessons và Words).
    Có thể được gọi từ migration, test fixture hoặc endpoint quản trị.
    """
    logger.info("Bắt đầu nạp seed data cho Learning Paths & Lessons...")
    path_stats = await seed_learning_paths(session)

    logger.info("Bắt đầu nạp seed data cho Vocabulary Words...")
    word_stats = await seed_words(session)

    summary = {**path_stats, **word_stats}
    logger.info("Hoàn tất nạp seed data: %s", summary)
    return summary


# ─────────────────────────────────────────────────────────────────────────────
# 4. STANDALONE CLI ENTRYPOINT
# ─────────────────────────────────────────────────────────────────────────────

async def main() -> None:
    """CLI Runner để chạy độc lập: python -m app.db.seeds"""
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    )
    print("=" * 65)
    print("  LingoUp Seed Data Runner (FastAPI & PostgreSQL)")
    print("=" * 65)

    async with AsyncSessionLocal() as session:
        async with session.begin():
            stats = await seed_all(session)

    print("\n✅ Seed data executed successfully!")
    print(f"   • Learning Paths created/updated : {stats.get('paths', 0)}")
    print(f"   • Units created/updated          : {stats.get('units', 0)}")
    print(f"   • Lessons created/updated        : {stats.get('lessons', 0)}")
    print(f"   • Vocabulary Words inserted/synced: {stats.get('words', 0)}")
    print("=" * 65)


if __name__ == "__main__":
    asyncio.run(main())
