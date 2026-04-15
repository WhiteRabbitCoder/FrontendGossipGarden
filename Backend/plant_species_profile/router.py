from fastapi import APIRouter, Depends
from sqlmodel import Session, select

from db.session import get_session
from .models import PlantSpeciesProfileModel
from .schema import PlantSpeciesProfileSchema, PlantSpeciesProfileUpdateSchema

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
        plant_species_profile = db.exec(select(PlantSpeciesProfileModel).where(PlantSpeciesProfileModel.plant_specie_id == specie_id)).first()

    except Exception as e:
        return {"message": str(e)}

    else:
        return {"plant_species_profile": plant_species_profile}

@plant_species_router.post("/")
async def create_plant_species_profile(plant_species_profile: PlantSpeciesProfileSchema, db: Session = Depends(get_session)):
    try:

        plant_profile = PlantSpeciesProfileModel(
            species_name=plant_species_profile.species_name,
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


@plant_species_router.patch("/{specie_id}")
async def update_plant_species_profile(
    specie_id: int,
    plant_species_profile: PlantSpeciesProfileUpdateSchema,
    db: Session = Depends(get_session),
):
    try:
        plant_profile = db.exec(
            select(PlantSpeciesProfileModel).where(PlantSpeciesProfileModel.plant_specie_id == specie_id)
        ).first()

        if not plant_profile:
            return {"message": "Plant species profile not found"}

        update_data = plant_species_profile.model_dump(exclude_unset=True)
        for field, value in update_data.items():
            setattr(plant_profile, field, value)

        db.add(plant_profile)
        db.commit()
        db.refresh(plant_profile)

    except Exception as e:
        return {"message": str(e)}

    else:
        return {"plant_species_profile": plant_profile}


@plant_species_router.delete("/{specie_id}")
async def delete_plant_species_profile(specie_id: int, db: Session = Depends(get_session)):
    try:
        plant_profile = db.exec(
            select(PlantSpeciesProfileModel).where(PlantSpeciesProfileModel.plant_specie_id == specie_id)
        ).first()

        if not plant_profile:
            return {"message": "Plant species profile not found"}

        db.delete(plant_profile)
        db.commit()

    except Exception as e:
        return {"message": str(e)}

    else:
        return {"message": "Plant species profile deleted successfully"}
