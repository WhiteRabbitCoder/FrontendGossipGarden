from fastapi import FastAPI
from contextlib import asynccontextmanager
from sqlmodel import SQLModel

from plants.routes import router_plants
from plant_species_profile.router import plant_species_router
from db.seed_data import seed_data
from core.mqtt_config import fast_mqtt
from db.session import engine
import sensor_data.mqtt_handlers

def create_db_and_tables():

    SQLModel.metadata.create_all(engine)
    seed_data()

@asynccontextmanager
async def lifespan(app: FastAPI):
    print("Creando tablas...")
    create_db_and_tables()
    print("Tablas creadas correctamente.")

    await fast_mqtt.mqtt_startup()
    yield

    await fast_mqtt.mqtt_shutdown()

app = FastAPI(lifespan=lifespan)

app.include_router(router_plants, prefix="/plants", tags=["plants"])

app.include_router(plant_species_router, prefix="/plant_species", tags=["plant_species"])

@app.get("/")
async def root():
    return {"message": "Api running..."}
