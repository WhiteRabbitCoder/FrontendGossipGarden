from fastapi_mqtt import FastMQTT, MQTTConfig
from core.config import settings

mqtt_config = MQTTConfig(
    host=settings.MQTT_HOST,
    port=settings.MQTT_PORT,
    keepalive=settings.MQTT_KEEPALIVE,
    username=settings.MQTT_USERNAME,
    password=settings.MQTT_PASSWORD,
    ssl=settings.MQTT_SSL
)

fast_mqtt = FastMQTT(config=mqtt_config)
