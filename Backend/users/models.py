from sqlmodel import SQLModel, Field, Relationship
from sqlalchemy import Column, BigInteger, Integer, String, Boolean, DateTime, ForeignKey
from typing import Optional, TYPE_CHECKING
from datetime import datetime

if TYPE_CHECKING:
    from roles.models import RoleModel
    from plants.models import PlantsModel
    from chat_messages.models import ChatMessageModel
    from user_achievements.models import UserAchievementModel
    from friendships.models import FriendshipModel
    from refresh_tokens.models import RefreshTokenModel


class UserModel(SQLModel, table=True):
    __tablename__ = "user"

    user_id: Optional[int] = Field(
        sa_column=Column(BigInteger, primary_key=True, autoincrement=True)
    )
    role_id: Optional[int] = Field(
        sa_column=Column(Integer, ForeignKey("role.role_id"), nullable=True)
    )
    name: str = Field(sa_column=Column(String(100), nullable=False))
    email: str = Field(sa_column=Column(String(60), nullable=False, unique=True))
    password_hash: str = Field(sa_column=Column(String(255), nullable=False))
    telephone: Optional[str] = Field(
        sa_column=Column(String(15), nullable=True)
    )
    is_active: bool = Field(
        sa_column=Column(Boolean, nullable=False, default=True)
    )
    last_login: Optional[datetime] = Field(
        sa_column=Column(DateTime, nullable=True)
    )
    created_at: datetime = Field(
        sa_column=Column(DateTime, nullable=False, default=datetime.now)
    )
    updated_at: datetime = Field(
        sa_column=Column(DateTime, nullable=False, default=datetime.now, onupdate=datetime.now)
    )

    role: Optional["RoleModel"] = Relationship(back_populates="users")
    plants: list["PlantsModel"] = Relationship(back_populates="user")
    chat_messages: list["ChatMessageModel"] = Relationship(back_populates="user")
    user_achievements: list["UserAchievementModel"] = Relationship(back_populates="user")
    friendships: list["FriendshipModel"] = Relationship(
        back_populates="user",
        sa_relationship_kwargs={"foreign_keys": "FriendshipModel.user_id"},
    )
    friend_of: list["FriendshipModel"] = Relationship(
        back_populates="friend",
        sa_relationship_kwargs={"foreign_keys": "FriendshipModel.friend_id"},
    )
    refresh_tokens: list["RefreshTokenModel"] = Relationship(back_populates="user")
