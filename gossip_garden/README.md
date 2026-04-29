# Gossip Garden (Flutter)

App cliente de Gossip Garden. Muestra el estado de las plantas del usuario (humedad, temperatura, luz, salud, mood) consumiendo telemetría del backend en tiempo real, con autenticación opcional vía Google/Firebase y chat por planta persistido en Firestore.

---

## Requisitos

- **Flutter SDK** compatible con Dart `>=3.0.0 <4.0.0`.
- **Android Studio** + Android SDK + Command-line Tools (necesario aunque solo corras en emulador iOS o web — Flutter lo valida).
- Un dispositivo o emulador (Android emulator, iOS simulator, Chrome, escritorio Linux/macOS/Windows).
- Para auth/chat real: un proyecto de **Firebase** con Authentication (Google) y Firestore habilitados.

> Si es la primera vez que configuras Android Studio + Flutter en esta máquina, sigue antes [`../README_CONFIG.md`](../README_CONFIG.md). Cuando `flutter doctor` salga en verde para Android, vuelve aquí.

---

## Primer arranque

Desde la carpeta `gossip_garden/`:

```bash
flutter pub get        # instala dependencias
flutter doctor         # verifica toolchain (debe estar en verde)
flutter run            # arranca la app contra el backend remoto (Railway)
```

Por defecto la app apunta al backend desplegado en `https://gossip-garden-backend.up.railway.app` y corre **sin Firebase** (auth y chat usan fallbacks locales). Eso es suficiente para ver plantas y telemetría.

---

## Modos de arranque

La configuración se inyecta en tiempo de compilación con `--dart-define`. No hay archivos `.env` ni `firebase_options.dart` — todo entra por flags.

### 1. Backend remoto (default)

```bash
flutter run
# equivalente explícito:
flutter run --dart-define=BACKEND_TARGET=remote
```

### 2. Backend local

Levanta el backend en `localhost:8000` (rama de backend, no esta) y luego:

```bash
# Android emulator → host loopback
flutter run \
  --dart-define=BACKEND_TARGET=local \
  --dart-define=BACKEND_LOCAL_URL=http://10.0.2.2:8000

# iOS simulator / desktop / web
flutter run \
  --dart-define=BACKEND_TARGET=local \
  --dart-define=BACKEND_LOCAL_URL=http://localhost:8000
```

### 3. Con Firebase (auth Google + chat persistido)

Todas las claves marcadas como obligatorias deben pasarse juntas — si falta una, `FirebaseEnvironment.isConfigured` queda en `false` y la app cae a los fallbacks locales:

```bash
flutter run \
  --dart-define=BACKEND_TARGET=remote \
  --dart-define=ENABLE_FIREBASE=true \
  --dart-define=FIREBASE_API_KEY=... \
  --dart-define=FIREBASE_APP_ID=... \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=... \
  --dart-define=FIREBASE_PROJECT_ID=... \
  --dart-define=FIREBASE_STORAGE_BUCKET=... \
  --dart-define=FIREBASE_AUTH_DOMAIN=... \
  --dart-define=FIREBASE_MEASUREMENT_ID=...
```

Para no escribir el bloque cada vez, usa un archivo `--dart-define-from-file=run.json`:

```json
{
  "BACKEND_TARGET": "remote",
  "ENABLE_FIREBASE": "true",
  "FIREBASE_API_KEY": "...",
  "FIREBASE_APP_ID": "...",
  "FIREBASE_MESSAGING_SENDER_ID": "...",
  "FIREBASE_PROJECT_ID": "...",
  "FIREBASE_STORAGE_BUCKET": "...",
  "FIREBASE_AUTH_DOMAIN": "...",
  "FIREBASE_MEASUREMENT_ID": "..."
}
```

```bash
flutter run --dart-define-from-file=run.json
```

> No commitees `run.json` — añádelo a `.gitignore` local. Las claves Firebase del cliente no son secretas pero conviene no fijarlas en el repo.

---

## Variables de compilación

| Variable                       | Default                                              | Notas                                                 |
| ------------------------------ | ---------------------------------------------------- | ----------------------------------------------------- |
| `BACKEND_TARGET`               | `remote`                                             | `local` \| `prod` \| `production` \| `deploy` \| `remote` |
| `BACKEND_LOCAL_URL`            | `http://10.0.2.2:8000`                               | Loopback del host para Android emulator               |
| `BACKEND_DEPLOY_URL`           | `https://gossip-garden-backend.up.railway.app`       | Backend Railway en producción                         |
| `ENABLE_FIREBASE`              | `false`                                              | Activa auth Google + chat Firestore                   |
| `FIREBASE_API_KEY`             | —                                                    | Obligatorio si `ENABLE_FIREBASE=true`                 |
| `FIREBASE_APP_ID`              | —                                                    | Obligatorio                                           |
| `FIREBASE_MESSAGING_SENDER_ID` | —                                                    | Obligatorio                                           |
| `FIREBASE_PROJECT_ID`          | —                                                    | Obligatorio                                           |
| `FIREBASE_STORAGE_BUCKET`      | —                                                    | Opcional                                              |
| `FIREBASE_AUTH_DOMAIN`         | —                                                    | Opcional                                              |
| `FIREBASE_MEASUREMENT_ID`      | —                                                    | Opcional                                              |

---

## Comandos útiles

```bash
flutter pub get                                              # instalar deps
flutter analyze                                              # lint (flutter_lints)
flutter test                                                 # toda la suite
flutter test test/widget_test.dart                           # un archivo
flutter test --plain-name "App renders login entry point"    # un test por nombre
flutter clean && flutter pub get                             # reset de build
flutter build apk --dart-define=BACKEND_TARGET=remote        # APK release
```

---

## Endpoints que consume

Toda la lógica de red vive en `lib/features/plants/data/datasources/plant_api_datasource.dart`.

- `GET /plants` → `{ "plants": [...] }`
- `GET /plant_species` → `{ "plant_species_profiles": [...] }`
- `GET /sensor_data/{plant_id}` → `{ "sensor_data": {...}, "averages": {...}, "readings_count": N }`
- `GET /sensor_data/{plant_id}/stream` → SSE (`text/event-stream`, líneas `data: ...`)

El datasource calcula derivados (health, mood, `lastWatered`, `SensorStatus`, `ConfidenceLevel`) a partir del perfil de especie y los promedios — no vienen del backend.

`plantsProvider` se auto-invalida cada 5 s para hacer polling REST; `plantRealtimeSensorProvider` consume el SSE.

---

## Estructura

```
lib/
├── core/config/         # AppConfig + FirebaseEnvironment (gating de --dart-define)
├── features/
│   ├── auth/            # AuthService (Google/Firebase + fallback stub)
│   └── plants/          # data / domain / presentation
└── main.dart            # ProviderScope + _AppGate (login → onboarding → main)
```

Estado: **Riverpod** (`flutter_riverpod`). Navegación: un único `Scaffold` con `IndexedStack` + overlays controlados por `navigation_provider.dart` — no se usan rutas de `Navigator`.

---

## Auth y chat sin Firebase

Si `ENABLE_FIREBASE` está apagado o falta alguna clave:

- **Auth** → `AuthService` devuelve un usuario stub local; el login funciona pero no persiste entre dispositivos.
- **Chat** → `MemoryChatRepository` guarda mensajes solo en memoria del proceso. Al cerrar la app se pierden.

Con Firebase configurado: usuarios en `users/{uid}`, mensajes en `plants/{plantId}/messages` ordenados por `timestampMs`.

---

## Convenciones

- Strings de UI en español; identificadores y comentarios mezclan ES/EN — sigue el archivo donde estés.
- No hay codegen (`build_runner`). El parsing JSON es a mano en los `_to*` del datasource.
- Lints: `flutter_lints: ^6.0.0` sin overrides.
