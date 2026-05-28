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

`src/.env` está en `.gitignore`. Los secretos se inyectan en tiempo de compilación via `--dart-define` — el `Makefile` los toma del `.env` automáticamente.

---

## Correr y buildear (desde `src/`)

```bash
make dev-web       # Chrome, backend local (localhost:8000)
make prod-web      # Chrome, backend Railway (production)
make qa-web        # Chrome, backend Railway (QA)
make dev-android   # Android emulator, backend local
make prod-android  # Android device, backend Railway (production)
make samsung       # Samsung SM S721B, backend Railway (production)
make samsung-qa    # Samsung SM S721B, backend Railway (QA)

make build-web     # build release web
make build-apk     # build APK release → build/app/outputs/flutter-apk/app-release.apk

make analyze       # flutter analyze
make test          # flutter test --coverage
make help          # lista completa de targets
```

Sin `make`, pasar los defines manualmente:

```bash
flutter run -d <DEVICE_ID> \
  --dart-define=BACKEND_TARGET=prod \
  --dart-define=SUPABASE_ANON_KEY=<value> \
  --dart-define=GOOGLE_CLIENT_ID=<value>
```

### Auth secrets (van en `src/.env`)

| Variable | Descripción |
|---|---|
| `SUPABASE_URL` | URL del proyecto Supabase (default ya configurado en `AppConfig`) |
| `SUPABASE_ANON_KEY` | Anon key publicable de Supabase — **requerida** |
| `GOOGLE_CLIENT_ID` | OAuth client ID del proyecto — **requerido** para Google Sign-In |

`src/android/app/google-services.json` debe existir en disco (gitignored) para que el picker nativo de Google Sign-In funcione en Android.

`BACKEND_TARGET` válidos: `local` | `prod` | `production` | `deploy` | `remote` (default `remote` → Railway production).

Production backend: `https://backendgossipgarden-production.up.railway.app`

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
- Google Sign-In: `AuthNotifier` llama `googleSignIn.signOut()` antes de `signIn()` para forzar el selector de cuentas; `idToken` → `POST {SUPABASE_URL}/auth/v1/token?grant_type=id_token` → JWT saved to `TokenStorage`.
- `SessionObserver` is registered in `ProviderScope(observers: [...])` in `main.dart` — any provider that throws `UnauthorizedException` triggers global signOut. Direct calls outside providers (e.g. chat) handle 401 explicitly.
- `backendTokenProvider` (plain `StateProvider<String>`) holds the active JWT and is watched by all datasource providers for reactivity.

### Plants & sensors

- `plantsProvider` — `FutureProvider`, calls `PlantApiDatasource.getPlants()`, self-invalidates every 30s via `Timer`.
- `plantRealtimeSensorProvider(plantId)` — `FutureProvider.family`, polls `GET /api/v1/plants/{id}/sensor-data/latest` every 15s via `Stream.periodic`.
- All datasource providers watch `backendTokenProvider` and rebuild when the token changes.

### Datasources

| File | Endpoints |
|---|---|
| `plant_api_datasource.dart` | `GET /api/v1/plants/`, `GET /api/v1/plants/{id}/sensor-data/latest`, `DELETE /api/v1/plants/{id}` |
| `identification_api_datasource.dart` | `POST /api/v1/identify` (multipart, `image/jpeg`), `POST /api/v1/species/from-candidate` |
| `plant_create_datasource.dart` | `POST /api/v1/plants/` |

`plant_api_datasource.dart` reads `common_name` and `scientific_name` directly from the `/plants/` response (server-side join with species). There is no separate `/species` call.

**Plant photo:** `GET /api/v1/plants/` devuelve `photo_url` (URL pública de Firebase Storage). La app usa `photo_url` directamente como `NetworkImage`; fallback a icono si es null.

### Plant identification flow

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

Single root `Scaffold` with `IndexedStack` + overlay widgets (not Navigator routes). `MainScreen` envuelve el `Scaffold` en `PopScope` — con overlay activo, el Back llama a `notifier.handleBack()`. New screens extend `NavigationState` and `MainScreen._buildOverlay`, not `Navigator.push`.

---

## Testing

```bash
flutter test                        # all tests
flutter test --coverage             # with lcov coverage
flutter test test/features/plants/  # specific feature
```

- **mocktail** (`^1.0.4`) for mocking.
- Fixtures in `test/fixtures/*.json`.
- Helpers: `test/helpers/fixture_loader.dart`, `test/helpers/fake_secure_storage.dart`.
- Coverage threshold: **40%** on business logic (excludes `screens/`, `widgets/`, `main.dart`).

---

## CI (GitHub Actions — `.github/workflows/ci.yml`)

Two parallel jobs on push/PR to `main` or `qa`:

1. **analyze** — `flutter analyze --fatal-infos`
2. **test** — `flutter test --coverage` + 40% lcov threshold

---

## Conventions

- User-facing strings in Spanish; identifiers and comments mixed Spanish/English — match the surrounding file.
- Dart SDK `>=3.0.0 <4.0.0`, lints from `flutter_lints: ^6.0.0`, no overrides.
- No codegen, no `build_runner`. JSON parsing is hand-written.
- No comments unless the WHY is non-obvious.
- Google Sign-In on **web** requires a Web OAuth 2.0 client ID (different from Android). Add `<meta name="google-signin-client_id">` in `web/index.html` with the web client ID.
