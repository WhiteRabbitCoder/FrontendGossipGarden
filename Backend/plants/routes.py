from fastapi import APIRouter, Depends
from sqlmodel import Session, select

from .models import PlantsModel
from db.session import get_session
from plants.schemas import PlantSchema

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
            personality=plant.personality,
            visibility=plant.visibility
        )
        db.add(plant_db)
        db.commit()
        db.refresh(plant_db)

    except Exception as e:
        return {"message": str(e)}

    else:
        return plant_db




