"""
app/core/errors/handlers.py

Global exception handlers cho FastAPI.
Đăng ký trong main.py qua app.add_exception_handler().

Chuẩn hóa tất cả lỗi về format JSON:
  {
    "code": "ERROR_CODE",
    "message": "Human-readable message",
    "detail": {...}   # tùy chọn
  }
"""

from __future__ import annotations

import logging

from fastapi import FastAPI, Request, status
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from starlette.exceptions import HTTPException as StarletteHTTPException

logger = logging.getLogger(__name__)


# ── Response builders ─────────────────────────────────────────────────────────

def _error_response(
    status_code: int,
    code: str,
    message: str,
    detail: dict | None = None,
) -> JSONResponse:
    body: dict = {"code": code, "message": message}
    if detail:
        body["detail"] = detail
    return JSONResponse(status_code=status_code, content=body)


# ── Handlers ──────────────────────────────────────────────────────────────────

async def http_exception_handler(
    request: Request, exc: StarletteHTTPException
) -> JSONResponse:
    """
    Bắt tất cả HTTPException từ FastAPI/Starlette.
    Nếu detail đã là dict có 'code' → dùng nguyên, không đổi.
    """
    detail = exc.detail

    if isinstance(detail, dict) and "code" in detail:
        # Đã format sẵn (từ các router)
        return JSONResponse(
            status_code=exc.status_code,
            content=detail,
            headers=getattr(exc, "headers", None),
        )

    # Fallback cho HTTPException tạo bởi FastAPI nội bộ
    return _error_response(
        status_code=exc.status_code,
        code=f"HTTP_{exc.status_code}",
        message=str(detail) if detail else "An error occurred",
    )


async def validation_exception_handler(
    request: Request, exc: RequestValidationError
) -> JSONResponse:
    """
    Bắt lỗi validation Pydantic (422 Unprocessable Entity).
    Trả về danh sách field errors có cấu trúc.
    """
    errors = []
    for err in exc.errors():
        field = ".".join(str(loc) for loc in err.get("loc", []))
        errors.append({"field": field, "message": err.get("msg", ""), "type": err.get("type", "")})

    return _error_response(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        code="VALIDATION_ERROR",
        message="Request validation failed",
        detail={"errors": errors},
    )


async def unhandled_exception_handler(
    request: Request, exc: Exception
) -> JSONResponse:
    """
    Catch-all cho mọi exception không được xử lý.
    Log đầy đủ traceback, trả 500 an toàn (không leak internals).
    """
    logger.exception(
        "Unhandled exception: method=%s path=%s",
        request.method,
        request.url.path,
        exc_info=exc,
    )
    return _error_response(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        code="INTERNAL_SERVER_ERROR",
        message="An unexpected error occurred. Please try again later.",
    )


# ── Registration helper ───────────────────────────────────────────────────────

def register_exception_handlers(app: FastAPI) -> None:
    """
    Đăng ký tất cả exception handlers vào FastAPI app.
    Gọi trong create_app() trước khi include routers.
    """
    app.add_exception_handler(StarletteHTTPException, http_exception_handler)  # type: ignore[arg-type]
    app.add_exception_handler(RequestValidationError, validation_exception_handler)  # type: ignore[arg-type]
    app.add_exception_handler(Exception, unhandled_exception_handler)
