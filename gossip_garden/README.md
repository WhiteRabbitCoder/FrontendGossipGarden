# Gossip Garden (Flutter)

App cliente para Gossip Garden.

## Conexion con Backend

La app usa variables de compilacion (`--dart-define`) para elegir a que backend conectarse.

Variables soportadas:

- `BACKEND_TARGET`: `local` (default) o `prod`
- `BACKEND_LOCAL_URL`: URL del backend local
- `BACKEND_DEPLOY_URL`: URL del backend desplegado

### Ejemplos

Local (Android emulador):

```bash
flutter run \
  --dart-define=BACKEND_TARGET=local \
  --dart-define=BACKEND_LOCAL_URL=http://10.0.2.2:8000
```

Local (iOS simulador):

```bash
flutter run \
  --dart-define=BACKEND_TARGET=local \
  --dart-define=BACKEND_LOCAL_URL=http://localhost:8000
```

Produccion:

```bash
flutter run \
  --dart-define=BACKEND_TARGET=prod \
  --dart-define=BACKEND_DEPLOY_URL=https://tu-api.com
```

## Endpoints consumidos

- `GET /plants`
- `GET /plant_species`
- `GET /sensor_data/{plant_id}`

La UI muestra datos procesados usando promedio historico cuando el backend lo provee.

## Nota sobre chat y auth

Chats y autenticacion Google/Firebase aun no estan implementados en esta app.
Actualmente solo se integra la capa de plantas/telemetria contra el backend PostgreSQL.
