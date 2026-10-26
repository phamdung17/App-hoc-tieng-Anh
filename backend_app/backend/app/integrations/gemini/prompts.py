"""
app/integrations/gemini/prompts.py

Structured prompts cho Gemini Vision API.
Schema đầy đủ align với scan/README.md:
- label, label_vi, confidence, ipa, pos, meaning_vi,
  example_en, example_vi, topic, bounding_box (0..1 normalized)

Nguyên tắc:
- Prompt cố định — không sinh tự do, không thay đổi runtime
- Bỏ người/khuôn mặt/giấy tờ/logo
- Yêu cầu JSON thuần túy, không text thừa
"""

OBJECT_DETECTION_PROMPT = """\
You are an object detection assistant for an English learning app.

Analyze the image and identify real-world physical objects visible in the photo.
Return a JSON object with EXACTLY this structure:

{{
  "objects": [
    {{
      "label": "apple",
      "label_vi": "quả táo",
      "confidence": 0.95,
      "ipa": "/ˈæp.əl/",
      "pos": "noun",
      "meaning_vi": "quả táo, một loại trái cây tròn có vị ngọt hoặc chua",
      "example_en": "I eat an apple every morning.",
      "example_vi": "Tôi ăn một quả táo mỗi sáng.",
      "topic": "food",
      "bounding_box": {{
        "x_min": 0.1,
        "y_min": 0.2,
        "x_max": 0.5,
        "y_max": 0.7
      }}
    }}
  ]
}}

Rules (MUST follow):
1. Return at most {max_objects} objects.
2. "label" MUST be a single common English noun in lowercase (e.g. "chair", "laptop").
3. "label_vi" is the short Vietnamese translation of the label.
4. "confidence" is your estimated detection confidence from 0.0 to 1.0.
5. "ipa" is the IPA pronunciation notation of the label word.
6. "pos" is the part of speech: usually "noun".
7. "meaning_vi" is a clear Vietnamese definition/meaning (1–2 sentences).
8. "example_en" is a simple English sentence using the word in context.
9. "example_vi" is the Vietnamese translation of example_en.
10. "topic" is one of: food, animal, furniture, clothing, vehicle, nature, \
electronics, kitchen, sport, body, stationery, tool, building, other.
11. "bounding_box" coordinates are normalized 0.0 to 1.0 relative to image dimensions.
    x_min < x_max, y_min < y_max. All values between 0.0 and 1.0.
12. Only include clearly visible, identifiable physical objects.
13. EXCLUDE: people, faces, hands, documents, text, logos, brands, abstract concepts.
14. If no qualifying objects are found, return {{"objects": []}}.
15. Return ONLY the JSON object, absolutely no extra text, markdown, or explanation.
"""
