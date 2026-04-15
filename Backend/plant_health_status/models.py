from sqlmodel import SQLModel, Field, Relationship
from sqlalchemy import Column, BigInteger, String, Text, DateTime, ForeignKey
from typing import Optional, TYPE_CHECKING
from datetime import datetime

if TYPE_CHECKING:
    from plants.models import PlantsModel


class PlantHealthStatusModel(SQLModel, table=True):
    __tablename__ = "plant_health_status"

    plant_health_status_id: Optional[int] = Field(
        sa_column=Column(BigInteger, primary_key=True, autoincrement=True)
    )
    plant_id: Optional[int] = Field(
        sa_column=Column(BigInteger, ForeignKey("plant.plant_id"), nullable=True)
    )
    timestamp: Optional[datetime] = Field(
        sa_column=Column(DateTime, nullable=True)
    )
    status_temperature: Optional[str] = Field(
        sa_column=Column(String(45), nullable=True)
    )
    status_humidity: Optional[str] = Field(
        sa_column=Column(String(45), nullable=True)
    )
    status_light: Optional[str] = Field(
        sa_column=Column(String(45), nullable=True)
    )
    status_soil_moisture: Optional[str] = Field(
        sa_column=Column(String(45), nullable=True)
    )
    disease: Optional[str] = Field(
        sa_column=Column(String(45), nullable=True)
    )
    recommendation: Optional[str] = Field(
        sa_column=Column(Text, nullable=True)
    )

    plant: Optional["PlantsModel"] = Relationship(back_populates="health_statuses")
