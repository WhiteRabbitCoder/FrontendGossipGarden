from sqlmodel import SQLModel, Field, Relationship
from sqlalchemy import Column, BigInteger, Integer, String, ForeignKey
from typing import Optional, TYPE_CHECKING

if TYPE_CHECKING:
    from achievements.models import AchievementModel
    from users.models import UserModel


class UserAchievementModel(SQLModel, table=True):
    __tablename__ = "user_achievement"

    user_achievement_id: Optional[int] = Field(
        sa_column=Column(BigInteger, primary_key=True, autoincrement=True)
    )
    achievement_id: Optional[int] = Field(
        sa_column=Column(BigInteger, ForeignKey("achievement.achievement_id"), nullable=True)
    )
    user_id: Optional[int] = Field(
        sa_column=Column(BigInteger, ForeignKey("user.user_id"), nullable=True)
    )
    progress: int = Field(
        sa_column=Column(Integer, nullable=False, default=0)
    )
    status: Optional[str] = Field(
        sa_column=Column(String(55), nullable=True)
    )

    achievement: Optional["AchievementModel"] = Relationship(back_populates="user_achievements")
    user: Optional["UserModel"] = Relationship(back_populates="user_achievements")
