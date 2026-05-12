# Stack Tecnológico — OperadorApp

Cada paquete justificado. Versiones sugeridas alineadas con Flutter 3.22+ / Dart 3.3+.

---

## State Management & DI

| Paquete | Versión | Razón |
|---------|---------|-------|
| `flutter_riverpod` | ^2.5.1 | DI + state management en un sistema. `AsyncNotifier` encaja con Either. Mejor testeable que GetX. |
| `riverpod_annotation` | ^2.3.5 | Genera providers con anotaciones, elimina boilerplate. |
| `riverpod_generator` | ^2.4.3 | (dev) Procesador de `riverpod_annotation`. |
| `riverpod_lint` | ^2.3.13 | (dev) Lint rules específicas de Riverpod. |

---

## Navegación

| Paquete | Versión | Razón |
|---------|---------|-------|
| `go_router` | ^14.2.0 | Navegación declarativa con deep linking. Guards de auth como `redirect`. Compatible con web futuro. |

---

## Modelos e Inmutabilidad

| Paquete | Versión | Razón |
|---------|---------|-------|
| `freezed_annotation` | ^2.4.4 | Clases inmutables con `copyWith`, pattern matching, sealed classes para AppError. |
| `json_annotation` | ^4.9.0 | Serialización JSON generada; evita errores manuales de keys. |
| `freezed` | ^2.5.7 | (dev) Generador de código para freezed_annotation. |
| `json_serializable` | ^6.8.0 | (dev) Generador de `fromJson`/`toJson`. |

---

## Red y Backend

| Paquete | Versión | Razón |
|---------|---------|-------|
| `supabase_flutter` | ^2.5.3 | Cliente oficial Supabase: Auth, PostgreSQL, Storage, Realtime, Edge Functions. |
| `dio` | ^5.4.3 | HTTP cliente con interceptors (logging, auth token injection, retry). Más flexible que http. |

---

## Persistencia Local (Offline-First)

| Paquete | Versión | Razón |
|---------|---------|-------|
| `drift` | ^2.18.0 | SQLite tipado con queries validadas en compilación. Migrations versionadas. Streams reactivos. |
| `drift_dev` | ^2.18.0 | (dev) Generador de código Drift + mocks para tests sin BD real. |
| `sqlite3_flutter_libs` | ^0.5.21 | Binarios de SQLite para Android/iOS/Desktop. |
| `path_provider` | ^2.1.3 | Ruta del directorio de la app para la BD Drift. |
| `path` | ^1.9.0 | Manipulación de rutas de archivo de forma portable. |

---

## Almacenamiento Seguro

| Paquete | Versión | Razón |
|---------|---------|-------|
| `flutter_secure_storage` | ^9.2.2 | Keychain (iOS) / Keystore (Android) para tokens de sesión. Nunca SharedPreferences para tokens. |

---

## Mapas

| Paquete | Versión | Razón |
|---------|---------|-------|
| `google_maps_flutter` | ^2.7.0 | Implementación A. Mapas de alta calidad para producción. Requiere API key y facturación. |
| `flutter_map` | ^7.0.2 | Implementación B (default en dev). OpenStreetMap, sin costo, sin API key. |
| `latlong2` | ^0.9.1 | Coordenadas geográficas compatibles con `flutter_map`. |

---

## Animaciones

| Paquete | Versión | Razón |
|---------|---------|-------|
| `rive` | ^0.13.12 | Animaciones de estado (tracto en movimiento, mecánico, choque). Editor visual Rive.app. |
| `lottie` | ^3.1.2 | Animaciones After Effects para premios, bienvenida. Archivos `.json` ligeros. |
| `flutter_animate` | ^4.5.0 | Microinteracciones declarativas: slide, fade, scale en una línea de código. |

---

## Conectividad

| Paquete | Versión | Razón |
|---------|---------|-------|
| `connectivity_plus` | ^6.0.3 | Detecta cambios de red en tiempo real. Stream reactivo para activar sync al recuperar conexión. |

---

## Programación Funcional y Errores

| Paquete | Versión | Razón |
|---------|---------|-------|
| `fpdart` | ^1.1.0 | `Either<AppError, T>` para errores tipados. `Option<T>` para nulabilidad explícita. Composición con `map`/`flatMap`/`fold`. |

---

## Logging

| Paquete | Versión | Razón |
|---------|---------|-------|
| `logger` | ^2.3.0 | Logging estructurado con niveles (debug, info, warning, error). Output pretty en dev, JSON en prod. |

---

## Localización

| Paquete | Versión | Razón |
|---------|---------|-------|
| `intl` | ^0.19.0 | Formateo de fechas, números y moneda en español MX. Base para `flutter_localizations`. |

---

## Imágenes y Multimedia

| Paquete | Versión | Razón |
|---------|---------|-------|
| `cached_network_image` | ^3.3.1 | Caché de fotos de perfil de Supabase Storage. Placeholder y error widget. |
| `image_picker` | ^1.1.2 | Selección de foto de perfil desde cámara o galería. |

---

## Variables de Entorno

| Paquete | Versión | Razón |
|---------|---------|-------|
| `flutter_dotenv` | ^5.1.0 | Lee `.env` en tiempo de ejecución. Las keys nunca hardcodeadas en el código fuente. |

---

## Utilidades

| Paquete | Versión | Razón |
|---------|---------|-------|
| `equatable` | ^2.0.5 | Comparación por valor en clases que no usan Freezed. |
| `collection` | ^1.18.0 | Operaciones de colecciones: `groupBy`, `sortedBy`, `firstWhereOrNull`. |
| `rxdart` | ^0.27.7 | Operadores reactivos avanzados para streams del sync service: `debounceTime`, `switchMap`. |

---

## Build Runner & Code Generation

| Paquete | Versión | Razón |
|---------|---------|-------|
| `build_runner` | ^2.4.11 | (dev) Orquesta la generación de código de Freezed, Drift, Riverpod, JSON. |

---

## Testing

| Paquete | Versión | Razón |
|---------|---------|-------|
| `flutter_test` | SDK | Tests de widget y unitarios. |
| `integration_test` | SDK | Tests de integración en dispositivo real o emulador. |
| `mocktail` | ^1.0.4 | Mocks sin generación de código. Más simple que mockito para este stack. |

---

## Análisis Estático

| Paquete | Versión | Razón |
|---------|---------|-------|
| `very_good_analysis` | ^6.0.0 | (dev) Lint rules de Very Good Ventures: estricto, sin `dynamic` implícito, trailing commas, etc. |
| `custom_lint` | ^0.6.4 | (dev) Runner para lint plugins de terceros (riverpod_lint). |

---

## Herramientas de Desarrollo (no pub.dev)

| Herramienta | Versión | Razón |
|-------------|---------|-------|
| `lefthook` | latest | Pre-commit hooks: format → analyze → test rápidos. Sin instalación de Node. |
| `supabase-cli` | 1.x | Desarrollo local de Supabase idéntico a producción con Docker. |
| `Docker Desktop` | latest | Corre Supabase local (PostgreSQL, PostgREST, Studio). |
| `GitHub Actions` | — | CI/CD: lint + test + build APK en cada PR. |

---

## Versiones de Flutter / Dart

```yaml
environment:
  sdk: ">=3.3.0 <4.0.0"
  flutter: ">=3.22.0"
```

Flutter 3.22+ incluye Impeller por default en Android (mejor rendimiento de animaciones).
Dart 3.3+ tiene sound null safety maduro y patterns/records completos.

---

## Paquetes que se evaluaron pero NO se usaron

| Paquete | Razón de descarte |
|---------|-------------------|
| `get` / GetX | Magia implícita, difícil de testear, mezcla DI + state + routing |
| `bloc` | Boilerplate excesivo para un equipo pequeño |
| `hive` | Sin SQL, sin relaciones, migrations manuales |
| `isar` | Bueno pero Drift tiene mejor integración con Supabase y tests generados |
| `firebase_core` | Sustituido por Supabase en su totalidad |
| `provider` | Superseded por Riverpod del mismo autor |
| `shared_preferences` | Solo para configuración simple; datos estructurados van a Drift |
