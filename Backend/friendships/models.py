from sqlmodel import SQLModel, Field, Relationship
from sqlalchemy import Column, BigInteger, String, DateTime, ForeignKey
from typing import Optional, TYPE_CHECKING
from datetime import datetime

if TYPE_CHECKING:
    from users.models import UserModel


class FriendshipModel(SQLModel, table=True):
    __tablename__ = "friendship"

    friendship_id: Optional[int] = Field(
        sa_column=Column(BigInteger, primary_key=True, autoincrement=True)
    )
    user_id: Optional[int] = Field(
        sa_column=Column(BigInteger, ForeignKey("user.user_id"), nullable=True)
    )
    friend_id: Optional[int] = Field(
        sa_column=Column(BigInteger, ForeignKey("user.user_id"), nullable=True)
    )
    status: Optional[str] = Field(
        sa_column=Column(String(45), nullable=True)
    )
    created_at: Optional[datetime] = Field(
        sa_column=Column(DateTime, nullable=True)
    )
    updated_at: Optional[datetime] = Field(
        sa_column=Column(DateTime, nullable=True)
    )

    user: Optional["UserModel"] = Relationship(
        back_populates="friendships",
        sa_relationship_kwargs={"foreign_keys": "[FriendshipModel.user_id]"},
    )
    friend: Optional["UserModel"] = Relationship(
        back_populates="friend_of",
        sa_relationship_kwargs={"foreign_keys": "[FriendshipModel.friend_id]"},
    )
