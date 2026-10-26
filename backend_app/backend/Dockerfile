FROM python:3.11-slim

# Không tạo .pyc, stdout/stderr unbuffered
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# Cài Poetry
RUN pip install --no-cache-dir poetry==1.8.*

# Copy dependency files trước (cache layer)
COPY pyproject.toml poetry.lock* ./

# Cài production deps (không cài dev deps)
RUN poetry config virtualenvs.create false \
    && poetry install --only main --no-root --no-interaction

# Copy source code
COPY . .

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
