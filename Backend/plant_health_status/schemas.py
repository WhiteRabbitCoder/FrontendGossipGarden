from pydantic import BaseModel
from typing import Optional
from datetime import datetime


class PlantHealthStatusSchema(BaseModel):
    plant_id: Optional[int] = None
    timestamp: Optional[datetime] = None
    status_temperature: Optional[str] = None
    status_humidity: Optional[str] = None
    status_light: Optional[str] = None
    status_soil_moisture: Optional[str] = None
    disease: Optional[str] = None
    recommendation: Optional[str] = None


class PlantHealthStatusUpdateSchema(BaseModel):
    status_temperature: Optional[str] = None
    status_humidity: Optional[str] = None
    status_light: Optional[str] = None
    status_soil_moisture: Optional[str] = None
    disease: Optional[str] = None
    recommendation: Optional[str] = None
