<div align="center">
  <img src="docs/icon.png" width="140" alt="Gossip Garden logo"/>
  <h1>Gossip Garden</h1>
  <p><em>Your plants have something to say.</em></p>

  ![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)
  ![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)
  ![Supabase](https://img.shields.io/badge/Supabase-Auth%20%26%20DB-3ECF8E?logo=supabase&logoColor=white)
  ![FastAPI](https://img.shields.io/badge/FastAPI-Backend-009688?logo=fastapi&logoColor=white)
  ![Railway](https://img.shields.io/badge/Deployed%20on-Railway-0B0D0E?logo=railway&logoColor=white)
</div>

---

Gossip Garden is a Flutter mobile app that lets you identify, track, and connect with your plants using AI. Point the camera at any plant, get a full care profile in seconds, and monitor its sensor data in real time.

---

## Features

- **AI Plant Identification** — Snap a photo and get an instant species match with care tips, personality, and scientific context, powered by a plant.id → GBIF → OpenAI pipeline.
- **Real-time Sensor Dashboard** — Live temperature, humidity, and light readings from IoT sensors paired to each plant.
- **Plant Chat** — Talk to your plant. Each species has its own AI personality prompt driving an LLM-powered conversation.
- **Google Sign-In & Email Auth** — Native Android account picker backed by Supabase JWT — no password reuse, no browser redirect.
- **Persistent Sessions** — JWT stored securely with `flutter_secure_storage`; sessions survive app restarts.
- **Onboarding Flow** — First-launch walkthrough that guides new users through identifying their first plant before reaching the main dashboard.

---

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                  Flutter App (Android)               │
│                                                     │
│  ┌──────────┐  ┌──────────────┐  ┌───────────────┐ │
│  │   Auth   │  │    Plants    │  │     Chat      │ │
│  │ Supabase │  │  /api/v1/*   │  │  /api/v1/chat │ │
│  └────┬─────┘  └──────┬───────┘  └───────┬───────┘ │
└───────┼───────────────┼──────────────────┼─────────┘
        │               │                  │
        ▼               ▼                  ▼
┌───────────────────────────────────────────────────┐
│          FastAPI Backend  (Railway)                │
│                                                   │
│  /api/v1/auth      /api/v1/plants                 │
│  /api/v1/identify  /api/v1/species                │
│  /api/v1/sensors   /api/v1/chat/{plant_id}        │
│                                                   │
│  ┌──────────┐ ┌──────────┐ ┌─────────┐ ┌───────┐ │
│  │ Supabase │ │ Firebase │ │  Redis  │ │Ollama │ │
│  │ Postgres │ │ Storage  │ │  Cache  │ │  LLM  │ │
│  └──────────┘ └──────────┘ └─────────┘ └───────┘ │
└───────────────────────────────────────────────────┘
```

### Tech Stack

| Layer | Technology |
|---|---|
| Mobile | Flutter 3, Riverpod, Dart 3 |
| Auth | Supabase (JWT ES256) + `google_sign_in` native Android picker |
| Backend | FastAPI (Python 3.11), deployed on Railway |
| Database | Supabase (PostgreSQL + pgvector for RAG) |
| AI Identification | plant.id → GBIF → RAG → OpenAI gpt-4o Structured Output |
| Plant Photos | Firebase Storage (uploaded by backend via `firebase-admin`) |
| IoT Telemetry | Firebase Firestore (30-day TTL per reading) |
| Chat History | Redis (2h TTL per plant per user) |
| LLM Chat | Ollama (`gemma4`) with per-species personality prompt |

---

## App Flow

### Authentication

```
Email / Password                    Google Sign-In
      │                                   │
      ▼                                   ▼
POST /api/v1/auth/login        google_sign_in (native)
      │                          Android account picker
      │                                   │
      │                           idToken from Google
      │                                   │
      │                     POST supabase.co/auth/v1/token
      │                         grant_type=id_token
      │                                   │
      └──────────────┬────────────────────┘
                     ▼
             Supabase JWT saved
           (flutter_secure_storage)
                     │
                     ▼
            All /api/v1/* calls
          Authorization: Bearer <jwt>
```

> Firebase is **not used as an auth intermediary**. Supabase handles all identity. The Firebase SDK is disabled by default in the Flutter app — Firebase Storage and Firestore are managed server-side by the backend (`firebase-admin`).

---

### Plant Identification

```
  📷 Camera capture
        │
        ▼
  POST /api/v1/identify
  (multipart image/jpeg + optional GPS)
        │
        ▼
   plant.id API ──► confidence score
        │
   ┌────┴──────────────────────┬──────────────────────────────┐
   │                           │                              │
< 25%                      25% – 75%                        > 75%
   │                           │                              │
Needs more photos       Top-3 candidates               Full pipeline:
   │                      (cards UI)                  GBIF → RAG →
Dialog + retry               │                        OpenAI gpt-4o
                        User selects one                    │
                             │                              │
                  POST /api/v1/species/from-candidate       │
                             │                              │
                             └──────────────┬───────────────┘
                                            ▼
                                   Care profile returned
                                   (species · family · care
                                   summary · comfort ranges
                                   · personality · FAQs)
                                            │
                                            ▼
                                   User sets a nickname
                                            │
                                            ▼
                                   POST /api/v1/plants/
                                            │
                                            ▼
                                   Photo → Firebase Storage
                                   (background task, zero latency)
```

---

### Sensor Monitoring

Each plant can be paired with an IoT sensor over MQTT. The app polls `GET /api/v1/plants/{id}/sensor-data/latest` every 15 seconds and displays live readings:

| Metric | Icon |
|---|---|
| Temperature | 🌡️ °C |
| Soil humidity | 💧 % |
| Air humidity | 🌫️ % |
| Light | ☀️ lux |

Health status (`healthy` / `warning` / `critical`) is computed by the backend by comparing readings against the species' care profile comfort ranges, with per-sensor weights and sensitivity levels.

---

## Project Structure

```
frontendGossipGarden/
├── src/
│   ├── lib/
│   │   ├── core/
│   │   │   ├── config/         # AppConfig, FirebaseEnvironment
│   │   │   ├── services/       # TokenStorage, BackendAuthService, BackendChatService
│   │   │   └── theme/          # GardenColors, GardenTextStyles
│   │   ├── features/
│   │   │   ├── auth/
│   │   │   │   ├── data/           # AuthService (Firebase optional wrapper)
│   │   │   │   └── presentation/
│   │   │   │       ├── providers/  # AuthNotifier, backendTokenProvider
│   │   │   │       └── screens/    # LoginScreen, RegisterScreen
│   │   │   └── plants/
│   │   │       ├── data/
│   │   │       │   ├── datasources/  # PlantApiDatasource
│   │   │       │   │                 # IdentificationApiDatasource
│   │   │       │   │                 # PlantCreateDatasource
│   │   │       │   └── models/       # Plant, IdentifyResult, CareProfile …
│   │   │       └── presentation/
│   │   │           ├── providers/    # plantsProvider, plantRealtimeSensorProvider …
│   │   │           └── screens/      # PlantProfileScreen, PlantIdentifyScreen,
│   │   │                             # PlantChatScreen, OnboardingScreen
│   │   └── main.dart
│   ├── android/
│   │   └── app/src/main/
│   │       ├── AndroidManifest.xml   # CAMERA permission, deep link gossipgarden://
│   │       └── google-services.json  # Firebase project gossipgarden-e2879
│   └── pubspec.yaml
├── CLAUDE.md           # Developer guide — architecture, auth decisions, build commands
├── PENDING_BACKEND.md  # Endpoints planned but not yet implemented in the backend
└── API_CONTRACT.md     # API spec reference (canonical: backendGossipGarden/API_CONTRACT.md)
```

---

## Getting Started

### Prerequisites

- Flutter 3.x SDK (`flutter --version`)
- ADB for physical device installs
- Backend running locally **or** use the production Railway deployment

### Run

```bash
cd src
flutter pub get

# Against production backend (Railway)
flutter run --dart-define=BACKEND_TARGET=prod

# Against local backend (Android emulator → host loopback)
flutter run \
  --dart-define=BACKEND_TARGET=local \
  --dart-define=BACKEND_LOCAL_URL=http://10.0.2.2:8000
```

### Build a release APK

```bash
cd src
flutter build apk --release --dart-define=BACKEND_TARGET=prod
adb install build/app/outputs/flutter-apk/app-release.apk
```

### `--dart-define` reference

| Variable | Values | Default |
|---|---|---|
| `BACKEND_TARGET` | `local` \| `prod` | `prod` |
| `BACKEND_LOCAL_URL` | any URL | `http://10.0.2.2:8000` |
| `ENABLE_FIREBASE` | `true` \| `false` | `false` |

---

## Backend

Business logic lives in a separate repository. All endpoints are under `/api/v1/*` and require a Supabase Bearer JWT.

**Production:** `https://backendgossipgarden-production.up.railway.app`  
**Docs:** `https://backendgossipgarden-production.up.railway.app/docs`

See [`PENDING_BACKEND.md`](PENDING_BACKEND.md) for planned but unimplemented endpoints.

---

<div align="center">
  <sub>Made with 🌱 and a lot of care</sub>
</div>
