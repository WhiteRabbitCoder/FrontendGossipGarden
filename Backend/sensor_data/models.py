from sqlmodel import Field, SQLModel, Relationship
from sqlalchemy import Column, BigInteger, Float, DateTime, ForeignKey
from typing import Optional, TYPE_CHECKING
from datetime import datetime

if TYPE_CHECKING:
    from plants.models import PlantsModel


class SensorDataModel(SQLModel, table=True):
    __tablename__ = "sensor_data"

    sensor_data_id: Optional[int] = Field(
        sa_column=Column(BigInteger, primary_key=True, autoincrement=True)
    )
    plant_id: Optional[int] = Field(
        sa_column=Column(BigInteger, ForeignKey("plant.plant_id"), nullable=True)
    )
    timestamp: Optional[datetime] = Field(
        sa_column=Column(DateTime, nullable=True)
    )
    temperature: Optional[float] = Field(
        sa_column=Column(Float, nullable=True)
    )
    humidity: Optional[float] = Field(
        sa_column=Column(Float, nullable=True)
    )
    soil_moisture: Optional[float] = Field(
        sa_column=Column(Float, nullable=True)
    )
    light: Optional[float] = Field(
        sa_column=Column(Float, nullable=True)
    )

    plant: Optional["PlantsModel"] = Relationship(back_populates="sensor_data")
