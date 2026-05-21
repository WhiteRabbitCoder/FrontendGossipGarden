# CLAUDE.md — frontendGossipGarden (Flutter)

Flutter mobile app for GossipGarden. Source lives in `src/`. The app talks exclusively to the backend at `backendGossipGarden/` — see `backendGossipGarden/API_CONTRACT.md` for the canonical contract.

## Common commands (run from `src/`)

```bash
flutter pub get
flutter analyze
flutter test
```

### Build & run

```bash
# Production backend (Railway) — must pass auth secrets via --dart-define
flutter run \
  --dart-define=BACKEND_TARGET=prod \
  --dart-define=SUPABASE_URL=https://tslrtebdziilekddalcr.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<your-anon-key> \
  --dart-define=GOOGLE_CLIENT_ID=<your-google-client-id>

# Local backend (Android emulator → host loopback)
flutter run \
  --dart-define=BACKEND_TARGET=local \
  --dart-define=BACKEND_LOCAL_URL=http://10.0.2.2:8000 \
  --dart-define=SUPABASE_URL=https://tslrtebdziilekddalcr.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<your-anon-key> \
  --dart-define=GOOGLE_CLIENT_ID=<your-google-client-id>

# Release APK for device
flutter build apk --release \
  --dart-define=BACKEND_TARGET=prod \
  --dart-define=SUPABASE_URL=https://tslrtebdziilekddalcr.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<your-anon-key> \
  --dart-define=GOOGLE_CLIENT_ID=<your-google-client-id>
adb install build/app/outputs/flutter-apk/app-release.apk
```

`BACKEND_TARGET` is consumed by `lib/core/config/app_config.dart`. Valid values: `local` | `prod` | `production` | `deploy` | `remote` (default `remote` → same as `prod`).

### Auth secrets (required for Google Sign-In)

| Flag | Description |
|---|---|
| `SUPABASE_URL` | Supabase project URL (e.g. `https://xxx.supabase.co`) |
| `SUPABASE_ANON_KEY` | Supabase publishable anon key |
| `GOOGLE_CLIENT_ID` | Web/server OAuth client ID from Firebase project |

These are injected at build time via `--dart-define` and read by `AppConfig` in `lib/core/config/app_config.dart`. They default to empty strings — Google Sign-In will fail if not provided.

Production backend URL: `https://backendgossipgarden-production.up.railway.app`

---

## Auth architecture — Supabase only, no Firebase as intermediary

**Rule:** Firebase is NOT an auth intermediary. All auth goes through Supabase directly from Flutter.

| Method | Flow |
|---|---|
| Email/password | `POST /api/v1/auth/login` → Supabase JWT |
| Google Sign-In | Native Android account selector (`google_sign_in`) → `idToken` → `POST supabase.co/auth/v1/token?grant_type=id_token` → Supabase JWT |
| Register | `POST /api/v1/auth/register` → auto-login to get JWT |

The Supabase JWT is saved in `flutter_secure_storage` (key: `gg_jwt`) via `lib/core/services/token_storage.dart` and restored on app restart. It is read from `backendTokenProvider` (Riverpod `StateProvider<String?>`) across the app.

**Google Sign-In details:**
- Uses `google_sign_in` package with `serverClientId` from `AppConfig.googleClientId` (injected via `--dart-define=GOOGLE_CLIENT_ID`).
- The `idToken` is exchanged directly with Supabase (not through the backend): `POST {SUPABASE_URL}/auth/v1/token?grant_type=id_token` with `apikey: {SUPABASE_ANON_KEY}`.
- `google-services.json` is required by `google_sign_in` on Android for the native account picker — it is gitignored and must be obtained from Firebase console. See `android/app/google-services.json.example` for the expected structure.
- Android debug keystore SHA-1: `AD:DC:9D:0E:83:23:8C:07:DC:1C:AB:34:27:38:27:AA:72:1F:92:09`

**Firebase SDK in Flutter:** disabled by default (`ENABLE_FIREBASE=false`). The backend handles Firebase Storage and Firestore server-side via `firebase-admin` (Python). The Flutter app does not need the Firebase SDK for photos or chat.

### Firebase opt-in (not needed for current production build)

To enable Firebase from Flutter (e.g. for direct Firestore access), pass via `--dart-define`:

```
ENABLE_FIREBASE=true
FIREBASE_API_KEY=...
FIREBASE_APP_ID=...
FIREBASE_MESSAGING_SENDER_ID=...
FIREBASE_PROJECT_ID=...
FIREBASE_STORAGE_BUCKET=...   # optional
FIREBASE_AUTH_DOMAIN=...      # optional
```

`FirebaseEnvironment.isConfigured` gates every Firebase call site — safe to omit.

---

## Architecture

### Layered feature structure (`lib/features/<feature>/{data,domain,presentation}`)

- `data/` — `models/` (DTOs + enums), `datasources/` (HTTP clients), `repositories/` (impls).
- `domain/` — repository interfaces and `usecases/`.
- `presentation/` — `screens/`, `widgets/`, `providers/` (Riverpod).

Two features: `plants/` (plant management, identification, LLM chat, sensor telemetry) and `auth/`.

### State management

Riverpod (`flutter_riverpod`). Wired in `main.dart` via `ProviderScope`. Notable providers in `lib/features/plants/presentation/providers/plant_providers.dart`:

- `plantsProvider` — `FutureProvider<List<Plant>>` calling `GET /api/v1/plants/` with Bearer token.
- `plantRealtimeSensorProvider` — `StreamProvider` polling `GET /api/v1/plants/{id}/sensor-data/latest` every 15s.
- `identificationApiDatasourceProvider` — token-aware datasource for `POST /api/v1/identify`.
- `plantCreateDatasourceProvider` — token-aware datasource for `POST /api/v1/plants/`.
- `chatProviders` (`chat_providers.dart`) — providers for LLM chat with plant personality.

`auth_provider.dart` — `AuthNotifier` exposes `AsyncValue<AuthSession>`; `_AppGate` in `main.dart` routes login → onboarding → main.

`navigation_provider.dart` — single source of truth for tab state. The app uses **one root `Scaffold` with `IndexedStack` and overlay widgets**, not Navigator routes.

### Backend contract (active)

All calls go to `/api/v1/*` with `Authorization: Bearer <supabase_jwt>`.

| Datasource | Endpoints used |
|---|---|
| `plant_api_datasource.dart` | `GET /api/v1/plants/`, `GET /api/v1/plants/{id}/sensor-data/latest` |
| `identification_api_datasource.dart` | `POST /api/v1/identify` (multipart, `image/jpeg`), `POST /api/v1/species/from-candidate` |
| `plant_create_datasource.dart` | `POST /api/v1/plants/` |
| `backend_auth_service.dart` | `POST /api/v1/auth/login`, `POST /api/v1/auth/register`; also `POST supabase.co/auth/v1/token` (Google) |
| `backend_chat_service.dart` | `POST /api/v1/chat/{plant_id}`, `GET /api/v1/chat/{plant_id}/history` |
| `sensor_stream_datasource.dart` | `GET /api/v1/plants/{id}/sensor-data/latest` (polling) |

**Important:** `GET /api/v1/species` does NOT exist in the backend — do not call it. Comfort zone defaults are hardcoded in `plant_api_datasource.dart` until `GET /api/v1/species/{id}/profile` is implemented.

### Plant identification flow

`PlantIdentifyScreen` → camera capture → `POST /api/v1/identify` (multipart `image/jpeg`) → state machine:
- `needs_more_photos` → dialog + retry
- `needs_user_selection` → candidate list → tap → `POST /api/v1/species/from-candidate`
- `completed` → confirm screen → `POST /api/v1/plants/` → navigate to plant profile

**Multipart note:** `MultipartFile.fromPath` on Android defaults to `application/octet-stream`. Always pass `contentType: MediaType('image', 'jpeg')` explicitly (requires `http_parser: ^4.0.2` in `pubspec.yaml`).

### New screens and widgets

**Screens:**
- `chat_list_screen.dart` — list of all plant conversations.
- `plant_chat_screen.dart` — LLM chat interface with individual plant personality.

**Widgets:**
- `telemetry_panel.dart` — real-time sensor data display.
- `summary_banner.dart` — plant health summary.
- `hero_stats_card.dart` — headline statistics card.
- `voice_note_bubble.dart` — voice message UI component.

### Pending backend endpoints

See `frontendGossipGarden/PENDING_BACKEND.md` for the full list. Key gaps:
- `GET /api/v1/species/{id}/profile` — comfort zones (using defaults now)
- JWT refresh — on expiry, user is forced to re-login
- CRUD friendships

---

## Testing

The project has **141+ automated tests** across 12 test files. Run from `src/`:

```bash
flutter test                        # all tests
flutter test --coverage             # with lcov coverage
flutter test test/features/plants/  # specific feature
```

### Stack
- **mocktail** (`^1.0.4`) for mocking HTTP clients and services.
- Fixtures in `test/fixtures/*.json` (API response snapshots).
- Helpers: `test/helpers/fixture_loader.dart`, `test/helpers/fake_secure_storage.dart`.

### Coverage
Business logic coverage threshold: **40%** (enforced in CI). Excludes `screens/`, `widgets/`, and `main.dart` — those are covered by widget/integration tests.

### Test structure
```
test/
├── core/services/              # backend_auth_service, token_storage
├── features/
│   ├── auth/data/              # user_profile model
│   ├── auth/presentation/      # auth_provider
│   └── plants/
│       ├── data/datasources/   # plant_api, plant_create, identification_api
│       ├── data/models/        # plant, sensors, comfort_zones, identification
│       └── presentation/providers/  # navigation_provider
├── fixtures/                   # JSON response fixtures
└── helpers/                    # fixture_loader, fake_secure_storage
```

---

## CI (GitHub Actions — `.github/workflows/ci.yml`)

Two parallel jobs triggered on push/PR to `main` or `qa`:

1. **analyze** — `flutter analyze --fatal-infos` (zero warnings/infos allowed).
2. **test** — `flutter test --coverage` + lcov threshold check (40% on business logic).

Coverage report artifact uploaded for each run.

---

## Conventions

- User-facing strings are in Spanish; comments and identifiers are mixed Spanish/English. Match the surrounding file.
- Dart SDK: `>=3.0.0 <4.0.0`. Lints: `flutter_lints: ^6.0.0`.
- No codegen (`build_runner`, generated files). JSON parsing is hand-written.
- `Backend/.env` (untracked) contains live credentials. Do not echo, commit, or paste outside that file.
