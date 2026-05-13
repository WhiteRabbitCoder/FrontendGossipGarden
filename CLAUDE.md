# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository layout

This repo contains two top-level projects, but **only `gossip_garden/` is in source control on this branch** (`frontend`):

- `gossip_garden/` — Flutter client app. This is the active codebase.
- `Backend/` — FastAPI/Python backend. On this branch the directory contains only `__pycache__/` artifacts and a `.env` (both gitignored). Real backend source lives on other branches; the deployed instance the app talks to is `https://gossip-garden-backend.up.railway.app`.
- `README_CONFIG.md` — One-time Android Studio + Flutter SDK setup notes (Spanish). Not relevant to day-to-day work.

When the user asks to change backend code on this branch, confirm before doing so — they likely want the `main`/backend branch instead.

`Backend/.env` (untracked) contains a live Railway Postgres URL and HiveMQ MQTT credentials. Do not echo, commit, or paste these anywhere outside that file.

## Common commands (run from `gossip_garden/`)

```bash
flutter pub get                      # install deps
flutter analyze                      # lint (uses analysis_options.yaml -> flutter_lints)
flutter test                         # all tests
flutter test test/widget_test.dart   # single test file
flutter test --plain-name "App renders login entry point"   # single test by name
flutter run                          # default target = remote (Railway)
```

### Backend selection at compile time

The app reads its backend URL from `--dart-define` flags consumed in `lib/core/config/app_config.dart`:

- `BACKEND_TARGET`: `local` | `prod` | `production` | `deploy` | `remote` (default `remote`)
- `BACKEND_LOCAL_URL`: defaults to `http://10.0.2.2:8000` (Android emulator → host loopback)
- `BACKEND_DEPLOY_URL`: defaults to the Railway URL above

```bash
# Android emulator → local backend
flutter run --dart-define=BACKEND_TARGET=local --dart-define=BACKEND_LOCAL_URL=http://10.0.2.2:8000

# iOS simulator → local backend
flutter run --dart-define=BACKEND_TARGET=local --dart-define=BACKEND_LOCAL_URL=http://localhost:8000

# Deployed backend
flutter run --dart-define=BACKEND_TARGET=prod
```

### Firebase

Firebase is **opt-in** at compile time. Without it, auth falls back to a stub local user and chat falls back to in-memory. To enable it, every key below must be passed via `--dart-define` (see `lib/core/config/firebase_environment.dart`):

```
ENABLE_FIREBASE=true
FIREBASE_API_KEY=...
FIREBASE_APP_ID=...
FIREBASE_MESSAGING_SENDER_ID=...
FIREBASE_PROJECT_ID=...
FIREBASE_STORAGE_BUCKET=...        # optional
FIREBASE_AUTH_DOMAIN=...           # optional
FIREBASE_MEASUREMENT_ID=...        # optional
```

`FirebaseEnvironment.isConfigured` gates every Firebase call site, so it is safe to run without these defines — the UI will route through the no-Firebase fallbacks.

## Architecture

### Layered feature structure (`lib/features/<feature>/{data,domain,presentation}`)

- `data/` — `models/` (DTOs + enums), `datasources/` (HTTP/SSE clients, mocks), `repositories/` (impls).
- `domain/` — repository interfaces and `usecases/`.
- `presentation/` — `screens/`, `widgets/`, `providers/` (Riverpod), `extensions/`.

Two features today: `plants/` (the bulk of the app) and `auth/`. There is also a `lib/widgets/material.dart` orphan widget — the canonical `PlantCard` lives under `features/plants/presentation/widgets/`.

### State management

Riverpod (`flutter_riverpod`). Wired in `main.dart` via `ProviderScope`. Notable providers:

- `lib/features/plants/presentation/providers/plant_providers.dart` — `plantsProvider` is a `FutureProvider` that **self-invalidates every 5 seconds** to poll the REST backend; `plantRealtimeSensorProvider` is a `StreamProvider.family<int>` that consumes the SSE stream.
- `chat_providers.dart` — picks `FirestoreChatRepository` when Firebase is configured, otherwise `MemoryChatRepository`. Both implement `ChatRepository`.
- `auth_provider.dart` — `AuthNotifier` exposes an `AsyncValue<AuthSession>`; `_AppGate` in `main.dart` routes login → onboarding → main based on it.
- `navigation_provider.dart` — single source of truth for tab state and overlay routing. The app uses **one root `Scaffold` with an `IndexedStack` and overlay widgets**, not Navigator routes — adding a new screen usually means extending `NavigationState` and `MainScreen._buildOverlay`, not pushing a route.

### Backend contract

`PlantApiDatasource` (`lib/features/plants/data/datasources/plant_api_datasource.dart`) is the only thing that knows the API shape. It calls:

- `GET /plants` → `{ "plants": [...] }`
- `GET /plant_species` → `{ "plant_species_profiles": [...] }` (also accepts the singular `plant_species_profile`)
- `GET /sensor_data/{plant_id}` → `{ "sensor_data": {...latest}, "averages": {...}, "readings_count": N }`
- `GET /sensor_data/{plant_id}/stream` → SSE (`text/event-stream`, lines prefixed `data: `)

The datasource is responsible for **all derived state** the UI consumes: it computes `health` (per-metric distance to comfort range, averaged), `mood`, `lastWatered` estimate, `SensorStatus` (online/degraded/offline based on timestamp age: ≤20 min / ≤3 h / older), and `ConfidenceLevel`. Comfort zones come from the species profile fields (`min_humidity`, `max_humidity`, `min_temperature`, …). When changing the backend response shape, update this file's `_to*` helpers and the species/sensor extractors together — there is no codegen.

### Auth + chat persistence

`AuthService` (`lib/features/auth/data/auth_service.dart`) is constructed with **nullable** `FirebaseAuth`/`GoogleSignIn`/`FirebaseFirestore`; the no-arg constructor is what `authServiceProvider` returns when Firebase isn't configured. Sign-in writes a user doc to `users/{uid}`; chat messages live at `plants/{plantId}/messages` ordered by `timestampMs`.

## Conventions worth knowing

- User-facing strings are in Spanish; comments and identifiers are mixed Spanish/English. Match the surrounding file rather than normalizing.
- The Dart SDK constraint is `>=3.0.0 <4.0.0`; lints come from `flutter_lints: ^6.0.0` with no project-specific overrides.
- There's no codegen (no `build_runner`, no generated files). JSON parsing is hand-written; enums use a shared `_enumFromString` helper in `core/utils/enum_utils.dart`.