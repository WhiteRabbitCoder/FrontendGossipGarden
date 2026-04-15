from pydantic import BaseModel
from typing import Optional


class AchievementSchema(BaseModel):
    achievement_name: str
    target: int


class AchievementUpdateSchema(BaseModel):
    achievement_name: Optional[str] = None
    target: Optional[int] = None
