"""S3 compatible private storage used for uploaded scan images."""

from __future__ import annotations

import asyncio
from functools import lru_cache

import boto3

from app.core.config import settings


@lru_cache(maxsize=1)
def _client():
    return boto3.client(
        "s3",
        endpoint_url=settings.STORAGE_ENDPOINT,
        region_name=settings.STORAGE_REGION,
        aws_access_key_id=settings.STORAGE_ACCESS_KEY,
        aws_secret_access_key=settings.STORAGE_SECRET_KEY,
    )


async def upload_private_image(key: str, body: bytes, content_type: str) -> None:
    await asyncio.to_thread(
        _client().put_object,
        Bucket=settings.STORAGE_BUCKET_PRIVATE,
        Key=key,
        Body=body,
        ContentType=content_type,
    )


async def create_private_image_url(key: str) -> str:
    return await asyncio.to_thread(
        _client().generate_presigned_url,
        "get_object",
        Params={"Bucket": settings.STORAGE_BUCKET_PRIVATE, "Key": key},
        ExpiresIn=settings.STORAGE_PRESIGN_TTL,
    )
