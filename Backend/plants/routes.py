from fastapi import APIRouter, Depends
from sqlmodel import Session, select

from .models import PlantsModel
from db.session import get_session
from plants.schemas import PlantSchema, PlantUpdateSchema

router_plants = APIRouter()

@router_plants.get("/")
async def get_plants(db: Session = Depends(get_session)):
    try:
        plants = db.exec(select(PlantsModel)).all()

    except Exception as e:
        return {"message": str(e)}

    else:
        return {"plants": plants}


@router_plants.get("/{plant_id}")
async def get_plant(plant_id: int, db: Session = Depends(get_session)):
    try:
        plant = db.exec(select(PlantsModel).where(PlantsModel.plant_id == plant_id)).first()

    except Exception as e:
        return {"message": str(e)}

    else:
        return {"plant": plant}

@router_plants.post("/", status_code=201)
async def create_plant(plant: PlantSchema, db: Session = Depends(get_session)):
    try:
        plant_db = PlantsModel(
            name=plant.name,
            location=plant.location,
            plant_species_id=plant.plant_species_id,
            user_id=plant.user_id,
            visibility=plant.visibility
        )
        db.add(plant_db)
        db.commit()
        db.refresh(plant_db)

    except Exception as e:
        return {"message": str(e)}

    else:
        return plant_db


@router_plants.patch("/{plant_id}")
async def update_plant(
    plant_id: int,
    plant: PlantUpdateSchema,
    db: Session = Depends(get_session),
):
    try:
        plant_db = db.exec(select(PlantsModel).where(PlantsModel.plant_id == plant_id)).first()

        if not plant_db:
            return {"message": "Plant not found"}

        update_data = plant.model_dump(exclude_unset=True)
        for field, value in update_data.items():
            setattr(plant_db, field, value)

        db.add(plant_db)
        db.commit()
        db.refresh(plant_db)

    except Exception as e:
        return {"message": str(e)}

    else:
        return plant_db


@router_plants.delete("/{plant_id}")
async def delete_plant(plant_id: int, db: Session = Depends(get_session)):
    try:
        plant_db = db.exec(select(PlantsModel).where(PlantsModel.plant_id == plant_id)).first()

        if not plant_db:
            return {"message": "Plant not found"}

        db.delete(plant_db)
        db.commit()

    except Exception as e:
        return {"message": str(e)}

    else:
        return {"message": "Plant deleted successfully"}


