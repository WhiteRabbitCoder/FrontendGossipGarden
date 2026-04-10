from sqlmodel import SQLModel, Field, Relationship
from typing import Optional

class PlantSpeciesProfileModel(SQLModel, table=True):
    __tablename__ = "plant_species_profile"

    plant_species_id: Optional[int] = Field(default=None, primary_key=True)
    specie_name: str
    personality: Optional[str] = None
    min_temperature: float
    max_temperature: float
    min_humidity: float
    max_humidity: float
    min_soil_moisture: float
    max_soil_moisture: float
    min_light: float
    max_light: float
    care_instructions: str

    plant: list["PlantsModel"] = Relationship(back_populates="plant_species")
