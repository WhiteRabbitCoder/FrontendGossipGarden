from pydantic import BaseModel
from typing import Optional


class UserAchievementSchema(BaseModel):
    achievement_id: Optional[int] = None
    user_id: Optional[int] = None
    progress: int = 0
    status: Optional[str] = None


class UserAchievementUpdateSchema(BaseModel):
    progress: Optional[int] = None
    status: Optional[str] = None
