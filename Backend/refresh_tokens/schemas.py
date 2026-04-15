from pydantic import BaseModel
from typing import Optional
from datetime import datetime


class RefreshTokenSchema(BaseModel):
    user_id: Optional[int] = None
    token: str
    expires_at: Optional[datetime] = None
    created_at: Optional[datetime] = None
