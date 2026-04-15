from sqlmodel import SQLModel, Field, Relationship
from sqlalchemy import Column, Integer, String
from typing import Optional, TYPE_CHECKING

if TYPE_CHECKING:
    from users.models import UserModel


class RoleModel(SQLModel, table=True):
    __tablename__ = "role"

    role_id: Optional[int] = Field(
        sa_column=Column(Integer, primary_key=True, autoincrement=True)
    )
    role_name: str = Field(sa_column=Column(String(45), nullable=False))

    users: list["UserModel"] = Relationship(back_populates="role")
