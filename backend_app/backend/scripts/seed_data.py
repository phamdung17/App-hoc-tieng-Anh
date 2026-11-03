"""
scripts/seed_data.py

CLI entrypoint để chạy kịch bản nạp seed data:
  python scripts/seed_data.py
hoặc:
  python -m app.db.seeds
"""

import asyncio
import logging
import os
import sys
from pathlib import Path

# Đảm bảo đường dẫn gốc backend nằm trong sys.path
backend_dir = Path(__file__).resolve().parent.parent
if str(backend_dir) not in sys.path:
    sys.path.insert(0, str(backend_dir))

from app.core.database import AsyncSessionLocal
from app.db.seeds import SEED_PATHS, SEED_WORDS, seed_all

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
logger = logging.getLogger("scripts.seed_data")


async def run_seed() -> None:
    """Thực thi seed data trong database transaction."""
    logger.info("Khởi động phiên làm việc cơ sở dữ liệu...")
    async with AsyncSessionLocal() as session:
        async with session.begin():
            stats = await seed_all(session)

    print("\n" + "=" * 60)
    print("  LINGOUP DATABASE SEED COMPLETED SUCCESSFULLY")
    print("=" * 60)
    print(f"  - Learning Paths Seeded : {stats.get('paths', 0)}")
    print(f"  - Units Seeded          : {stats.get('units', 0)}")
    print(f"  - Lessons Seeded        : {stats.get('lessons', 0)}")
    print(f"  - Vocabulary Words      : {stats.get('words', 0)}")
    print("=" * 60 + "\n")


def main() -> None:
    if "--info" in sys.argv or "--count" in sys.argv:
        print(f"Total Seed Paths: {len(SEED_PATHS)}")
        total_units = sum(len(p.get("units", [])) for p in SEED_PATHS)
        total_lessons = sum(
            len(u.get("lessons", []))
            for p in SEED_PATHS
            for u in p.get("units", [])
        )
        print(f"Total Seed Units: {total_units}")
        print(f"Total Seed Lessons: {total_lessons}")
        print(f"Total Seed Words: {len(SEED_WORDS)}")
        return

    asyncio.run(run_seed())


if __name__ == "__main__":
    main()
