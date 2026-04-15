from pydantic import BaseModel
from typing import Optional

class PlantSpeciesProfileSchema(BaseModel):
    species_name: str
    min_temperature: float
    max_temperature: float
    min_humidity: float
    max_humidity: float
    min_soil_moisture: float
    max_soil_moisture: float
    min_light: float
    max_light: float
    care_instructions: Optional[str] = None


class PlantSpeciesProfileUpdateSchema(BaseModel):
    species_name: Optional[str] = None
    min_temperature: Optional[float] = None
    max_temperature: Optional[float] = None
    min_humidity: Optional[float] = None
    max_humidity: Optional[float] = None
    min_soil_moisture: Optional[float] = None
    max_soil_moisture: Optional[float] = None
    min_light: Optional[float] = None
    max_light: Optional[float] = None
    care_instructions: Optional[str] = None
