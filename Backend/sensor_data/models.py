from sqlmodel import Field, SQLModel, Relationship
from plants.models import PlantsModel
from typing import Optional
from datetime import datetime

class SensorDataModel(SQLModel, table=True):
    __tablename__ = "sensor_data"

    sensor_data_id: Optional[int] = Field(default=None, primary_key=True)
    plant_id: int = Field(foreign_key="plant.plant_id")
    timestamp: datetime
    temperature: Optional[float] = Field(default=None)
    humidity: Optional[float] = Field(default=None)
    soil_moisture: float = Field(default=None)
    light: Optional[float] = Field(default=None)
    plant: Optional["PlantsModel"] = Relationship(back_populates="sensor_data")
