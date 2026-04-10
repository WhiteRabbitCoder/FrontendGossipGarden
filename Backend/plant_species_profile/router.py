from fastapi import APIRouter, Depends
from sqlmodel import Session, select

from db.session import get_session
from .models import PlantSpeciesProfileModel
from .schema import PlantSpeciesProfileSchema

plant_species_router = APIRouter()

@plant_species_router.get("/")
async def root(db: Session = Depends(get_session)):
    try:
        plant_species_profiles = db.exec(select(PlantSpeciesProfileModel)).all()

    except Exception as e:
        return {"message": str(e)}

    else:
        return {"plant_species_profiles": plant_species_profiles}


@plant_species_router.get("/{specie_id}")
async def get_plant_species_profile(specie_id: int, db: Session = Depends(get_session)):
    try:
        plant_species_profile = db.exec(select(PlantSpeciesProfileModel).where(PlantSpeciesProfileModel.plant_species_id == specie_id)).first()

    except Exception as e:
        return {"message": str(e)}

    else:
        return {"plant_species_profile": plant_species_profile}

@plant_species_router.post("/")
async def create_plant_species_profile(plant_species_profile: PlantSpeciesProfileSchema, db: Session = Depends(get_session)):
    try:

        plant_profile = PlantSpeciesProfileModel(
            specie_name=plant_species_profile.specie_name,
            min_temperature=plant_species_profile.min_temperature,
            max_temperature=plant_species_profile.max_temperature,
            min_humidity=plant_species_profile.min_humidity,
            max_humidity=plant_species_profile.max_humidity,
            min_soil_moisture=plant_species_profile.min_soil_moisture,
            max_soil_moisture=plant_species_profile.max_soil_moisture,
            min_light=plant_species_profile.min_light,
            max_light=plant_species_profile.max_light,
            care_instructions=plant_species_profile.care_instructions
        )

        db.add(plant_profile)
        db.commit()
        db.refresh(plant_profile)

    except Exception as e:
        return {"message": str(e)}

    else:
        return {
            "message": plant_profile
        }

