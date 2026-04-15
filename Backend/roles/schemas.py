from pydantic import BaseModel
from typing import Optional


class RoleSchema(BaseModel):
    role_name: str


class RoleUpdateSchema(BaseModel):
    role_name: Optional[str] = None
