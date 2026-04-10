from fastapi_mqtt import FastMQTT, MQTTConfig

mqtt_config = MQTTConfig(
    host="0712cb0c18314a609092dfd3544c234c.s1.eu.hivemq.cloud",
    port=8883,
    keepalive=60,
    username="Danieloide",
    password="Danii123",
    ssl=True
)

fast_mqtt = FastMQTT(config=mqtt_config)