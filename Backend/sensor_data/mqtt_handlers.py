import json
from typing import Any
from gmqtt import Client as MQTTClient
from core.mqtt_config import fast_mqtt
from core.config import settings
from core.logger import get_logger
from db.session import engine
from sqlmodel import Session
from .service import save_sensor_data
from .schemas import SensorDataSchema


logger = get_logger(__name__)

@fast_mqtt.on_connect()
def connect(client: MQTTClient, flags: int, rc: int, properties: Any):
    print("✅ Conectado a HiveMQ Cloud")
    client.subscribe(settings.MQTT_TOPIC)
    print(f"🎧 Suscrito al tópico: {settings.MQTT_TOPIC}")

@fast_mqtt.on_message()
async def message(client: MQTTClient, topic: str, payload: bytes, qos: int, properties: Any):
    try:
        data = json.loads(payload.decode('utf-8'))
        logger.info("MQTT payload received | topic=%s", topic)

        # Validar datos con el Schema de Pydantic
        sensor_data = SensorDataSchema(**data)

        with Session(engine) as session:
            saved = save_sensor_data(session, sensor_data, source="mqtt")
            logger.info(
                "MQTT data persisted | topic=%s | plant_id=%s | sensor_data_id=%s",
                topic,
                sensor_data.plant_id,
                saved.sensor_data_id,
            )

    except Exception as e:
        logger.exception("Error processing MQTT message on topic=%s: %s", topic, e)
