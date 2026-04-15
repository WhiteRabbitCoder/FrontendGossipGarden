from pydantic import BaseModel
from typing import Optional

class PlantSchema(BaseModel):
    name: str
    location: Optional[str] = None
    plant_specie_id: Optional[int] = None
    user_id: Optional[int] = None
    visibility: Optional[str] = None


class PlantUpdateSchema(BaseModel):
    name: Optional[str] = None
    location: Optional[str] = None
    plant_specie_id: Optional[int] = None
    user_id: Optional[int] = None
    visibility: Optional[str] = None
