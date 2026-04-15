from sqlmodel import SQLModel, Field, Relationship
from sqlalchemy import Column, BigInteger, String, Float, Text
from typing import Optional, TYPE_CHECKING

if TYPE_CHECKING:
    from plants.models import PlantsModel


class PlantSpeciesProfileModel(SQLModel, table=True):
    __tablename__ = "plant_species_profile"

    plant_specie_id: Optional[int] = Field(
        sa_column=Column(BigInteger, primary_key=True, autoincrement=True)
    )
    species_name: str = Field(sa_column=Column(String(100), nullable=False))
    min_temperature: float = Field(sa_column=Column(Float, nullable=False))
    max_temperature: float = Field(sa_column=Column(Float, nullable=False))
    min_humidity: float = Field(sa_column=Column(Float, nullable=False))
    max_humidity: float = Field(sa_column=Column(Float, nullable=False))
    min_soil_moisture: float = Field(sa_column=Column(Float, nullable=False))
    max_soil_moisture: float = Field(sa_column=Column(Float, nullable=False))
    min_light: float = Field(sa_column=Column(Float, nullable=False))
    max_light: float = Field(sa_column=Column(Float, nullable=False))
    care_instructions: Optional[str] = Field(sa_column=Column(Text, nullable=True))

    plant: list["PlantsModel"] = Relationship(back_populates="plant_species")
