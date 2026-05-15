# Pendientes de integración — Gossip Garden

Este documento registra los gaps entre el frontend Flutter y el backend FastAPI tras la implementación de `feat/backend-integration`.

---

## A. Endpoints pendientes en el backend

Funcionalidades descritas en la arquitectura pero aún no implementadas como endpoints HTTP:

| # | Endpoint | Descripción | Impacto en frontend |
|---|---|---|---|
| 1 | `GET /api/v1/species/{species_id}/profile` | Devuelve rangos de cuidado de una especie ya registrada. | Sin esto, `PlantApiDatasource.getPlants()` usa comfort zones por defecto (hardcodeados) en vez de los rangos reales del LLM. El health score y alertas son aproximados. |
| 2 | `POST /api/v1/chat/{plant_id}` | Chat con LLM usando `ai_personality_prompt` como system prompt. Infraestructura Ollama+Redis descrita en `backendGossipGarden/CLAUDE.md` pero sin implementar. | `PlantChatScreen` usa Firestore como fallback (funcional). `BackendChatService` está preparado y apunta a `AppConfig.backendBaseUrl` — solo falta el endpoint. |
| 3 | `GET /api/v1/plants/{plant_id}/sensor-data/stream` | SSE streaming de telemetría en tiempo real. | `plantRealtimeSensorProvider` usa polling cada 15s como sustituto. Cuando el endpoint exista, reemplazar el `Stream.periodic` por un `EventSource`. |
| 4 | `POST /api/v1/auth/refresh` | Refresh del JWT expirado sin requerir re-login. | Hoy: cuando el JWT expira (por defecto Supabase: 1 hora), la app fuerza logout. Implementar interceptor de 401 → refresh → reintentar. |
| 5 | CRUD `/api/v1/friendships` | Crear/aceptar/rechazar amistades. Tabla `friendships` existe en Supabase, `GET /plants?target_user_id=X` valida la amistad. | No hay UI de amistades. Se puede añadir en un PR separado una vez existan los endpoints. |

---

## B. UI no cableada en este PR (endpoint en backend ya listo)

Estas funcionalidades tienen endpoint en el backend pero no tienen pantalla conectada en este PR por estar fuera del scope "cablear lo que ya tiene UI":

| Funcionalidad | Endpoint backend | Dónde implementar |
|---|---|---|
| Crear planta manualmente (sin identificación) | `POST /api/v1/plants/` | Nueva pantalla o modal "Agregar planta" con campo de `species_id` directo o búsqueda de especie. |
| Actualizar foto de planta sin re-identificar | `PUT /api/v1/plants/{plant_id}/photo` | Botón en `PlantProfileScreen` → `image_picker` → multipart upload. |
| Historial de lecturas de sensor | `GET /api/v1/plants/{plant_id}/sensor-data/history?days=30` | Gráfica de línea en `PlantProfileScreen` o tab separado. |

---

## C. Bugs y lógica fallando — resueltos en este PR

| Bug | Estado | Fix aplicado |
|---|---|---|
| `RegisterScreen` no llamaba a `POST /auth/register`, no enviaba `username` | **Resuelto** | Añadido campo username, llamada a `backend.register()` + auto-login posterior |
| `plantsProvider` devolvía planta demo hardcodeada | **Resuelto** | Conectado a `PlantApiDatasource.getPlants()` con polling 30s |
| `PlantApiDatasource` llamaba a `/api/v1/species` (no existe en backend nuevo) | **Resuelto** | Eliminada la llamada; comfort zones usan defaults hasta que exista endpoint (A.1) |
| Ruta de sensores incorrecta: `/api/v1/sensors/{id}/latest` | **Resuelto** | Corregida a `/api/v1/plants/{id}/sensor-data/latest` con Bearer auth |
| `BackendChatService` apuntaba a URL ngrok hardcodeada | **Resuelto** | Reemplazada por `AppConfig.backendBaseUrl` |
| Token JWT perdido al cerrar la app (solo en memoria) | **Resuelto** | `flutter_secure_storage` con bootstrap en `AuthNotifier._bootstrap()` |
| Google sign-in (Firebase) no negociaba JWT de Supabase | **Resuelto** | Flujo nuevo: `GET /auth/google-url` → `flutter_web_auth_2` → parsear fragment → guardar JWT |
| `plantRealtimeSensorProvider` emitía ruido aleatorio (mock) | **Resuelto** | Reemplazado por polling real al endpoint de sensores cada 15s |

---

## D. Deuda técnica conocida (no bloqueante)

- **Comfort zones por defecto**: mientras no exista `GET /species/{id}/profile`, las alertas y el health score usan rangos genéricos. Las plantas recién identificadas con `/identify` tienen el `species_id` correcto — se necesita el endpoint para retroalimentar los rangos al listar plantas.
- **JWT expira sin refresh**: al cabo de ~1 hora el token caduca, el backend devuelve 401 y `UnauthorizedException` llega hasta `plantsProvider`. La app muestra error pero no hace logout automático. Implementar el interceptor cuando exista el endpoint de refresh.
- **Google OAuth mobile deep link**: requiere configurar el client ID de Google OAuth en Supabase Console y el redirect URI `gossipgarden://auth/callback`. Sin esta configuración, el botón de Google arroja error en `getGoogleAuthUrl`.
- **`withOpacity` deprecation**: ~60 warnings en código pre-existente. No introducidos en este PR; se pueden resolver en un PR de linting independiente.
