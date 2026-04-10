from pydantic import BaseModel, Field
from typing import Optional

class PlantSpeciesProfileSchema(BaseModel):
    specie_name: str
    personality : str
    min_temperature: float
    max_temperature: float
    min_humidity: float
    max_humidity: float
    min_soil_moisture: float
    max_soil_moisture: float
    min_light: float
    max_light: float
    care_instructions: str
