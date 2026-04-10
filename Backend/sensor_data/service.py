from sqlmodel import Session
from .models import SensorDataModel
from .schemas import SensorDataSchema

def save_sensor_data(db: Session, sensor_data: SensorDataSchema):
    sensor_data_db = SensorDataModel(
        plant_id=sensor_data.plant_id,
        timestamp=sensor_data.timestamp,
        temperature=sensor_data.sensors.temperature,
        humidity=sensor_data.sensors.humidity,
        soil_moisture=sensor_data.sensors.soil_moisture,
        light=sensor_data.sensors.light,
    )
    db.add(sensor_data_db)
    db.commit()
    db.refresh(sensor_data_db)
    return sensor_data_db