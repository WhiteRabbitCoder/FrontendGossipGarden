from sqlmodel import Field, SQLModel, Relationship
# from plant_species_profile.models import PlantSpeciesProfileModel
# from sensor_data.models import SensorDataModel
from typing import Optional
from datetime import datetime

class PlantsModel(SQLModel, table=True):
    __tablename__ = "plant"

    plant_id: Optional[int] = Field(default=None, primary_key=True)
    plant_species_id: Optional[int] = Field(default=None,
                                                    foreign_key="plant_species_profile.plant_species_id")
    name: str
    location: str
    registered_at: datetime = Field(default_factory=datetime.now)
    visibility: int = Field(default= 1)

    plant_species: Optional["PlantSpeciesProfileModel"] = Relationship(back_populates="plant")

    sensor_data: list["SensorDataModel"] = Relationship(back_populates="plant")

