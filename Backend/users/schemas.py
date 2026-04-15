from pydantic import BaseModel
from typing import Optional
from datetime import datetime


class UserSchema(BaseModel):
    role_id: Optional[int] = None
    name: str
    email: str
    password_hash: str
    telephone: Optional[str] = None
    is_active: bool = True


class UserUpdateSchema(BaseModel):
    role_id: Optional[int] = None
    name: Optional[str] = None
    email: Optional[str] = None
    telephone: Optional[str] = None
    is_active: Optional[bool] = None


class UserResponseSchema(BaseModel):
    user_id: int
    role_id: Optional[int] = None
    name: str
    email: str
    telephone: Optional[str] = None
    is_active: bool
    last_login: Optional[datetime] = None
    created_at: datetime
    updated_at: datetime
