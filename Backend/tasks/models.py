from sqlmodel import SQLModel, Field, Relationship
from sqlalchemy import Column, BigInteger, Text, DateTime, ForeignKey
from typing import Optional, TYPE_CHECKING
from datetime import datetime

if TYPE_CHECKING:
    from plants.models import PlantsModel


class TaskModel(SQLModel, table=True):
    __tablename__ = "task"

    task_id: Optional[int] = Field(
        sa_column=Column(BigInteger, primary_key=True, autoincrement=True)
    )
    plant_id: Optional[int] = Field(
        sa_column=Column(BigInteger, ForeignKey("plant.plant_id"), nullable=True)
    )
    description: Optional[str] = Field(
        sa_column=Column(Text, nullable=True)
    )
    created_at: Optional[datetime] = Field(
        sa_column=Column(DateTime, nullable=True)
    )
    due_date: Optional[datetime] = Field(
        sa_column=Column(DateTime, nullable=True)
    )
    completed_at: Optional[datetime] = Field(
        sa_column=Column(DateTime, nullable=True)
    )

    plant: Optional["PlantsModel"] = Relationship(back_populates="tasks")
