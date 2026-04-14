from fastapi import APIRouter, Depends
from sqlmodel import Session, select

from db.session import get_session
from sensor_data.schemas import SensorDataSchema
from .models import SensorDataModel
from .service import save_sensor_data

router_sensor_data = APIRouter()

@router_sensor_data.get("/")
async def root():
    return {"message": "Hello Sensor Data"}

@router_sensor_data.get("/{plant_id}")
async def get_sensor_data(plant_id: int, db: Session = Depends(get_session)):
    try:
        sensor_data_rows = db.exec(
            select(SensorDataModel)
            .where(SensorDataModel.plant_id == plant_id)
            .order_by(SensorDataModel.timestamp.desc(), SensorDataModel.sensor_data_id.desc())
        ).all()

        latest_sensor_data = sensor_data_rows[0] if sensor_data_rows else None

        temperature_values = [
            row.temperature for row in sensor_data_rows if row.temperature is not None
        ]
        humidity_values = [
            row.humidity for row in sensor_data_rows if row.humidity is not None
        ]
        soil_moisture_values = [
            row.soil_moisture for row in sensor_data_rows if row.soil_moisture is not None
        ]
        light_values = [
            row.light for row in sensor_data_rows if row.light is not None
        ]

        averages = {
            "temperature": (
                sum(temperature_values) / len(temperature_values)
                if temperature_values
                else None
            ),
            "humidity": (
                sum(humidity_values) / len(humidity_values)
                if humidity_values
                else None
            ),
            "soil_moisture": (
                sum(soil_moisture_values) / len(soil_moisture_values)
                if soil_moisture_values
                else None
            ),
            "light": (
                sum(light_values) / len(light_values)
                if light_values
                else None
            ),
        }

    except Exception as e:
        return {"message": str(e)}

    else:
        return {
            "sensor_data": latest_sensor_data,
            "averages": averages,
            "readings_count": len(sensor_data_rows),
        }


@router_sensor_data.get("/{plant_id}/history")
async def get_sensor_data_history(
    plant_id: int,
    limit: int = 30,
    db: Session = Depends(get_session),
):
    try:
        sensor_data_rows = db.exec(
            select(SensorDataModel)
            .where(SensorDataModel.plant_id == plant_id)
            .order_by(SensorDataModel.timestamp.desc(), SensorDataModel.sensor_data_id.desc())
            .limit(limit)
        ).all()

    except Exception as e:
        return {"message": str(e)}

    else:
        return {"sensor_data": sensor_data_rows, "count": len(sensor_data_rows)}

@router_sensor_data.post("/")
async def create_sensor_data(sensor_data: SensorDataSchema, db: Session = Depends(get_session)):
    return save_sensor_data(db, sensor_data)
