from fastapi import APIRouter, Depends
from sqlmodel import Session, select
from datetime import datetime, timedelta

from db.session import get_session
from core.logger import get_logger
from sensor_data.schemas import SensorDataSchema
from .models import SensorDataModel
from .service import save_sensor_data
from .firestore_service import (
    get_firestore_daily_aggregates,
    get_firestore_history,
)

router_sensor_data = APIRouter()
logger = get_logger(__name__)

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
            "source": "sql",
        }


@router_sensor_data.get("/{plant_id}/history")
async def get_sensor_data_history(
    plant_id: int,
    limit: int = 30,
    db: Session = Depends(get_session),
):
    firestore_rows = get_firestore_history(plant_id, limit=limit)
    if firestore_rows:
        return {
            "sensor_data": firestore_rows,
            "count": len(firestore_rows),
            "source": "firestore",
        }

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
        return {
            "sensor_data": sensor_data_rows,
            "count": len(sensor_data_rows),
            "source": "sql",
        }


@router_sensor_data.get("/{plant_id}/history/window")
async def get_sensor_data_history_window(
    plant_id: int,
    days: int = 8,
    limit: int = 1000,
    db: Session = Depends(get_session),
):
    firestore_rows = get_firestore_history(plant_id, days=days, limit=limit)
    if firestore_rows:
        return {
            "sensor_data": firestore_rows,
            "count": len(firestore_rows),
            "window_days": days,
            "source": "firestore",
        }

    start_dt = datetime.utcnow() - timedelta(days=days)
    try:
        sensor_data_rows = db.exec(
            select(SensorDataModel)
            .where(SensorDataModel.plant_id == plant_id)
            .where(SensorDataModel.timestamp >= start_dt)
            .order_by(SensorDataModel.timestamp.desc(), SensorDataModel.sensor_data_id.desc())
            .limit(limit)
        ).all()
    except Exception as e:
        return {"message": str(e)}

    return {
        "sensor_data": sensor_data_rows,
        "count": len(sensor_data_rows),
        "window_days": days,
        "source": "sql",
    }


@router_sensor_data.get("/{plant_id}/history/range")
async def get_sensor_data_history_range(
    plant_id: int,
    start: str,
    end: str,
    limit: int = 1000,
    db: Session = Depends(get_session),
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
    if firestore_rows:
        return {
            "sensor_data": firestore_rows,
            "count": len(firestore_rows),
            "start": start_dt,
            "end": end_dt,
            "source": "firestore",
        }

    try:
        sensor_data_rows = db.exec(
            select(SensorDataModel)
            .where(SensorDataModel.plant_id == plant_id)
            .where(SensorDataModel.timestamp >= start_dt)
            .where(SensorDataModel.timestamp <= end_dt)
            .order_by(SensorDataModel.timestamp.desc(), SensorDataModel.sensor_data_id.desc())
            .limit(limit)
        ).all()
    except Exception as e:
        return {"message": str(e)}

    return {
        "sensor_data": sensor_data_rows,
        "count": len(sensor_data_rows),
        "start": start_dt,
        "end": end_dt,
        "source": "sql",
    }


@router_sensor_data.get("/{plant_id}/aggregates/daily")
async def get_sensor_daily_aggregates(
    plant_id: int,
    days: int = 30,
    db: Session = Depends(get_session),
):
    firestore_daily = get_firestore_daily_aggregates(plant_id, days=days)
    if firestore_daily:
        return {
            "aggregates": firestore_daily,
            "count": len(firestore_daily),
            "days": days,
            "source": "firestore",
        }

    start_dt = datetime.utcnow() - timedelta(days=days)
    try:
        sensor_data_rows = db.exec(
            select(SensorDataModel)
            .where(SensorDataModel.plant_id == plant_id)
            .where(SensorDataModel.timestamp >= start_dt)
            .order_by(SensorDataModel.timestamp.asc(), SensorDataModel.sensor_data_id.asc())
        ).all()
    except Exception as e:
        return {"message": str(e)}

    grouped: dict[str, dict] = {}
    for row in sensor_data_rows:
        if row.timestamp is None:
            continue
        day_key = row.timestamp.date().isoformat()
        bucket = grouped.setdefault(
            day_key,
            {
                "date": day_key,
                "plant_id": plant_id,
                "readings_count": 0,
                "temperature": {"sum": 0.0, "count": 0, "avg": None, "min": None, "max": None},
                "humidity": {"sum": 0.0, "count": 0, "avg": None, "min": None, "max": None},
                "soil_moisture": {"sum": 0.0, "count": 0, "avg": None, "min": None, "max": None},
                "light": {"sum": 0.0, "count": 0, "avg": None, "min": None, "max": None},
            },
        )
        bucket["readings_count"] += 1

        for key, value in {
            "temperature": row.temperature,
            "humidity": row.humidity,
            "soil_moisture": row.soil_moisture,
            "light": row.light,
        }.items():
            if value is None:
                continue
            metric = bucket[key]
            metric["sum"] += float(value)
            metric["count"] += 1
            metric["avg"] = metric["sum"] / metric["count"]
            metric["min"] = value if metric["min"] is None else min(metric["min"], value)
            metric["max"] = value if metric["max"] is None else max(metric["max"], value)

    aggregates = [grouped[key] for key in sorted(grouped.keys())]
    return {
        "aggregates": aggregates,
        "count": len(aggregates),
        "days": days,
        "source": "sql",
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
