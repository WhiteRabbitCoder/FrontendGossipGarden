from sqlmodel import Field, SQLModel, Relationship
from sqlalchemy import Column, Integer, BigInteger, String, Text, DateTime, ForeignKey
from typing import Optional, TYPE_CHECKING
from datetime import datetime

if TYPE_CHECKING:
    from plant_species_profile.models import PlantSpeciesProfileModel
    from sensor_data.models import SensorDataModel
    from users.models import UserModel
    from tasks.models import TaskModel
    from chat_messages.models import ChatMessageModel
    from plant_health_status.models import PlantHealthStatusModel


class PlantsModel(SQLModel, table=True):
    __tablename__ = "plant"

    plant_id: Optional[int] = Field(
        sa_column=Column(Integer, primary_key=True, autoincrement=True)
    )
    user_id: Optional[int] = Field(
        sa_column=Column(BigInteger, ForeignKey("user.user_id"), nullable=True)
    )
    plant_species_id: Optional[int] = Field(
        sa_column=Column(Integer, ForeignKey("plant_species_profile.plant_species_id"), nullable=True)
    )
    name: str = Field(sa_column=Column(String(60), nullable=False))
    location: str = Field(sa_column=Column(Text, nullable=False))
    registered_at: Optional[datetime] = Field(
        sa_column=Column(DateTime, nullable=False, default=datetime.now)
    )
    visibility: int = Field(
        sa_column=Column(Integer, nullable=False, default=1)
    )

    plant_species: Optional["PlantSpeciesProfileModel"] = Relationship(back_populates="plant")
    user: Optional["UserModel"] = Relationship(back_populates="plants")
    sensor_data: list["SensorDataModel"] = Relationship(back_populates="plant")
    tasks: list["TaskModel"] = Relationship(back_populates="plant")
    chat_messages: list["ChatMessageModel"] = Relationship(back_populates="plant")
    health_statuses: list["PlantHealthStatusModel"] = Relationship(back_populates="plant")
