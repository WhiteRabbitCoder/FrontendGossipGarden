from sqlmodel import SQLModel, Field, Relationship
from sqlalchemy import Column, BigInteger, Integer, String
from typing import Optional, TYPE_CHECKING

if TYPE_CHECKING:
    from user_achievements.models import UserAchievementModel


class AchievementModel(SQLModel, table=True):
    __tablename__ = "achievement"

    achievement_id: Optional[int] = Field(
        sa_column=Column(BigInteger, primary_key=True, autoincrement=True)
    )
    achievement_name: str = Field(
        sa_column=Column(String(65), nullable=False)
    )
    target: int = Field(
        sa_column=Column(Integer, nullable=False)
    )

    user_achievements: list["UserAchievementModel"] = Relationship(
        back_populates="achievement"
    )
