import asyncio
import json

from fastapi import APIRouter, Depends
from fastapi.responses import StreamingResponse
from sqlmodel import Session, select
from datetime import datetime, timedelta

from db.session import get_session, engine
from core.logger import get_logger
from sensor_data.schemas import SensorDataSchema
from .models import SensorDataModel
from .service import save_sensor_data
from .firestore_service import (
    get_firestore_daily_aggregates,
    get_firestore_history,
    get_firestore_window_averages,
    test_firestore_connection,
)

router_sensor_data = APIRouter()
logger = get_logger(__name__)


@router_sensor_data.get("/firestore/health")
async def firestore_health():
    return test_firestore_connection()

@router_sensor_data.get("/")
async def root():
    return {"message": "Hello Sensor Data"}

@router_sensor_data.get("/{plant_id}")
async def get_sensor_data(plant_id: int, db: Session = Depends(get_session)):
    try:
        latest_sensor_data = db.exec(
            select(SensorDataModel)
            .where(SensorDataModel.plant_id == plant_id)
            .order_by(SensorDataModel.timestamp.desc(), SensorDataModel.sensor_data_id.desc())
        ).first()

        if latest_sensor_data is None:
            return {
                "sensor_data": None,
                "averages": {
                    "temperature": None,
                    "humidity": None,
                    "soil_moisture": None,
                    "light": None,
                },
                "readings_count": 0,
                "source": "sql",
            }

        averages = get_firestore_window_averages(plant_id, days=30)

    except Exception as e:
        return {"message": str(e)}

    else:
        return {
            "sensor_data": latest_sensor_data,
            "averages": averages,
            "readings_count": 1,
            "source": "sql",
        }


@router_sensor_data.get("/{plant_id}/stream")
async def stream_sensor_data(plant_id: int):
    async def event_generator():
        while True:
            with Session(engine) as db:
                latest_sensor_data = db.exec(
                    select(SensorDataModel)
                    .where(SensorDataModel.plant_id == plant_id)
                    .order_by(
                        SensorDataModel.timestamp.desc(),
                        SensorDataModel.sensor_data_id.desc(),
                    )
                ).first()

                payload = {
                    "plant_id": plant_id,
                    "sensor_data": (
                        {
                            "sensor_data_id": latest_sensor_data.sensor_data_id,
                            "timestamp": latest_sensor_data.timestamp.isoformat()
                            if latest_sensor_data and latest_sensor_data.timestamp
                            else None,
                            "temperature": latest_sensor_data.temperature if latest_sensor_data else None,
                            "humidity": latest_sensor_data.humidity if latest_sensor_data else None,
                            "soil_moisture": latest_sensor_data.soil_moisture if latest_sensor_data else None,
                            "light": latest_sensor_data.light if latest_sensor_data else None,
                        }
                        if latest_sensor_data
                        else None
                    ),
                }

                yield f"data: {json.dumps(payload)}\n\n"
            await asyncio.sleep(2)

    return StreamingResponse(event_generator(), media_type="text/event-stream")


@router_sensor_data.get("/{plant_id}/history")
async def get_sensor_data_history(
    plant_id: int,
    limit: int = 30,
):
    firestore_rows = get_firestore_history(plant_id, limit=limit)
    return {
        "sensor_data": firestore_rows,
        "count": len(firestore_rows),
        "source": "firestore",
    }


@router_sensor_data.get("/{plant_id}/history/window")
async def get_sensor_data_history_window(
    plant_id: int,
    days: int = 8,
    limit: int = 1000,
):
    firestore_rows = get_firestore_history(plant_id, days=days, limit=limit)
    return {
        "sensor_data": firestore_rows,
        "count": len(firestore_rows),
        "window_days": days,
        "source": "firestore",
    }


@router_sensor_data.get("/{plant_id}/history/range")
async def get_sensor_data_history_range(
    plant_id: int,
    start: str,
    end: str,
    limit: int = 1000,
):
    try:
        start_dt = datetime.fromisoformat(start)
        end_dt = datetime.fromisoformat(end)
    except Exception:
        return {
            "message": "Formato de fecha inválido. Usa ISO 8601, por ejemplo 2026-04-01T00:00:00"
        }

    firestore_rows = get_firestore_history(
        plant_id,
        start=start_dt,
        end=end_dt,
        limit=limit,
    )
    return {
        "sensor_data": firestore_rows,
        "count": len(firestore_rows),
        "start": start_dt,
        "end": end_dt,
        "source": "firestore",
    }


@router_sensor_data.get("/{plant_id}/aggregates/daily")
async def get_sensor_daily_aggregates(
    plant_id: int,
    days: int = 30,
):
    firestore_daily = get_firestore_daily_aggregates(plant_id, days=days)
    return {
        "aggregates": firestore_daily,
        "count": len(firestore_daily),
        "days": days,
        "source": "firestore",
    }

@router_sensor_data.post("/")
async def create_sensor_data(sensor_data: SensorDataSchema, db: Session = Depends(get_session)):
    saved = save_sensor_data(db, sensor_data, source="api")
    logger.info(
        "Manual sensor POST persisted | plant_id=%s | sensor_data_id=%s",
        sensor_data.plant_id,
        saved.sensor_data_id,
    )
    return saved
