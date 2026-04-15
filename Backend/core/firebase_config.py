import json
from typing import Any

from core.config import settings
from core.logger import get_logger

try:
    import firebase_admin
    from firebase_admin import credentials
    from firebase_admin import firestore
except ModuleNotFoundError:
    firebase_admin = None
    credentials = None
    firestore = None


logger = get_logger(__name__)
_firebase_initialized = False


def _build_firebase_options() -> dict[str, Any]:
    options: dict[str, Any] = {}
    if settings.FIREBASE_PROJECT_ID:
        options["projectId"] = settings.FIREBASE_PROJECT_ID
    if settings.FIREBASE_DATABASE_URL:
        options["databaseURL"] = settings.FIREBASE_DATABASE_URL
    if settings.FIREBASE_STORAGE_BUCKET:
        options["storageBucket"] = settings.FIREBASE_STORAGE_BUCKET
    return options


def initialize_firebase() -> bool:
    global _firebase_initialized

    if not settings.FIREBASE_ENABLED:
        logger.info("Firebase deshabilitado por configuración (FIREBASE_ENABLED=false).")
        _firebase_initialized = False
        return False

    if firebase_admin is None or credentials is None or firestore is None:
        message = (
            "firebase-admin no está instalado. "
            "Agrega la dependencia en el entorno para habilitar Firebase."
        )
        if settings.FIREBASE_FAIL_FAST:
            raise RuntimeError(message)
        logger.warning(message)
        _firebase_initialized = False
        return False

    try:
        firebase_admin.get_app()
        logger.info("Firebase ya estaba inicializado.")
        _firebase_initialized = True
        return True
    except ValueError:
        pass

    cert_source = None

    if settings.FIREBASE_CREDENTIALS_JSON:
        try:
            cert_source = credentials.Certificate(
                json.loads(settings.FIREBASE_CREDENTIALS_JSON)
            )
        except json.JSONDecodeError as exc:
            message = (
                "FIREBASE_CREDENTIALS_JSON no contiene JSON válido. "
                "No se pudo inicializar Firebase."
            )
            if settings.FIREBASE_FAIL_FAST:
                raise RuntimeError(message) from exc
            logger.warning(message)
            _firebase_initialized = False
            return False
    elif settings.FIREBASE_CREDENTIALS_FILE:
        try:
            cert_source = credentials.Certificate(settings.FIREBASE_CREDENTIALS_FILE)
        except Exception as exc:
            message = (
                "No se pudo leer FIREBASE_CREDENTIALS_FILE. "
                "Revisa que la ruta exista y el JSON sea válido."
            )
            if settings.FIREBASE_FAIL_FAST:
                raise RuntimeError(message) from exc
            logger.warning(message)
            _firebase_initialized = False
            return False
    else:
        message = (
            "FIREBASE_ENABLED=true pero faltan credenciales. "
            "Define FIREBASE_CREDENTIALS_JSON o FIREBASE_CREDENTIALS_FILE."
        )
        if settings.FIREBASE_FAIL_FAST:
            raise RuntimeError(message)
        logger.warning(message)
        _firebase_initialized = False
        return False

    options = _build_firebase_options()
    try:
        if options:
            firebase_admin.initialize_app(cert_source, options)
        else:
            firebase_admin.initialize_app(cert_source)
    except Exception as exc:
        message = "No se pudo inicializar Firebase con la configuración actual."
        if settings.FIREBASE_FAIL_FAST:
            raise RuntimeError(message) from exc
        logger.warning(message)
        _firebase_initialized = False
        return False

    logger.info("Firebase inicializado correctamente.")
    _firebase_initialized = True
    return True


def is_firebase_ready() -> bool:
    return _firebase_initialized


def get_firestore_client() -> Any | None:
    if not _firebase_initialized or firestore is None:
        return None

    try:
        return firestore.client()
    except Exception as exc:
        logger.warning("No se pudo crear cliente Firestore: %s", exc)
        return None
