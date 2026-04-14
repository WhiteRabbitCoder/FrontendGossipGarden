from pydantic import BaseModel
from typing import Optional

class PlantSchema(BaseModel):
    name: str
    location: str
    plant_species_id: int
    visibility: Optional[int] = 1


class PlantUpdateSchema(BaseModel):
    name: Optional[str] = None
    location: Optional[str] = None
    plant_species_id: Optional[int] = None
    visibility: Optional[int] = None
