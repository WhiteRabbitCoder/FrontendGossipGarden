# CLAUDE.md — frontendGossipGarden (Flutter)

Flutter mobile app for GossipGarden. Source lives in `src/`. The app talks exclusively to the backend at `backendGossipGarden/` — see `backendGossipGarden/API_CONTRACT.md` for the canonical contract.

## Setup (once, from `src/`)

```bash
cp .env.example .env   # rellenar SUPABASE_ANON_KEY y GOOGLE_CLIENT_ID
flutter pub get
```

`src/.env` está en `.gitignore`. Ver `src/.env.example` para la estructura. Los secretos se inyectan en tiempo de compilación via `--dart-define` — el `Makefile` los toma del `.env` automáticamente.

## Correr y buildear (desde `src/`)

```bash
make dev-web       # Chrome, backend local (localhost:8000)
make prod-web      # Chrome, backend Railway (production)
make qa-web        # Chrome, backend Railway (QA)
make dev-android   # Android emulator, backend local
make prod-android  # Android device, backend Railway (production)
make samsung       # Samsung SM S721B, backend Railway (production)
make samsung-qa    # Samsung SM S721B, backend Railway (QA) ← para probar QA

make build-web     # build release web
make build-apk     # build APK release → build/app/outputs/flutter-apk/app-release.apk

make analyze       # flutter analyze
make test          # flutter test --coverage
make help          # lista completa de targets
```

`BACKEND_TARGET` es consumido por `lib/core/config/app_config.dart`. Valores válidos: `local` | `prod` | `production` | `deploy` | `remote` (default `remote` → igual que `prod`).

### Auth secrets (van en `src/.env`)

| Variable | Descripción |
|---|---|
| `SUPABASE_URL` | URL del proyecto Supabase (default ya configurado en `AppConfig`) |
| `SUPABASE_ANON_KEY` | Anon key publicable de Supabase — **requerida** |
| `GOOGLE_CLIENT_ID` | OAuth client ID (web/server) del proyecto Firebase — **requerido** para Google Sign-In |

Además, `src/android/app/google-services.json` debe existir en disco (gitignored) para que el picker nativo de Google Sign-In funcione en Android. Ver `google-services.json.example` para la estructura esperada.

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

**Session expiry (401):** `SessionObserver` (`core/observers/session_observer.dart`) es un `ProviderObserver` registrado en `ProviderScope` que detecta `UnauthorizedException` en cualquier `AsyncError` y llama a `signOut()` automáticamente. Las llamadas directas fuera de providers (e.g. chat) manejan 401 explícitamente.

**Back button:** `MainScreen` envuelve el `Scaffold` en `PopScope`. Con overlay activo (chat/perfil), el Back llama a `notifier.handleBack()` en lugar de salir de la app.

**Google Sign-In:** `AuthNotifier` llama `googleSignIn.signOut()` antes de `signIn()` para forzar el selector de cuentas nativo en cada inicio de sesión. `GoogleSignIn` es inyectable vía constructor para facilitar tests.

### Backend contract (active)

All calls go to `/api/v1/*` with `Authorization: Bearer <supabase_jwt>`.

| Datasource | Endpoints used |
|---|---|
| `plant_api_datasource.dart` | `GET /api/v1/plants/`, `GET /api/v1/plants/{id}/sensor-data/latest`, `DELETE /api/v1/plants/{id}` |
| `identification_api_datasource.dart` | `POST /api/v1/identify` (multipart, `image/jpeg`), `POST /api/v1/species/from-candidate` |
| `plant_create_datasource.dart` | `POST /api/v1/plants/` |
| `backend_auth_service.dart` | `POST /api/v1/auth/login`, `POST /api/v1/auth/register`; also `POST supabase.co/auth/v1/token` (Google) |
| `backend_chat_service.dart` | `POST /api/v1/chat/{plant_id}`, `GET /api/v1/chat/{plant_id}/history` |
| `sensor_stream_datasource.dart` | `GET /api/v1/plants/{id}/sensor-data/latest` (polling) |

**Important:** `GET /api/v1/species` does NOT exist in the backend — do not call it. Comfort zone defaults are hardcoded in `plant_api_datasource.dart` until `GET /api/v1/species/{id}/profile` is implemented.

**Plant photo:** `GET /api/v1/plants/` devuelve `photo_url` (URL pública de Firebase Storage) además de `photo_storage_path`. La app usa `photo_url` directamente como `NetworkImage`; fallback a `assets/images/app_logo.png` si es null. El campo `image` en el modelo `Plant` se popula con `photo_url`.

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

The project has **144 automated tests** across 12 test files. Run from `src/`:

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
