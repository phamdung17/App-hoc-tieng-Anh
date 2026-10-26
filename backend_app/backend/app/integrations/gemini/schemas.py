"""
app/integrations/gemini/schemas.py

Pydantic models cho Gemini API response.
Schema đầy đủ align với scan/README.md:
- label, label_vi, confidence, ipa, pos, meaning_vi,
  example_en, example_vi, topic, bounding_box
"""

from __future__ import annotations

from pydantic import BaseModel, Field, field_validator, model_validator


class BoundingBox(BaseModel):
    """
    Bounding box chuẩn hóa trong khoảng [0.0, 1.0] tương đối với kích thước ảnh.

    Lưu ý: Gemini API thực tế trả bbox dạng [ymin, xmin, ymax, xmax] 0..1000.
    Việc chuyển đổi từ format đó sang x_min/y_min/x_max/y_max 0..1 được làm
    trong client.py trước khi parse vào model này.
    """
    x_min: float = Field(ge=0.0, le=1.0, description="Left edge (0..1)")
    y_min: float = Field(ge=0.0, le=1.0, description="Top edge (0..1)")
    x_max: float = Field(ge=0.0, le=1.0, description="Right edge (0..1)")
    y_max: float = Field(ge=0.0, le=1.0, description="Bottom edge (0..1)")

    @model_validator(mode="after")
    def validate_box_geometry(self) -> "BoundingBox":
        if self.x_max <= self.x_min:
            raise ValueError(
                f"x_max ({self.x_max}) must be greater than x_min ({self.x_min})"
            )
        if self.y_max <= self.y_min:
            raise ValueError(
                f"y_max ({self.y_max}) must be greater than y_min ({self.y_min})"
            )
        return self

    @property
    def width(self) -> float:
        return self.x_max - self.x_min

    @property
    def height(self) -> float:
        return self.y_max - self.y_min

    @property
    def area(self) -> float:
        return self.width * self.height

    def to_xywh(self) -> tuple[float, float, float, float]:
        """Chuyển sang (x, y, width, height) — format lưu vào DB."""
        return self.x_min, self.y_min, self.width, self.height


class DetectedObject(BaseModel):
    """
    Một vật thể được nhận diện bởi Gemini.
    Schema align với scan README: đủ fields cho word card.
    """
    # Nhận dạng
    label: str = Field(min_length=1, max_length=50, description="English noun (lowercase)")
    label_vi: str = Field(default="", max_length=100, description="Vietnamese translation")
    confidence: float = Field(ge=0.0, le=1.0, description="Detection confidence")

    # Word card fields (dùng để seed vào bảng words nếu chưa có)
    ipa: str = Field(default="", max_length=50, description="IPA pronunciation")
    pos: str = Field(default="noun", max_length=20, description="Part of speech")
    meaning_vi: str = Field(default="", max_length=300, description="Vietnamese meaning/definition")
    example_en: str = Field(default="", max_length=300, description="English example sentence")
    example_vi: str = Field(default="", max_length=300, description="Vietnamese translation of example")
    topic: str = Field(default="", max_length=50, description="Topic category (food, nature, etc.)")

    # Spatial
    bounding_box: BoundingBox

    @field_validator("label", mode="before")
    @classmethod
    def normalize_label(cls, v: str) -> str:
        """Lowercase và strip label."""
        return v.strip().lower()

    @field_validator("pos", mode="before")
    @classmethod
    def normalize_pos(cls, v: str) -> str:
        return v.strip().lower()


class GeminiDetectionResponse(BaseModel):
    """Response tổng hợp từ Gemini — wrapper quanh list vật thể."""
    objects: list[DetectedObject] = Field(
        default_factory=list,
        max_length=10,
        description="List các vật thể nhận diện được (tối đa 10)",
    )
