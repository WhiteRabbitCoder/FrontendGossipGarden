from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timedelta
from typing import Any
from uuid import uuid4

from core.firebase_config import get_firestore_client, is_firebase_ready
from core.logger import get_logger


logger = get_logger(__name__)


@dataclass
class SensorReading:
    sensor_data_id: int | None
    plant_id: int
    timestamp: datetime
    temperature: float | None
    humidity: float | None
    soil_moisture: float | None
    light: float | None
    source: str


def persist_sensor_reading_to_firestore(reading: SensorReading) -> bool:
    """
    Stores raw sensor reading under plants/{plant_id}/readings/{reading_id_or_ts}
    and updates a daily aggregate doc under plants/{plant_id}/daily/{YYYY-MM-DD}.
    """
    if not is_firebase_ready():
        return False

    firestore_client = get_firestore_client()
    if firestore_client is None:
        return False

    ts = _ensure_utc(reading.timestamp)
    reading_doc_id = (
        str(reading.sensor_data_id)
        if reading.sensor_data_id is not None
        else f"{int(ts.timestamp() * 1000)}-{reading.plant_id}"
    )

    reading_payload: dict[str, Any] = {
        "sensor_data_id": reading.sensor_data_id,
        "plant_id": reading.plant_id,
        "timestamp": ts,
        "timestamp_iso": ts.isoformat(),
        "temperature": reading.temperature,
        "humidity": reading.humidity,
        "soil_moisture": reading.soil_moisture,
        "light": reading.light,
        "source": reading.source,
        "ingested_at": datetime.utcnow(),
    }

    try:
        plant_ref = firestore_client.collection("plants").document(str(reading.plant_id))
        plant_ref.set(
            {
                "plant_id": reading.plant_id,
                "latest": reading_payload,
                "updated_at": datetime.utcnow(),
            },
            merge=True,
        )

        plant_ref.collection("readings").document(reading_doc_id).set(reading_payload)

        _upsert_daily_aggregate(firestore_client, reading)

    except Exception as exc:
        logger.exception(
            "Failed to persist sensor reading to Firestore | plant_id=%s | error=%s",
            reading.plant_id,
            exc,
        )
        return False

    logger.info(
        "Sensor reading persisted to Firestore | plant_id=%s | doc_id=%s",
        reading.plant_id,
        reading_doc_id,
    )
    return True


def get_firestore_history(
    plant_id: int,
    *,
    days: int | None = None,
    start: datetime | None = None,
    end: datetime | None = None,
    limit: int = 500,
) -> list[dict[str, Any]]:
    if not is_firebase_ready():
        return []

    firestore_client = get_firestore_client()
    if firestore_client is None:
        return []

    now = datetime.utcnow()
    start_dt = _ensure_utc(start) if start else None
    end_dt = _ensure_utc(end) if end else _ensure_utc(now)

    if days is not None:
        start_dt = _ensure_utc(now - timedelta(days=days))

    query = (
        firestore_client.collection("plants")
        .document(str(plant_id))
        .collection("readings")
        .order_by("timestamp")
    )

    if start_dt is not None:
        query = query.where("timestamp", ">=", start_dt)
    if end_dt is not None:
        query = query.where("timestamp", "<=", end_dt)

    query = query.limit(limit)

    try:
        docs = query.stream()
    except Exception as exc:
        logger.exception(
            "Failed to query Firestore history | plant_id=%s | error=%s",
            plant_id,
            exc,
        )
        return []

    result: list[dict[str, Any]] = []
    for doc in docs:
        data = doc.to_dict() or {}
        ts = data.get("timestamp")
        if hasattr(ts, "isoformat"):
            data["timestamp"] = ts.isoformat()
        result.append(data)

    return result


def get_firestore_daily_aggregates(
    plant_id: int,
    *,
    days: int,
    limit: int = 90,
) -> list[dict[str, Any]]:
    if not is_firebase_ready():
        return []

    firestore_client = get_firestore_client()
    if firestore_client is None:
        return []

    now = datetime.utcnow()
    start_dt = now - timedelta(days=days)
    start_key = start_dt.date().isoformat()

    query = (
        firestore_client.collection("plants")
        .document(str(plant_id))
        .collection("daily")
        .where("date", ">=", start_key)
        .order_by("date")
        .limit(limit)
    )

    try:
        docs = query.stream()
    except Exception as exc:
        logger.exception(
            "Failed to query Firestore daily aggregates | plant_id=%s | error=%s",
            plant_id,
            exc,
        )
        return []

    return [doc.to_dict() or {} for doc in docs]


def get_firestore_window_averages(plant_id: int, *, days: int = 30) -> dict[str, float | None]:
    daily = get_firestore_daily_aggregates(plant_id, days=days)
    if not daily:
        return {
            "temperature": None,
            "humidity": None,
            "soil_moisture": None,
            "light": None,
        }

    totals = {
        "temperature": {"sum": 0.0, "count": 0},
        "humidity": {"sum": 0.0, "count": 0},
        "soil_moisture": {"sum": 0.0, "count": 0},
        "light": {"sum": 0.0, "count": 0},
    }

    for day in daily:
        for key in totals.keys():
            metric = day.get(key)
            if not isinstance(metric, dict):
                continue
            metric_sum = metric.get("sum")
            metric_count = metric.get("count")
            if metric_sum is None or metric_count is None:
                continue
            try:
                sum_value = float(metric_sum)
                count_value = int(metric_count)
            except (TypeError, ValueError):
                continue

            totals[key]["sum"] += sum_value
            totals[key]["count"] += count_value

    return {
        key: (values["sum"] / values["count"] if values["count"] > 0 else None)
        for key, values in totals.items()
    }


def test_firestore_connection() -> dict[str, Any]:
    if not is_firebase_ready():
        return {"ok": False, "reason": "Firebase no inicializado"}

    firestore_client = get_firestore_client()
    if firestore_client is None:
        return {"ok": False, "reason": "No se pudo crear cliente Firestore"}

    doc_id = uuid4().hex
    doc_ref = firestore_client.collection("healthchecks").document(doc_id)
    payload = {
        "type": "firestore-connection-test",
        "created_at": datetime.utcnow(),
        "ok": True,
    }

    try:
        doc_ref.set(payload)
        snapshot = doc_ref.get()
        exists = snapshot.exists
        doc_ref.delete()
    except Exception as exc:
        logger.exception("Firestore connection test failed: %s", exc)
        return {"ok": False, "reason": str(exc)}

    return {
        "ok": bool(exists),
        "reason": None if exists else "No se pudo leer documento de prueba",
    }


def _upsert_daily_aggregate(firestore_client: Any, reading: SensorReading) -> None:
    ts = _ensure_utc(reading.timestamp)
    date_key = ts.date().isoformat()
    daily_ref = (
        firestore_client.collection("plants")
        .document(str(reading.plant_id))
        .collection("daily")
        .document(date_key)
    )

    snapshot = daily_ref.get()
    current = snapshot.to_dict() if snapshot.exists else None

    if current is None:
        base_payload = {
            "date": date_key,
            "plant_id": reading.plant_id,
            "readings_count": 0,
            "temperature": _metric_seed(),
            "humidity": _metric_seed(),
            "soil_moisture": _metric_seed(),
            "light": _metric_seed(),
            "updated_at": datetime.utcnow(),
        }
    else:
        base_payload = {
            "date": current.get("date", date_key),
            "plant_id": current.get("plant_id", reading.plant_id),
            "readings_count": int(current.get("readings_count", 0)),
            "temperature": _metric_from_doc(current.get("temperature")),
            "humidity": _metric_from_doc(current.get("humidity")),
            "soil_moisture": _metric_from_doc(current.get("soil_moisture")),
            "light": _metric_from_doc(current.get("light")),
            "updated_at": datetime.utcnow(),
        }

    base_payload["readings_count"] += 1

    _metric_update(base_payload["temperature"], reading.temperature)
    _metric_update(base_payload["humidity"], reading.humidity)
    _metric_update(base_payload["soil_moisture"], reading.soil_moisture)
    _metric_update(base_payload["light"], reading.light)

    daily_ref.set(base_payload, merge=True)


def _metric_seed() -> dict[str, Any]:
    return {
        "sum": 0.0,
        "count": 0,
        "avg": None,
        "min": None,
        "max": None,
    }


def _metric_from_doc(data: Any) -> dict[str, Any]:
    if not isinstance(data, dict):
        return _metric_seed()

    return {
        "sum": float(data.get("sum", 0.0)),
        "count": int(data.get("count", 0)),
        "avg": data.get("avg"),
        "min": data.get("min"),
        "max": data.get("max"),
    }


def _metric_update(metric: dict[str, Any], value: float | None) -> None:
    if value is None:
        return

    metric["sum"] = float(metric.get("sum", 0.0)) + float(value)
    metric["count"] = int(metric.get("count", 0)) + 1
    metric["avg"] = metric["sum"] / metric["count"]

    current_min = metric.get("min")
    current_max = metric.get("max")
    metric["min"] = value if current_min is None else min(float(current_min), float(value))
    metric["max"] = value if current_max is None else max(float(current_max), float(value))


def _ensure_utc(value: datetime | None) -> datetime:
    if value is None:
        return datetime.utcnow()
    if value.tzinfo is not None:
        return value.replace(tzinfo=None)
    return value
