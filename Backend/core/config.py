from urllib.parse import quote_plus

from pydantic import ValidationInfo, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    # Relational database settings.
    DATABASE_URL: str | None = None
    POSTGRES_USER: str | None = None
    POSTGRES_PASSWORD: str | None = None
    POSTGRES_DB: str | None = None
    POSTGRES_HOST: str | None = None
    POSTGRES_PORT: int = 5432

    # MQTT settings. If env vars are missing or invalid, defaults are used.
    MQTT_ENABLED: bool = True
    MQTT_FAIL_FAST: bool = False
    MQTT_HOST: str = "0712cb0c18314a609092dfd3544c234c.s1.eu.hivemq.cloud"
    MQTT_PORT: int = 8883
    MQTT_KEEPALIVE: int = 60
    MQTT_USERNAME: str = "Danieloide"
    MQTT_PASSWORD: str = "Danii123"
    MQTT_SSL: bool = True
    MQTT_TOPIC: str = "plantas/esp32_01/sensores"

    # Firebase settings (optional for now).
    FIREBASE_ENABLED: bool = False
    FIREBASE_FAIL_FAST: bool = False
    FIREBASE_CREDENTIALS_JSON: str | None = None
    FIREBASE_CREDENTIALS_FILE: str | None = None
    FIREBASE_PROJECT_ID: str | None = None
    FIREBASE_DATABASE_URL: str | None = None
    FIREBASE_STORAGE_BUCKET: str | None = None

    @field_validator("POSTGRES_PORT", "MQTT_PORT", "MQTT_KEEPALIVE", mode="before")
    @classmethod
    def parse_ints_with_fallback(cls, value: object, info: ValidationInfo) -> int:
        defaults = {
            "POSTGRES_PORT": 5432,
            "MQTT_PORT": 8883,
            "MQTT_KEEPALIVE": 60,
        }
        default_value = defaults[info.field_name]

        if value in (None, ""):
            return default_value
        try:
            return int(value)
        except (TypeError, ValueError):
            print(
                f"⚠️ Valor inválido para {info.field_name}: {value!r}. "
                f"Usando fallback {default_value}."
            )
            return default_value

    @field_validator(
        "MQTT_ENABLED",
        "MQTT_FAIL_FAST",
        "MQTT_SSL",
        "FIREBASE_ENABLED",
        "FIREBASE_FAIL_FAST",
        mode="before",
    )
    @classmethod
    def parse_bools_with_fallback(cls, value: object, info: ValidationInfo) -> bool:
        defaults = {
            "MQTT_ENABLED": True,
            "MQTT_FAIL_FAST": False,
            "MQTT_SSL": True,
            "FIREBASE_ENABLED": False,
            "FIREBASE_FAIL_FAST": False,
        }
        default_value = defaults[info.field_name]

        if isinstance(value, bool):
            return value
        if value in (None, ""):
            return default_value

        normalized = str(value).strip().lower()
        if normalized in {"1", "true", "yes", "on"}:
            return True
        if normalized in {"0", "false", "no", "off"}:
            return False

        print(
            f"⚠️ Valor inválido para {info.field_name}: {value!r}. "
            f"Usando fallback {default_value}."
        )
        return default_value

    @property
    def database_url(self) -> str:
        if self.DATABASE_URL and self.DATABASE_URL.strip():
            return self.DATABASE_URL.strip()

        pg_values = [
            self.POSTGRES_USER,
            self.POSTGRES_PASSWORD,
            self.POSTGRES_HOST,
            self.POSTGRES_DB,
        ]
        if all(pg_values):
            user = quote_plus(self.POSTGRES_USER.strip())
            password = quote_plus(self.POSTGRES_PASSWORD.strip())
            host = self.POSTGRES_HOST.strip()
            database = self.POSTGRES_DB.strip()
            return f"postgresql://{user}:{password}@{host}:{self.POSTGRES_PORT}/{database}"

        raise ValueError(
            "DATABASE_URL no está configurada. "
            "Define DATABASE_URL o POSTGRES_USER/POSTGRES_PASSWORD/"
            "POSTGRES_HOST/POSTGRES_DB."
        )


settings = Settings()
