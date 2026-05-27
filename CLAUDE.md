# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository layout

```
frontendGossipGarden/
├── src/                  ← Flutter app (active codebase, run all flutter commands from here)
│   ├── lib/
│   ├── web/
│   ├── pubspec.yaml
│   └── .env              ← secrets (gitignored) — see .env.example
└── CLAUDE.md
```

The Flutter app lives in `src/`. All `flutter` commands must be run from there.

---

## Common commands (run from `src/`)

```bash
flutter pub get
flutter analyze
flutter test

# Samsung device via USB (backend Railway)
flutter run -d <DEVICE_ID> \
  --dart-define=BACKEND_TARGET=prod \
  --dart-define=SUPABASE_ANON_KEY=<value> \
  --dart-define=GOOGLE_CLIENT_ID=<value>

# Chrome (web)
flutter run -d chrome \
  --dart-define=BACKEND_TARGET=prod \
  --dart-define=SUPABASE_ANON_KEY=<value> \
  --dart-define=GOOGLE_CLIENT_ID=<value>

# Local backend (Android device)
flutter run -d <DEVICE_ID> \
  --dart-define=BACKEND_TARGET=local \
  --dart-define=BACKEND_LOCAL_URL=http://10.0.2.2:8000 \
  --dart-define=SUPABASE_ANON_KEY=<value> \
  --dart-define=GOOGLE_CLIENT_ID=<value>
```

Secrets are in `src/.env` (gitignored). The defines `SUPABASE_ANON_KEY` and `GOOGLE_CLIENT_ID` must always be passed — they have no safe default.

### Backend targets

`BACKEND_TARGET` in `lib/core/config/app_config.dart`:

| Value | URL used |
|---|---|
| `prod` / `production` / `deploy` / `remote` (default) | `https://backendgossipgarden-production.up.railway.app` |
| `local` | `BACKEND_LOCAL_URL` (default `http://10.0.2.2:8000`) |

---

## Architecture

### Feature structure (`lib/features/<feature>/{data,presentation}`)

- `data/models/` — DTOs and enums
- `data/datasources/` — HTTP clients (no repositories layer in active code)
- `presentation/screens/` — full screens
- `presentation/widgets/` — reusable widgets
- `presentation/providers/` — Riverpod providers

Active features: `plants/`, `auth/`.

### Core layer (`lib/core/`)

| File | Purpose |
|---|---|
| `config/app_config.dart` | Compile-time config via `String.fromEnvironment` |
| `exceptions.dart` | `UnauthorizedException` — thrown by datasources on 401, caught by `SessionObserver` |
| `services/token_storage.dart` | JWT persistence via `flutter_secure_storage` (key `gg_jwt`) |
| `services/backend_auth_service.dart` | Email/password login+register + Google idToken → Supabase exchange |
| `services/backend_chat_service.dart` | Chat send + history fetch against `/api/v1/chat/` |
| `observers/session_observer.dart` | `ProviderObserver` — detects `UnauthorizedException` in any provider → auto-signOut |

### Auth

- **No Firebase Auth**. Auth is Supabase-only.
- `AuthNotifier` (`features/auth/presentation/providers/auth_provider.dart`) manages `AsyncValue<AuthSession>`.
- On startup, `_bootstrap()` restores the JWT from `TokenStorage` and sets session state.
- Google Sign-In: `GoogleSignIn.signIn()` → `idToken` → `POST {SUPABASE_URL}/auth/v1/token?grant_type=id_token` → JWT saved to `TokenStorage`.
- `SessionObserver` is registered in `ProviderScope(observers: [...])` in `main.dart` — any provider that throws `UnauthorizedException` triggers global signOut.
- `backendTokenProvider` (plain `StateProvider<String>`) holds the active JWT and is watched by all datasource providers for reactivity.

### Plants & sensors

- `plantsProvider` — `FutureProvider`, calls `PlantApiDatasource.getPlants()`, self-invalidates every 30s via `Timer`.
- `plantRealtimeSensorProvider(plantId)` — `FutureProvider.family`, polls `GET /api/v1/plants/{id}/sensor-data/latest` every 15s via `Stream.periodic`.
- All datasource providers watch `backendTokenProvider` and rebuild when the token changes.

### Datasources

| File | Endpoints |
|---|---|
| `plant_api_datasource.dart` | `GET /api/v1/plants/`, `GET /api/v1/plants/{id}/sensor-data/latest`, `DELETE /api/v1/plants/{id}` |
| `identification_api_datasource.dart` | `POST /api/v1/identify` (multipart), `POST /api/v1/species/from-candidate` |
| `plant_create_datasource.dart` | `POST /api/v1/plants/` |

`plant_api_datasource.dart` reads `common_name` and `scientific_name` directly from the `/plants/` response (server-side join with species). There is no separate `/species` call.

### Identification pipeline

`plant_identify_screen.dart` implements the full flow:

1. **selectMethod** — camera or search (search is catalog placeholder, no backend endpoint)
2. **idle** — live `CameraController` preview (back camera, `ResolutionPreset.high`)
3. **uploading** — `_processImage()`: `bakeOrientation` + center-crop + resize to 1024×1024 JPEG (q=92) → `POST /api/v1/identify`
4. **selectCandidate** — `PageView` carousel if backend returns `needs_user_selection`; each card shows photo URL + probability badge → `POST /api/v1/species/from-candidate`
5. **confirm** — real data from `CareProfile` (common name, family, care tips, fun facts); nickname input pre-filled
6. **creating** — `POST /api/v1/plants/` → `ref.invalidate(plantsProvider)` → `onCompleted?.call()`

`IdentifyResult` sealed class (`data/models/identification.dart`) discriminates `NeedsMorePhotos | NeedsUserSelection | IdentifyCompleted`.

### Chat

- `chatMessagesProvider(plantId)` — `StateNotifierProvider`, starts empty, filled via `loadHistory()` or `addMessage()`.
- No Firestore, no mock data. History loaded from `GET /api/v1/chat/{plantId}/history` on screen open.
- Messages sent to `POST /api/v1/chat/{plantId}` with `language: 'es'` and `response_format: 'text'`.

### Navigation

Single root `Scaffold` with `IndexedStack` + overlay widgets (not Navigator routes). New screens extend `NavigationState` and `MainScreen._buildOverlay`, not `Navigator.push`.

---

## Conventions

- User-facing strings in Spanish; identifiers and comments mixed Spanish/English — match the surrounding file.
- Dart SDK `>=3.0.0 <4.0.0`, lints from `flutter_lints: ^6.0.0`, no overrides.
- No codegen, no `build_runner`. JSON parsing is hand-written.
- No comments unless the WHY is non-obvious.
- Google Sign-In on **web** requires a Web OAuth 2.0 client ID (different from Android). Add `<meta name="google-signin-client_id">` in `web/index.html` with the web client ID. The current ID in `.env` is the Android client ID.
