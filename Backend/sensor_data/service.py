from sqlmodel import Session
from .models import SensorDataModel
from .schemas import SensorDataSchema
from core.logger import get_logger
from .firestore_service import SensorReading, persist_sensor_reading_to_firestore


logger = get_logger(__name__)

def save_sensor_data(db: Session, sensor_data: SensorDataSchema, *, source: str = "api"):
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

    firebase_persisted = persist_sensor_reading_to_firestore(
        SensorReading(
            sensor_data_id=sensor_data_db.sensor_data_id,
            plant_id=sensor_data_db.plant_id,
            timestamp=sensor_data_db.timestamp,
            temperature=sensor_data_db.temperature,
            humidity=sensor_data_db.humidity,
            soil_moisture=sensor_data_db.soil_moisture,
            light=sensor_data_db.light,
            source=source,
        )
    )

    logger.info(
        "Sensor data saved to SQL | plant_id=%s | timestamp=%s | temp=%s | humidity=%s | soil_moisture=%s | light=%s | source=%s | firestore=%s",
        sensor_data_db.plant_id,
        sensor_data_db.timestamp,
        sensor_data_db.temperature,
        sensor_data_db.humidity,
        sensor_data_db.soil_moisture,
        sensor_data_db.light,
        source,
        firebase_persisted,
    )
    return sensor_data_db
