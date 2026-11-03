import sys
from pathlib import Path
import uuid

# Add backend directory to sys.path
backend_dir = Path(r"d:\LapTrinhMoBa\do_an_moba\backend_app\backend")
sys.path.insert(0, str(backend_dir))

from app.db.seeds import SEED_PATHS, SEED_WORDS, deterministic_uuid, seed_all

print("--- 1. PATH & UNIT VERIFICATION ---")
assert len(SEED_PATHS) == 2, f"Expected 2 paths, got {len(SEED_PATHS)}"
p1, p2 = SEED_PATHS[0], SEED_PATHS[1]

assert p1["title"] == "English Basics & Daily Communication"
assert p1["level"] == "A1"
assert len(p1["units"]) == 3, f"Expected 3 units in p1, got {len(p1['units'])}"

assert p2["title"] == "Elementary English for Work & Life"
assert p2["level"] == "A2"
assert len(p2["units"]) == 2, f"Expected 2 units in p2, got {len(p2['units'])}"

p1_unit_titles = [u["title"] for u in p1["units"]]
expected_p1_units = [
    "Greetings & Introductions",
    "Food & Dining",
    "At the Airport & Travel",
]
assert p1_unit_titles == expected_p1_units, f"P1 units mismatch: {p1_unit_titles}"

p2_unit_titles = [u["title"] for u in p2["units"]]
expected_p2_units = [
    "Office & Jobs",
    "Hobbies & Daily Routine",
]
assert p2_unit_titles == expected_p2_units, f"P2 units mismatch: {p2_unit_titles}"
print("Paths and units verified successfully!")

print("\n--- 2. EXERCISE TYPES VERIFICATION ---")
types_found = set()
total_exercises = 0
for p in SEED_PATHS:
    for u in p["units"]:
        for l in u["lessons"]:
            exercises = l["content_data"]["exercises"]
            assert len(exercises) > 0, f"Lesson {l['title']} has no exercises"
            for ex in exercises:
                total_exercises += 1
                types_found.add(ex["type"])
                if ex["type"] == "choice":
                    assert "options" in ex and len(ex["options"]) == 4
                    assert "correctOptionIndex" in ex
                    assert "targetWord" in ex
                    assert "ipa" in ex
                    assert "explanation" in ex
                elif ex["type"] == "wordBank":
                    assert "correctWords" in ex and len(ex["correctWords"]) >= 3
                    assert "availableWords" in ex and len(ex["availableWords"]) >= len(ex["correctWords"])
                    assert "vietnameseSentence" in ex
                    assert "explanation" in ex
                elif ex["type"] == "matchPairs":
                    assert "pairs" in ex and len(ex["pairs"]) >= 3
                    for pair in ex["pairs"]:
                        assert "english" in pair and "vietnamese" in pair
                    assert "explanation" in ex
                elif ex["type"] == "listening":
                    assert "audioText" in ex
                    assert "answer" in ex
                elif ex["type"] == "speaking":
                    assert "phrase" in ex

expected_types = {"choice", "wordBank", "matchPairs", "listening", "speaking"}
assert expected_types.issubset(types_found), f"Missing types: {expected_types - types_found}"
print(f"Total exercises found: {total_exercises}")
print(f"All 5 exercise types present: {sorted(types_found)}")

print("\n--- 3. VOCABULARY WORDS VERIFICATION ---")
assert len(SEED_WORDS) >= 28, f"Expected >= 28 words, got {len(SEED_WORDS)}"
topics_found = {}
lemmas_found = set()

for w in SEED_WORDS:
    assert isinstance(w["id"], uuid.UUID)
    lemma = w["lemma"]
    assert lemma.islower(), f"Lemma not lowercase: {lemma}"
    assert lemma not in lemmas_found, f"Duplicate lemma: {lemma}"
    lemmas_found.add(lemma)
    assert w["ipa"], f"Missing ipa for {lemma}"
    assert w["pos"], f"Missing pos for {lemma}"
    assert w["meaning_vi"], f"Missing meaning_vi for {lemma}"
    assert w["example_en"], f"Missing example_en for {lemma}"
    assert w["example_vi"], f"Missing example_vi for {lemma}"
    assert w["is_seeded"] is True
    assert w["is_ai_generated"] is False
    topic = w["topic"]
    topics_found[topic] = topics_found.get(topic, 0) + 1

expected_topics = {"greeting", "food", "travel", "daily"}
assert expected_topics.issubset(topics_found.keys()), f"Missing topics: {expected_topics - set(topics_found.keys())}"
print(f"Total words: {len(SEED_WORDS)}")
print("Topic distribution:")
for topic, count in sorted(topics_found.items()):
    print(f"  - {topic}: {count} words")

print("\n--- 4. DETERMINISTIC UUID VERIFICATION ---")
uuid_hello_1 = deterministic_uuid("word:hello")
uuid_hello_2 = deterministic_uuid("word:hello")
assert uuid_hello_1 == uuid_hello_2, "UUID is not deterministic!"
assert str(uuid_hello_1) != str(uuid.uuid4()), "UUID collision or non-deterministic behavior"
print(f"Deterministic UUID verified: word:hello -> {uuid_hello_1}")

print("\n--- 5. COROUTINE EXECUTION & IDEMPOTENCY TEST (Pure Trampoline) ---")

def run_coroutine(coro):
    stack = [coro]
    ret = None
    while stack:
        top = stack[-1]
        try:
            val = top.send(ret)
            ret = None
            if hasattr(val, "send"):
                stack.append(val)
        except StopIteration as e:
            stack.pop()
            ret = e.value
    return ret

class MockResult:
    def __init__(self, items):
        self._items = items
    def scalars(self):
        return self
    def first(self):
        return self._items[0] if self._items else None

class MockAsyncSession:
    def __init__(self):
        self.objects = {}
        self.words_by_lemma = {}

    async def get(self, model_cls, obj_id):
        return self.objects.get((model_cls, obj_id))

    def add(self, obj):
        key = (type(obj), obj.id)
        self.objects[key] = obj
        if type(obj).__name__ == "Word":
            self.words_by_lemma[obj.lemma] = obj

    async def execute(self, stmt):
        found = None
        try:
            params = stmt.compile().params
            for p_val in params.values():
                if isinstance(p_val, str) and p_val in self.words_by_lemma:
                    found = self.words_by_lemma[p_val]
                    break
                elif isinstance(p_val, uuid.UUID) and (Word, p_val) in self.objects:
                    found = self.objects[(Word, p_val)]
                    break
        except Exception:
            pass
        return MockResult([found] if found else [])

    async def flush(self):
        return None

from app.db.seeds import seed_all
from app.core.models.learning import LearningPath, Unit, Lesson
from app.core.models.word import Word

session = MockAsyncSession()

# First run: should create new objects
stats1 = run_coroutine(seed_all(session))
print("Run 1 stats:", stats1)
assert stats1["paths"] == 2
assert stats1["units"] == 5
assert stats1["lessons"] == 10
assert stats1["words"] == 30
assert len([k for k in session.objects if k[0].__name__ == "LearningPath"]) == 2
assert len([k for k in session.objects if k[0].__name__ == "Unit"]) == 5
assert len([k for k in session.objects if k[0].__name__ == "Lesson"]) == 10
assert len([k for k in session.objects if k[0].__name__ == "Word"]) == 30

# Second run: should be completely idempotent (0 newly created, updates existing)
stats2 = run_coroutine(seed_all(session))
print("Run 2 stats (Idempotent rerun):", stats2)
assert stats2["paths"] == 0
assert stats2["units"] == 0
assert stats2["lessons"] == 0
assert stats2["words"] == 0
print("Idempotency verified: 0 duplicate paths, units, lessons, words created!")

print("\n==========================================")
print("ALL SEED DATA CRITERIA VERIFIED SUCCESSFULLY!")
print("==========================================")


print("\n==========================================")
print("ALL SEED DATA CRITERIA VERIFIED SUCCESSFULLY!")
print("==========================================")

