from sqlmodel import SQLModel, Field, Relationship
from sqlalchemy import Column, BigInteger, String, DateTime, ForeignKey
from typing import Optional, TYPE_CHECKING
from datetime import datetime

if TYPE_CHECKING:
    from users.models import UserModel


class RefreshTokenModel(SQLModel, table=True):
    __tablename__ = "refresh_token"

    token_id: Optional[int] = Field(
        sa_column=Column(BigInteger, primary_key=True, autoincrement=True)
    )
    user_id: Optional[int] = Field(
        sa_column=Column(BigInteger, ForeignKey("user.user_id"), nullable=True)
    )
    token: str = Field(
        sa_column=Column(String(500), nullable=False)
    )
    expires_at: Optional[datetime] = Field(
        sa_column=Column(DateTime, nullable=True)
    )
    created_at: Optional[datetime] = Field(
        sa_column=Column(DateTime, nullable=True)
    )

    user: Optional["UserModel"] = Relationship(back_populates="refresh_tokens")
