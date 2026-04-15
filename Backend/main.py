from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
from sqlmodel import SQLModel

from plants.routes import router_plants
from plant_species_profile.router import plant_species_router
from sensor_data.routes import router_sensor_data
from db.seed_data import seed_data
from core.mqtt_config import fast_mqtt
from core.config import settings
from core.firebase_config import initialize_firebase
from db.session import engine
import db.base  # noqa: F401
import sensor_data.mqtt_handlers

def create_db_and_tables():

    SQLModel.metadata.create_all(engine)
    seed_data()

@asynccontextmanager
async def lifespan(app: FastAPI):
    print("Creando tablas...")
    create_db_and_tables()
    print("Tablas creadas correctamente.")

    initialize_firebase()

    mqtt_started = False
    if settings.MQTT_ENABLED:
        try:
            await fast_mqtt.mqtt_startup()
            mqtt_started = True
            print("✅ MQTT iniciado correctamente.")
        except Exception as exc:
            print(f"⚠️ No se pudo iniciar MQTT: {exc}")
            if settings.MQTT_FAIL_FAST:
                raise
    else:
        print("ℹ️ MQTT deshabilitado por configuración (MQTT_ENABLED=false).")

    yield

    if mqtt_started:
        await fast_mqtt.mqtt_shutdown()
        print("ℹ️ MQTT detenido correctamente.")

app = FastAPI(lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(router_plants, prefix="/plants", tags=["plants"])

app.include_router(plant_species_router, prefix="/plant_species", tags=["plant_species"])

app.include_router(router_sensor_data, prefix="/sensor_data", tags=["sensor_data"])

@app.get("/")
async def root():
    return {"message": "Api running..."}
