# AGENT_SKILLS.md — FrontendGossipGarden (Flutter)

> Archivo de contexto unificado para agentes de IA (Claude Code, GitHub Copilot, Cursor).
> Skills específicas del app móvil Flutter + contexto del sistema completo.

---

## 1. SISTEMA — VISIÓN GENERAL

**Gossip Garden** es una plataforma IoT de monitoreo de plantas con IA. Este repo es el **cliente móvil Flutter** (Android + iOS) que consume la API del backend.

```
[Flutter App]  ──JWT Bearer──►  [FastAPI Backend - Railway]
                                        │
                               Supabase · Firebase · Redis
                               OpenAI · Plant.id · GBIF
                               ESP32 sensores (MQTT)
```

**Backend URL producción**: `https://backendgossipgarden-production.up.railway.app`  
**Contrato de API canónico**: `API_CONTRACT.md` en este repo (o en `BackendGossipGarden/API_CONTRACT.md`).

---

## 2. STACK

| Tecnología | Versión | Rol |
|---|---|---|
| Flutter | latest stable | Framework UI cross-platform |
| Dart SDK | >=3.0.0 <4.0.0 | Lenguaje |
| flutter_riverpod | ^2.0.0 | State management |
| http | ^1.2.2 | Llamadas REST |
| http_parser | ^4.0.2 | ContentType explícito en multipart |
| google_sign_in | ^6.2.1 | Account picker nativo Android |
| flutter_secure_storage | ^9.2.2 | Persistencia JWT |
| camera / image_picker | — | Captura de fotos |
| google_fonts / flutter_svg | — | UI |
| mocktail | ^1.0.4 | Mocking en tests |

---

## 3. ARQUITECTURA

### Clean Architecture por feature

```
src/lib/
├── main.dart                        — ProviderScope, _AppGate (routing)
├── core/
│   ├── config/app_config.dart       — BACKEND_TARGET → base URL
│   ├── services/
│   │   ├── backend_auth_service.dart  — login, register, Google OAuth
│   │   ├── backend_chat_service.dart  — chat send/history
│   │   └── token_storage.dart         — flutter_secure_storage (key: gg_jwt)
│   └── theme/
│       ├── garden_colors.dart         — paleta de colores
│       ├── garden_text_styles.dart    — tipografía
│       └── app_design_system.dart     — botones, sombras, modales
└── features/
    ├── auth/
    │   ├── data/                      — auth_service, user_profile
    │   └── presentation/
    │       ├── providers/auth_provider.dart   — AuthNotifier
    │       └── screens/login_screen, register_screen
    └── plants/
        ├── data/
        │   ├── datasources/           — un archivo por endpoint del backend
        │   ├── models/                — DTOs con fromJson/toJson (sin codegen)
        │   └── repositories/          — impls concretas
        ├── domain/
        │   ├── repositories/          — interfaces abstractas
        │   └── usecases/
        └── presentation/
            ├── providers/             — plant_providers, chat_providers, navigation_provider
            ├── screens/               — todas las pantallas
            └── widgets/               — componentes reutilizables
```

### Navegación: un root Scaffold con IndexedStack

```dart
// MainScreen — NO usar Navigator para tabs, solo IndexedStack
Scaffold(
  body: IndexedStack(
    index: ref.watch(navigationProvider),  // StateProvider<int>
    children: [
      KeepAliveWrapper(child: PlantsScreen()),
      KeepAliveWrapper(child: GardenViewScreen()),
      KeepAliveWrapper(child: DashboardScreen()),
      KeepAliveWrapper(child: ChatListScreen()),
    ],
  ),
  bottomNavigationBar: AnimatedBottomNav(),
)
// Las pantallas de detalle (PlantProfile, Chat, Identify) → Navigator.push
```

### Routing de auth (`_AppGate` en main.dart)
```dart
authProvider loading         → SplashScreen
authProvider null            → LoginScreen
authProvider session + first → OnboardingScreen
authProvider session         → MainScreen
```

---

## 4. SKILL: Autenticación

### Flujo Email/Password
```dart
// BackendAuthService
final response = await http.post(
  Uri.parse('${AppConfig.baseUrl}/api/v1/auth/login'),
  body: jsonEncode({'email': email, 'password': password}),
  headers: {'Content-Type': 'application/json'},
);
final token = jsonDecode(response.body)['access_token'];
await TokenStorage.save(token);          // flutter_secure_storage key: 'gg_jwt'
ref.read(backendTokenProvider.notifier).state = token;
```

### Flujo Google Sign-In
```dart
// ⚠️ Google Sign-In va DIRECTO a Supabase — NO pasa por el backend
final googleUser = await GoogleSignIn(
  serverClientId: '845769881632-43t9sgnt5d25qddc2ur23at78m909c6t.apps.googleusercontent.com',
).signIn();
final idToken = (await googleUser!.authentication).idToken!;

// Intercambiar idToken con Supabase directamente
final response = await http.post(
  Uri.parse('https://tslrtebdziilekddalcr.supabase.co/auth/v1/token?grant_type=id_token'),
  headers: {'apikey': 'sb_publishable_GlaX3ksF4ct_akaW5q4bWA_QItqdrqg',
            'Content-Type': 'application/json'},
  body: jsonEncode({'id_token': idToken, 'provider': 'google'}),
);
```

**Regla crítica**: `google-services.json` es solo para el account picker nativo. **Firebase NO es intermediario de auth.**

### Restauración de sesión (app restart)
```dart
// En AuthNotifier.build()
final token = await TokenStorage.read();  // key: 'gg_jwt'
if (token != null) state = AsyncData(AuthSession(token: token));
```

---

## 5. SKILL: Patrón Datasource

```dart
class PlantApiDatasource {
  final http.Client _client;
  final String _baseUrl;
  final String _token;

  PlantApiDatasource({required http.Client client,
                      required String baseUrl,
                      required String token})
      : _client = client, _baseUrl = baseUrl, _token = token;

  Future<List<PlantModel>> getPlants() async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/api/v1/plants/'),
      headers: {'Authorization': 'Bearer $_token'},
    );
    if (response.statusCode != 200) throw Exception('Error ${response.statusCode}');
    return (jsonDecode(response.body) as List)
        .map((j) => PlantModel.fromJson(j))
        .toList();
  }
}

// Proveedor
final plantApiDatasourceProvider = Provider<PlantApiDatasource>((ref) {
  return PlantApiDatasource(
    client: http.Client(),
    baseUrl: AppConfig.baseUrl,
    token: ref.watch(backendTokenProvider) ?? '',
  );
});
```

---

## 6. SKILL: Providers Riverpod

```dart
// JWT disponible en toda la app
final backendTokenProvider = StateProvider<String?>((ref) => null);

// Lista de plantas
final plantsProvider = FutureProvider<List<Plant>>((ref) async {
  return ref.watch(plantApiDatasourceProvider).getPlants();
});

// Sensor en tiempo real (polling 15s)
final plantRealtimeSensorProvider =
    StreamProvider.family<RealtimeSensorSnapshot, String>((ref, plantId) {
  return Stream.periodic(const Duration(seconds: 15))
      .asyncMap((_) => ref.read(sensorDatasourceProvider).getLatest(plantId));
});

// Tab activo
final navigationProvider = StateProvider<int>((ref) => 0);
```

---

## 7. SKILL: Identificación de Plantas (State Machine)

```dart
// PlantIdentifyScreen
// Paso 1: capturar foto
final file = await camera.takePicture();

// Paso 2: POST /api/v1/identify — ContentType EXPLÍCITO (Android falla sin esto)
final request = http.MultipartRequest('POST', Uri.parse('$base/api/v1/identify'));
request.files.add(await http.MultipartFile.fromPath(
  'image', file.path,
  contentType: MediaType('image', 'jpeg'),  // ← OBLIGATORIO en Android
));
request.headers['Authorization'] = 'Bearer $token';

// Paso 3: manejar respuesta por status
switch (result['status']) {
  case 'needs_more_photos':    // confianza < 25%
    // mostrar dialog → retry
  case 'needs_user_selection': // confianza 25-75%
    // mostrar lista de candidatos → tap → POST /species/from-candidate
  case 'completed':            // confianza > 75%
    // mostrar confirm → POST /api/v1/plants/ → navegar a PlantProfile
}
```

---

## 8. SKILL: Testing

```
src/test/
├── core/services/          — backend_auth_service, token_storage
├── features/
│   ├── auth/               — user_profile, auth_provider
│   └── plants/
│       ├── data/datasources/ — unit tests por datasource
│       ├── data/models/      — fromJson/toJson roundtrip
│       └── presentation/providers/
├── fixtures/               — JSON snapshots de respuestas reales de la API
└── helpers/
    ├── fixture_loader.dart       — carga archivos de fixtures
    └── fake_secure_storage.dart  — fake de flutter_secure_storage
```

```dart
// Patrón fixture-driven
final json = File('test/fixtures/plants_response.json').readAsStringSync();
final plants = (jsonDecode(json) as List).map(PlantModel.fromJson).toList();

// Mock con mocktail
class MockHttpClient extends Mock implements http.Client {}
```

**Umbral de cobertura CI**: 40% en lógica de negocio (excluye screens/, widgets/, main.dart).

---

## 9. BUILD Y ENTORNOS

```bash
# Desde src/
flutter pub get
flutter analyze                  # cero warnings (--fatal-infos en CI)
flutter test --coverage

# Producción
flutter run --dart-define=BACKEND_TARGET=prod
flutter build apk --release --dart-define=BACKEND_TARGET=prod
adb install build/app/outputs/flutter-apk/app-release.apk

# Local (emulador Android → host)
flutter run --dart-define=BACKEND_TARGET=local \
            --dart-define=BACKEND_LOCAL_URL=http://10.0.2.2:8000
```

`BACKEND_TARGET` válidos: `local` | `prod` | `production` | `deploy` | `remote`

---

## 10. ⚠️ GOTCHAS CRÍTICOS

| Regla | Detalle |
|---|---|
| ContentType en multipart | Android usa `octet-stream` por defecto — siempre `MediaType('image', 'jpeg')` |
| `GET /api/v1/species` NO existe | Usar comfort zones hardcodeadas hasta que el backend lo implemente |
| Firebase SDK deshabilitado | `ENABLE_FIREBASE=false` por defecto — no llamar Firebase desde Flutter |
| Google Sign-In → Supabase directo | No pasar por el backend — intercambio directo con Supabase |
| JWT en secure storage | Nunca SharedPreferences — solo `flutter_secure_storage`, key: `gg_jwt` |
| No codegen | Sin `build_runner`, sin `*.g.dart` — JSON parsing manual |
| IndexedStack para tabs | No usar Navigator para cambiar de tab — solo `navigationProvider` |
| `GET /api/v1/species` no existe | No llamarlo — hardcodear defaults temporalmente |

---

## 11. DISEÑO — PALETA (GardenColors)

```dart
// lib/core/theme/garden_colors.dart
static const cream        = Color(0xFFFAF3E0);  // fondo principal
static const sage         = Color(0xFF6B9E7A);  // primary — botones, activos
static const forest       = Color(0xFF3D6B50);  // pressed, énfasis
static const earth        = Color(0xFF8B6340);  // suelo, cálido
static const charcoal     = Color(0xFF2D3B2E);  // texto principal
static const okGreen      = Color(0xFF52A866);  // salud: healthy
static const golden       = Color(0xFFD4A017);  // salud: warning + CTA
static const errorRose    = Color(0xFFD94F4F);  // salud: critical + errores
static const waterBlue    = Color(0xFF4A90D9);  // humedad/agua
```

Health score → color: `≥80 okGreen | ≥50 golden | <50 errorRose`

---

## 12. GIT FLOW

```
feat/* | fix/* | bug/* | refactor/* | docs/* | test/* | chore/*
       ↓
      qa
       ↓
     main
```

Commits: `<type>(<scope>): <description>` — nunca atribuir commits a IA.
