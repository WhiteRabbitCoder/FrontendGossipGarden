from pydantic import BaseModel
from typing import Optional
from datetime import datetime


class FriendshipSchema(BaseModel):
    user_id: Optional[int] = None
    friend_id: Optional[int] = None
    status: Optional[str] = None


class FriendshipUpdateSchema(BaseModel):
    status: Optional[str] = None
    updated_at: Optional[datetime] = None
