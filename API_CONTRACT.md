> ⚠️ **DOCUMENTO DESACTUALIZADO** — Este contrato describe la API del backend Railway antiguo.
> El contrato vigente es `backendGossipGarden/API_CONTRACT.md` (base `/api/v1`, JWT Bearer).
> Rama activa de integración: `feat/backend-integration`. Ver `PENDING_BACKEND.md` para gaps.

# Contrato de API consumido por el frontend (LEGACY)

Este documento describe **exactamente** qué espera el frontend Flutter (`gossip_garden/`) del backend. Sirve como contrato para refactorizar el backend sin romper la app.

> **Generado a partir de**:
> - `lib/core/config/app_config.dart`
> - `lib/features/plants/data/datasources/plant_api_datasource.dart`
> - `lib/features/plants/data/datasources/sensor_stream_datasource.dart`
> - `lib/features/plants/data/models/realtime_sensor_snapshot.dart`
>
> Si tocas alguno de esos cuatro archivos, este doc puede quedar desactualizado.

---

## 0. Reglas globales

### URL base

Resuelta en `AppConfig.backendBaseUrl`:

| `BACKEND_TARGET`                                    | URL usada                  |
| --------------------------------------------------- | -------------------------- |
| `prod` / `production` / `deploy` / `remote` (default) | `BACKEND_DEPLOY_URL`       |
| `local`                                             | `BACKEND_LOCAL_URL`        |

Default de prod: `https://gossip-garden-backend.up.railway.app`. La barra final se recorta automáticamente, así que el backend puede o no servir con `/` final.

### Headers

- **No se envían**: ni `Authorization`, ni `Content-Type`, ni `Accept` (excepto en SSE, ver §4).
- **No hay autenticación** entre app y backend: todo lo que el backend exponga será accesible sin token. Si vas a añadir auth, requerirá cambios en el front.

### Métodos

Todos los endpoints son **`GET`**. El front no envía `POST`/`PUT`/`PATCH`/`DELETE` a este backend.

### Forma de error que el front entiende

`PlantApiDatasource._getJson` (`plant_api_datasource.dart:91-105`):

- Status code **fuera de `200..299`** → lanza `Exception('Error <code> consumiendo <path>')`. Esto **rompe la pantalla** salvo en `/sensor_data/{plant_id}` (ver §3).
- Body que **no decodifique a un objeto JSON top-level** (`Map`) → lanza `Exception('Respuesta invalida en <path>')`.
- **Cualquier código 2xx con JSON-objeto válido se acepta**, aunque los campos esperados falten (el front aplica defaults).

### Coerción de tipos

Los helpers `_toInt`, `_toDouble`, `_toString` aceptan **int, double, num o string parseable**. Es decir, el backend puede devolver `"42"` o `42` o `42.0` para un campo numérico y el front lo acepta. **Recomendado**: devolver tipos JSON nativos (`number`, no string) para evitar ambigüedades.

### Resumen de endpoints

| #   | Método | Path                                | Consumido en                                    | Crítico para |
| --- | ------ | ----------------------------------- | ----------------------------------------------- | ------------ |
| 1   | GET    | `/plants`                           | `PlantApiDatasource.getPlants`                  | Toda la app  |
| 2   | GET    | `/plant_species`                    | `PlantApiDatasource.getPlants`                  | Toda la app  |
| 3   | GET    | `/sensor_data/{plant_id}`           | `PlantApiDatasource._getSensorSnapshot`         | Telemetría   |
| 4   | GET    | `/sensor_data/{plant_id}/stream`    | `SensorStreamDatasource.watchPlantSensor` (SSE) | Tiempo real  |

> **Importante**: cada vez que el `plantsProvider` se invalida (cada 5 s, ver `plant_providers.dart:25-32`), el front llama 1× a `/plants`, 1× a `/plant_species` y **1× a `/sensor_data/{id}` por cada planta** que devuelve `/plants`. Si la lista crece, el fan-out en `/sensor_data/...` crece linealmente.

---

## 1. `GET /plants`

### Llamada

```
GET {BASE}/plants
```

Sin parámetros, sin headers, sin body.

### Response esperado (200 OK)

```jsonc
{
  "plants": [
    {
      "plant_id": 1,                  // requerido, ver abajo
      "plant_species_id": 7,          // requerido (alias aceptado: "plant_specie_id")
      "name": "Albahaca de la cocina" // opcional
      // ...cualquier otro campo se ignora
    }
  ]
}
```

### Campos leídos por el front

| Campo                                       | Tipo esperado     | Requerido | Default si falta              | Dónde se usa                                                                  |
| ------------------------------------------- | ----------------- | --------- | ----------------------------- | ----------------------------------------------------------------------------- |
| `plants`                                    | array             | sí        | `[]` (silencioso)             | Iteración para crear `Plant`s                                                  |
| `plants[].plant_id`                         | int / num / str   | sí        | `0`                           | `Plant.id` (string), key para `/sensor_data/{id}`                             |
| `plants[].plant_species_id`                 | int / num / str   | sí¹       | `-1` → no resuelve la especie | Lookup en el mapa que viene de `/plant_species`                               |
| `plants[].plant_specie_id`                  | int / num / str   | —         | —                             | Alias de `plant_species_id`. Sólo se usa si `plant_species_id` está ausente.  |
| `plants[].name`                             | string            | no        | `"Planta #<plant_id>"`        | `Plant.name`, mostrado en cards/dashboard/chat                                |

¹ Si falta o es `≤ 0`, la planta se queda sin especie → el front cae a **comfort zones por defecto** (ver §2 sección de defaults).

### Campos que el front ignora (puedes mantener, mover o eliminar)

Cualquier otro campo dentro de `plants[]`. El front **no** lee `created_at`, `user_id`, `image`, `notes`, etc., aunque el backend los envíe.

### Errores tolerados

- `plants` ausente o no es array → se interpreta como lista vacía, **no rompe**.
- Items de `plants` que no son objetos → se ignoran silenciosamente (`whereType<Map>()`).
- Campos numéricos en string → se parsean.

### Errores **no** tolerados

- Status no-2xx → excepción → la pantalla principal queda en estado de error visible.
- Body que no sea un objeto JSON → excepción.

---

## 2. `GET /plant_species`

### Llamada

```
GET {BASE}/plant_species
```

Sin parámetros.

### Response esperado (200 OK)

```jsonc
{
  // Aceptado en plural (preferido) o singular como alias:
  "plant_species_profiles": [
    {
      "plant_species_id": 7,            // requerido (alias: "plant_specie_id")
      "specie_name": "Albahaca",        // opcional (alias: "species_name")
      "personality": "dramática y ansiosa cuando le falta agua",
      "min_humidity": 40,
      "max_humidity": 70,
      "min_temperature": 18,
      "max_temperature": 27,
      "min_soil_moisture": 30,
      "max_soil_moisture": 60,
      "min_light": 250,
      "max_light": 1100
    }
  ]
}
```

### Campos leídos por el front

| Campo                                                  | Tipo            | Requerido | Default si falta | Uso                                                                                             |
| ------------------------------------------------------ | --------------- | --------- | ---------------- | ----------------------------------------------------------------------------------------------- |
| `plant_species_profiles` **o** `plant_species_profile` | array           | sí¹       | `[]`             | Lista a indexar por `plant_species_id`                                                          |
| `[].plant_species_id` (alias `plant_specie_id`)        | int / num / str | sí        | item descartado² | Clave para hacer match con `plants[].plant_species_id`                                          |
| `[].specie_name` (alias `species_name`)                | string          | no        | `"Especie desconocida"` | `Plant.species`, mostrado en cards/perfil/chat                                          |
| `[].personality`                                       | string          | no        | `playful` enum   | Clasificada por substring (ver tabla abajo)                                                     |
| `[].min_humidity`                                      | num / str       | no        | `40`             | `comfortZones.humidity.min` — usado en cálculo de `health`, `mood`, insights, telemetry panel   |
| `[].max_humidity`                                      | num / str       | no        | `70`             | `comfortZones.humidity.max`                                                                     |
| `[].min_temperature`                                   | num / str       | no        | `18`             | `comfortZones.temperature.min`                                                                  |
| `[].max_temperature`                                   | num / str       | no        | `27`             | `comfortZones.temperature.max`                                                                  |
| `[].min_soil_moisture`                                 | num / str       | no        | `30`             | `comfortZones.soilMoisture.min` — además influye `lastWatered`                                  |
| `[].max_soil_moisture`                                 | num / str       | no        | `60`             | `comfortZones.soilMoisture.max`                                                                 |
| `[].min_light`                                         | num / str       | no        | `250`            | `comfortZones.light.min`                                                                        |
| `[].max_light`                                         | num / str       | no        | `1100`           | `comfortZones.light.max`                                                                        |

¹ Si las dos claves faltan, se asume `[]` y todas las plantas usan defaults.
² Items cuyo id resuelve a `≤ 0` no entran al mapa, aunque tengan los demás campos.

### Mapeo de `personality` (insensible a mayúsculas, busca substrings)

Definido en `_derivePersonality` (`plant_api_datasource.dart:221-238`). La cadena se `toLowerCase()` y luego:

| Substring presente                                | Resultado en `Plant.personality`     |
| ------------------------------------------------- | ------------------------------------ |
| `"fuerte"`, `"resistente"`, `"sabia"`, `"serena"` | `PlantPersonality.wise`              |
| `"dram"`, `"intensa"`, `"ans"`                    | `PlantPersonality.dramatic`          |
| cualquier otra cosa (incluido vacío/null)         | `PlantPersonality.playful` (default) |

Si añades nuevos arquetipos en el back, **añade el mapeo aquí** o el front los degradará a `playful`.

### Campos ignorados

Cualquier otro campo en cada perfil. No se lee `description`, `watering_frequency`, `image_url`, etc.

---

## 3. `GET /sensor_data/{plant_id}`

### Llamada

```
GET {BASE}/sensor_data/<plant_id>
```

`plant_id` es el `plant_id` numérico que vino en `/plants`. Si por alguna razón la planta tiene `plant_id <= 0`, el front **no llama** este endpoint y trata la planta como offline.

### Response esperado (200 OK)

```jsonc
{
  "sensor_data": {                 // último registro crudo (puede ser null/ausente)
    "sensor_data_id": 1234,
    "timestamp": "2026-04-29T13:45:00Z",
    "humidity": 55.2,
    "temperature": 22.1,
    "light": 760,
    "soil_moisture": 42.5
  },
  "averages": {                    // promedios históricos (puede ser null/ausente)
    "humidity": 52.0,
    "temperature": 21.8,
    "light": 700,
    "soil_moisture": 40.0
  },
  "readings_count": 142            // cuantas lecturas se promediaron (default 0)
}
```

### Campos leídos por el front

| Campo                            | Tipo             | Requerido | Default            | Uso                                                                                       |
| -------------------------------- | ---------------- | --------- | ------------------ | ----------------------------------------------------------------------------------------- |
| `sensor_data`                    | objeto / null    | no        | `null` → offline   | Su mera presencia → `SensorStatus.degraded` mínimo; ver tabla de status                   |
| `sensor_data.timestamp`          | ISO 8601 string  | no¹       | `null` → degraded  | Calcula edad de la lectura en UTC. Determina `SensorStatus` y `confidence`.               |
| `sensor_data.humidity`           | num / str        | no        | `0`                | Fallback si `averages.humidity` está ausente                                              |
| `sensor_data.temperature`        | num / str        | no        | `0`                | Fallback                                                                                  |
| `sensor_data.light`              | num / str        | no        | `0`                | Fallback                                                                                  |
| `sensor_data.soil_moisture`      | num / str        | no        | `0`                | Fallback                                                                                  |
| `averages`                       | objeto / null    | no        | usa `sensor_data`  | Si está, **tiene precedencia** sobre `sensor_data` para los valores mostrados             |
| `averages.humidity`              | num / str        | no        | `sensor_data.humidity` o `0` | `Plant.sensors.humidity` y cálculo de health                                    |
| `averages.temperature`           | num / str        | no        | id.                | id.                                                                                       |
| `averages.light`                 | num / str        | no        | id.                | id.                                                                                       |
| `averages.soil_moisture`         | num / str        | no        | id.                | id. + cálculo de `lastWatered`                                                            |
| `readings_count`                 | int / num / str  | no        | `0`                | Texto en panel de insights: `"Promedios calculados con N lecturas."` vs `"última lectura"`|

¹ Si `sensor_data` existe pero `timestamp` falta o no parsea → `SensorStatus.degraded`.

### Derivación de `SensorStatus` (afecta health, mood, badges)

Calculada en `_deriveSensorStatus` y `_deriveConfidence` (`plant_api_datasource.dart:183-219`):

| Condición sobre el response                                    | `SensorStatus` | `ConfidenceLevel` |
| -------------------------------------------------------------- | -------------- | ----------------- |
| `sensor_data` ausente / null                                   | `offline`      | `low`             |
| `sensor_data` presente pero sin `timestamp` parseable           | `degraded`     | `medium`          |
| `timestamp` con edad **≤ 20 min** (UTC)                         | `online`       | `high`            |
| `timestamp` con edad entre 20 min y **3 horas**                 | `degraded`     | `medium`          |
| `timestamp` con edad **> 3 horas**                              | `offline`      | `low`             |

> El backend **debe enviar timestamps en UTC** (con `Z` o `+00:00`). Cualquier zona se acepta vía `DateTime.parse`, pero la comparación se hace contra `DateTime.now().toUtc()`. Si envías hora local sin offset, la edad puede salir negativa o errónea.

### Manejo de errores especial

`_getSensorSnapshot` (`plant_api_datasource.dart:107-126`) **envuelve toda la llamada en try/catch**. Cualquier excepción (status no-2xx, JSON inválido, timeout, body no-objeto) se traduce a `_SensorSnapshot()` vacío → la planta aparece como `offline` pero **el resto de la pantalla no se rompe**.

Esto significa que:

- Devolver **404** para una planta sin lecturas es tolerado (sale offline).
- Devolver **500** también es tolerado (sale offline). No es ideal, pero no rompe.
- El usuario no ve un error explícito; sólo que la planta está offline.

### Recomendaciones para el refactor

- Si vas a separar el endpoint en dos (p. ej. `/sensor_data/{id}/latest` + `/sensor_data/{id}/averages`), tienes que **actualizar el front** o componer la respuesta en un BFF.
- El front **no envía rangos de tiempo ni `limit`**: el cálculo del periodo de los `averages` es totalmente decisión del backend.
- `readings_count` sólo aparece en una línea de texto. Si lo eliminas, el front mostrará `"Mostrando la última lectura disponible."` en lugar de `"Promedios calculados con N lecturas."` — comportamiento aceptable.

---

## 4. `GET /sensor_data/{plant_id}/stream` (SSE)

### Llamada

```
GET {BASE}/sensor_data/<plant_id>/stream
Accept: text/event-stream
```

Es el único endpoint con header explícito (`Accept`). Se abre con `http.Request('GET', uri)` y se consume línea por línea.

### Formato esperado

Server-Sent Events estándar. El parser sólo reconoce **líneas que empiezan con `data: `**; cualquier otro tipo de línea (eventos `event:`, `id:`, comentarios `:`, líneas en blanco) se ignora silenciosamente.

```
data: {"plant_id": 1, "sensor_data": {"sensor_data_id": 1234, "timestamp": "2026-04-29T13:45:00Z", "temperature": 22.1, "humidity": 55.2, "soil_moisture": 42.5, "light": 760}}

data: {"plant_id": 1, "sensor_data": {...}}
```

Reglas concretas (`sensor_stream_datasource.dart:24-43`):

- Cada línea `data: ...` debe contener **un JSON-objeto completo en una sola línea**. No se concatenan múltiples `data:` consecutivos como en SSE clásico — si partes el JSON en varias líneas, sólo se parsea la última.
- Líneas vacías después del prefijo se ignoran.
- JSON inválido **lanza** (no se atrapa), así que el stream se rompe. Si necesitas robustez, envía siempre payloads válidos o nada.

### Schema del payload por evento

```jsonc
{
  "plant_id": 1,                   // requerido (default 0 si falta)
  "sensor_data": {
    "sensor_data_id": 1234,        // opcional
    "timestamp": "2026-04-29T13:45:00Z",  // opcional, ISO 8601
    "temperature": 22.1,           // opcional
    "humidity": 55.2,              // opcional
    "soil_moisture": 42.5,         // opcional
    "light": 760                   // opcional
  }
}
```

### Campos leídos

| Campo                              | Tipo              | Default      | Uso                                                  |
| ---------------------------------- | ----------------- | ------------ | ---------------------------------------------------- |
| `plant_id` (top-level)             | int / num / str   | `0`          | `RealtimeSensorSnapshot.plantId`                     |
| `sensor_data.sensor_data_id`       | int / num / str   | `null`       | `sensorDataId` (sólo informativo)                    |
| `sensor_data.timestamp`            | string ISO 8601   | `null`       | `DateTime.tryParse` — si falla, queda `null`         |
| `sensor_data.temperature`          | num / str         | `null`       | `temperature`                                        |
| `sensor_data.humidity`             | num / str         | `null`       | `humidity`                                           |
| `sensor_data.soil_moisture`        | num / str         | `null`       | `soilMoisture`                                       |
| `sensor_data.light`                | num / str         | `null`       | `light`                                              |

> Nota: el wrapper `sensor_data` es **obligatorio en el payload SSE**. Si pones los valores en el top-level (al estilo del REST de §3 mezclado), el front leerá `null` en todo. La forma SSE **no es** la misma que `/sensor_data/{id}` aunque comparta nombres.

### Campos ignorados

Cualquier campo extra dentro de `sensor_data` (`averages`, `readings_count`, etc.). No los proceses si no quieres.

### Quién consume este stream

El provider `plantRealtimeSensorProvider` (`plant_providers.dart:34-37`). Hoy se usa en pantallas de detalle/telemetría para mostrar valores en vivo, sin afectar la lista que pollea por REST.

### Recomendaciones para el refactor

- **No cambies el wrapper `sensor_data`** en el SSE sin actualizar `RealtimeSensorSnapshot.fromJson`.
- Si vas a migrar a WebSocket o MQTT directo, requiere reescribir `SensorStreamDatasource` (no es transparente).
- Si el backend cierra el stream limpiamente, el `StreamProvider` simplemente termina; el front **no reintenta solo**. El usuario tiene que volver a entrar a la pantalla.

---

## 5. Lo que el front **NO** llama al backend (para evitar confusiones)

Estos flujos no tocan tu backend; cualquier refactor ahí no rompe la app:

| Funcionalidad                       | Dónde vive realmente                                                           |
| ----------------------------------- | ------------------------------------------------------------------------------ |
| Login con Google                    | Firebase Auth + `google_sign_in`                                                |
| Perfil de usuario (`UserProfile`)   | Firestore: colección `users/{uid}`                                              |
| Onboarding (flag `onboardingCompleted`) | Firestore: campo en `users/{uid}`                                            |
| Chat con plantas                    | Firestore: subcolección `plants/{plantId}/messages`, ordenada por `timestampMs` |
| Achievements, friendships, tasks    | **No implementados en el front todavía** (pese a existir tablas en el DER)      |

Si quieres que estos flujos pasen por tu backend en vez de Firebase, requiere cambios en el front, no sólo en el back.

---

## 6. Checklist rápido antes de mergear cambios en el backend

- [ ] `/plants` sigue devolviendo `{"plants": [...]}` con `plant_id` y `plant_species_id` numéricos.
- [ ] `/plant_species` sigue devolviendo `{"plant_species_profiles": [...]}` (o el alias singular) con `plant_species_id` y los `min_*`/`max_*`.
- [ ] `/sensor_data/{id}` sigue devolviendo `{"sensor_data": {...}, "averages": {...}, "readings_count": n}` con `timestamp` ISO 8601 en UTC.
- [ ] `/sensor_data/{id}/stream` sigue emitiendo SSE con `data: <json en una línea>` envolviendo en `sensor_data`.
- [ ] Códigos 2xx en happy path; cualquier 4xx/5xx fuera de `/sensor_data/{id}` rompe pantalla.
- [ ] Si renombras campos en español/inglés (`specie_name` ↔ `species_name`, `plant_species_id` ↔ `plant_specie_id`), verifica que mantienes **al menos uno de los dos alias** que el front entiende.
- [ ] Carga: si añades plantas, mide el costo de `N+1` llamadas a `/sensor_data/{id}` cada 5 segundos.