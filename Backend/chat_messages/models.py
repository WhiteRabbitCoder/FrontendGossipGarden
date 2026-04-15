from sqlmodel import SQLModel, Field, Relationship
from sqlalchemy import Column, BigInteger, Text, String, DateTime, ForeignKey
from typing import Optional, TYPE_CHECKING
from datetime import datetime

if TYPE_CHECKING:
    from users.models import UserModel
    from plants.models import PlantsModel


class ChatMessageModel(SQLModel, table=True):
    __tablename__ = "chat_message"

    message_id: Optional[int] = Field(
        sa_column=Column(BigInteger, primary_key=True, autoincrement=True)
    )
    user_id: Optional[int] = Field(
        sa_column=Column(BigInteger, ForeignKey("user.user_id"), nullable=True)
    )
    plant_id: Optional[int] = Field(
        sa_column=Column(BigInteger, ForeignKey("plant.plant_id"), nullable=True)
    )
    message_text: Optional[str] = Field(
        sa_column=Column(Text, nullable=True)
    )
    sender: Optional[str] = Field(
        sa_column=Column(String(45), nullable=True)
    )
    timestamp: Optional[datetime] = Field(
        sa_column=Column(DateTime, nullable=True)
    )

    user: Optional["UserModel"] = Relationship(back_populates="chat_messages")
    plant: Optional["PlantsModel"] = Relationship(back_populates="chat_messages")
