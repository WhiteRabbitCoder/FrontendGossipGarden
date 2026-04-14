import json
from typing import Any

from core.config import settings

try:
    import firebase_admin
    from firebase_admin import credentials
except ModuleNotFoundError:
    firebase_admin = None
    credentials = None


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
    if not settings.FIREBASE_ENABLED:
        print("ℹ️ Firebase deshabilitado por configuración (FIREBASE_ENABLED=false).")
        return False

    if firebase_admin is None or credentials is None:
        message = (
            "firebase-admin no está instalado. "
            "Agrega la dependencia en el entorno para habilitar Firebase."
        )
        if settings.FIREBASE_FAIL_FAST:
            raise RuntimeError(message)
        print(f"⚠️ {message}")
        return False

    try:
        firebase_admin.get_app()
        print("✅ Firebase ya estaba inicializado.")
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
            print(f"⚠️ {message}")
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
            print(f"⚠️ {message}")
            return False
    else:
        message = (
            "FIREBASE_ENABLED=true pero faltan credenciales. "
            "Define FIREBASE_CREDENTIALS_JSON o FIREBASE_CREDENTIALS_FILE."
        )
        if settings.FIREBASE_FAIL_FAST:
            raise RuntimeError(message)
        print(f"⚠️ {message}")
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
        print(f"⚠️ {message}")
        return False

    print("✅ Firebase inicializado correctamente.")
    return True
