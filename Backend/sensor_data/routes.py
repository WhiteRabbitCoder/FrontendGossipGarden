from fastapi import APIRouter, Depends
from sqlmodel import Session

from db.session import get_session
from sensor_data.schemas import SensorDataSchema
from .models import SensorDataModel
from .service import save_sensor_data

router_sensor_data = APIRouter()

@router_sensor_data.get("/")
async def root():
    return {"message": "Hello Sensor Data"}

@router_sensor_data.get("/{plant_id}")
async def get_sensor_data(plant_id: int):
    return {"message": f"Hello Sensor Data for plant {plant_id}"}

@router_sensor_data.post("/")
async def create_sensor_data(sensor_data: SensorDataSchema, db: Session = Depends(get_session)):
    return save_sensor_data(db, sensor_data)