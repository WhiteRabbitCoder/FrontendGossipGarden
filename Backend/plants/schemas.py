from pydantic import BaseModel
from typing import Optional

class PlantSchema(BaseModel):
    name: str
    location: str
    plant_species_id: int
    visibility: Optional[int] = 1