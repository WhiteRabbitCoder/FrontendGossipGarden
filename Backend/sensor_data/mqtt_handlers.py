import json
from typing import Any
from gmqtt import Client as MQTTClient
from core.mqtt_config import fast_mqtt
from core.config import settings
from db.session import engine
from sqlmodel import Session
from .service import save_sensor_data
from .schemas import SensorDataSchema

@fast_mqtt.on_connect()
def connect(client: MQTTClient, flags: int, rc: int, properties: Any):
    print("✅ Conectado a HiveMQ Cloud")
    client.subscribe(settings.MQTT_TOPIC)
    print(f"🎧 Suscrito al tópico: {settings.MQTT_TOPIC}")

@fast_mqtt.on_message()
async def message(client: MQTTClient, topic: str, payload: bytes, qos: int, properties: Any):
    try:
        data = json.loads(payload.decode('utf-8'))
        print(f"\n📥 Nuevo mensaje MQTT en [{topic}]")

        # Validar datos con el Schema de Pydantic
        sensor_data = SensorDataSchema(**data)

        with Session(engine) as session:
            save_sensor_data(session, sensor_data)
            print(f"✅ Datos de planta {sensor_data.plant_id} guardados vía MQTT.")

    except Exception as e:
        print(f"❌ Error procesando mensaje MQTT: {e}")
