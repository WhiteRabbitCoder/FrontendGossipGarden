from pydantic import BaseModel
from datetime import datetime
from typing import Optional

class SensorPlantSchema(BaseModel):
    temperature: Optional[float] = None
    humidity: Optional[float] = None
    soil_moisture: Optional[float] = None
    light: Optional[float] = None

class SensorDataSchema(BaseModel):
    plant_id: int
    timestamp: datetime
    sensors: SensorPlantSchema
