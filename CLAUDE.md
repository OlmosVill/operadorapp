# CLAUDE.md — OperadorApp

Guía de contexto para el agente. Leer antes de cualquier tarea.

---

## Qué es este proyecto

App móvil Flutter para operadores de tractocamiones de una empresa logística. Muestra perfil del operador, historial de viajes, sistema de puntos gamificado (niveles Plata→Diamante) y catálogo de premios canjeables. El backend es Supabase (PostgreSQL + Auth + Edge Functions).

**Regla de seguridad crítica**: la lógica de cálculo de puntos SOLO vive en Edge Functions, nunca en el cliente. El usuario lo explicó explícitamente para evitar manipulación.

---

## Stack

| Capa | Tecnología | Versión |
|---|---|---|
| UI | Flutter | >=3.22 |
| Lenguaje | Dart | >=3.3 |
| State / DI | flutter_riverpod | ^3.1.0 (con legacy.dart para StateNotifier/ChangeNotifier) |
| Navegación | go_router | ^17.x |
| Modelos | freezed + freezed_annotation | ^3.x → requiere `sealed class` |
| Backend | supabase_flutter | local: 127.0.0.1:54321 |
| DB local | drift (SQLite) | 14 tablas, 6 DAOs, SyncService activo |
| Errores | fpdart Either<AppError, T> | en toda la capa domain/data |
| Mapas | flutter_map (OSM) / google_maps | seleccionable via .env MAP_PROVIDER |
| Config | flutter_dotenv | .env como asset |
| Temas | shared_preferences | persistencia de themeMode |
| Lint | very_good_analysis | muy estricto, ver analysis_options.yaml |

---

## Arquitectura

Clean Architecture por feature. Cada feature tiene:

```
lib/features/<feature>/
  domain/
    entities/        # Freezed sealed classes
    repositories/    # Interfaces abstractas
    usecases/        # Lógica de negocio pura
  data/
    datasources/     # Supabase / SQLite
    repositories/    # Implementaciones concretas
  presentation/
    providers/       # Riverpod (StateNotifier legacy)
    screens/
    widgets/
```

Capas compartidas:

```
lib/core/
  config/            # AppConfig (carga .env)
  constants/         # AppConstants (authEmailSuffix, SharedPrefs keys)
  errors/            # sealed class AppError y subclases
  providers/         # supabaseClientProvider, sharedPreferencesProvider, loggerProvider
  router/            # GoRouter con auth guard
  theme/             # AppTheme (dark/light), AppColors

lib/shared/widgets/  # AppLoadingWidget, AppErrorWidget
```

---

## Convenciones de código

- **Código en inglés**, comentarios y commits en español
- Commits en formato **Conventional Commits**: `feat:`, `fix:`, `docs:`, `chore:`, etc.
- Imports con `package:operadorapp/...` siempre (no relativos) — lo exige el lint
- Sin comentarios obvios; solo comentar el "por qué" no evidente
- `sealed class` en entidades Freezed (cambio de Freezed 2→3)
- Providers legacy: importar `flutter_riverpod/legacy.dart` para `StateNotifierProvider` y `ChangeNotifierProvider`
- Errores tipados: `Either<AppError, T>` en domain y data, nunca `throw` directamente
- Auth email convention: `{numero_empleado}@operadorapp.internal` (el sufijo está en `AppConstants.authEmailSuffix`)

---

## Estado del desarrollo

### ✅ Fase 0 — Planificación y documentación
Completa. Ver `docs/`: ARCHITECTURE.md, DATABASE.md, OFFLINE_STRATEGY.md, NOTIFICATIONS.md, ROADMAP.md, STACK.md.

### ✅ Fase 1 — Setup + Auth + Perfil básico + Temas
Completa. 15/15 tests pasando.

Archivos clave:
- `lib/main.dart` — inicialización completa (AppConfig → Supabase → SharedPrefs → ProviderScope)
- `lib/core/router/app_router.dart` — GoRouter con auth guard y ShellRoute (home/perfil/settings)
- `lib/features/auth/` — Login, ForgotPassword, providers, usecases, repositorio con Supabase
- `lib/features/profile/` — ProfileScreen con foto, nivel badge, barra de progreso, stats
- `lib/features/settings/` — SettingsScreen (tema, notificaciones, logout)
- `lib/features/trips/presentation/screens/home_screen.dart` — placeholder hasta Fase 4

### ✅ Fase 2 — Drift Local + Sincronización Supabase + Repositorios
Completa. 18/18 tests pasando.

Archivos clave:
- `lib/core/database/tables.dart` — 14 tablas Drift (+ TractosTable, HistorialTractosTable en Fase 7)
- `lib/core/database/app_database.dart` — AppDatabase con DAOs: PointsDao, ProfileDao, RewardsDao, SyncDao, TripsDao, TrucksDao; schemaVersion = 2
- `lib/core/services/connectivity_service.dart` — ConnectivityService (connectivity_plus)
- `lib/core/services/sync_service.dart` — pull incremental Supabase→Drift; parseo EWKB geography
- `lib/features/profile/` — refactorizado a offline-first con StreamProvider que observa Drift
- `lib/features/trips/domain/` — Trip, TripDetail, TripIncident, SecurityAlert, GpsPoint (Freezed)
- `lib/features/trips/data/` — DriftTripsLocalDatasource + TripsRepositoryImpl
- `lib/features/trips/presentation/providers/trips_provider.dart` — tripsProvider + tripDetailProvider
- `lib/core/providers/core_providers.dart` — appDatabaseProvider, connectivityServiceProvider, syncServiceProvider
- `lib/features/settings/` — indicador de sync (online/offline) en SettingsScreen

### ✅ Fase 3 — Historial de Viajes + Detalle con Mapa
Completa. 18/18 tests pasando.

Archivos clave:
- `lib/core/maps/map_adapter.dart` — interface `MapAdapter` (seleccionable via `AppConfig.mapProvider`)
- `lib/core/maps/osm_map_adapter.dart` — implementación flutter_map (OSM, default dev)
- `lib/core/maps/google_map_adapter.dart` — implementación google_maps_flutter (activar con `MAP_PROVIDER=google`)
- `lib/features/trips/presentation/widgets/trip_card.dart` — card de viaje: origen→destino, estado, KM, puntos
- `lib/features/trips/presentation/widgets/trip_map_view.dart` — widget que selecciona adapter por config
- `lib/features/trips/presentation/screens/trips_list_screen.dart` — lista agrupada por mes, pull-to-refresh
- `lib/features/trips/presentation/screens/trip_detail_screen.dart` — detalle: stats, mapa GPS, incidencias, alertas
- `lib/core/router/app_router.dart` — pestaña Viajes añadida (índice 1); `/trips` en ShellRoute; `/trips/:id` fuera del shell (pantalla completa sin nav bar)

### ✅ Fase 4 — Home Dinámico + Animaciones
Completa. Lint limpiado (0 issues tras `flutter analyze`).

Archivos clave:
- `lib/features/trips/presentation/providers/home_provider.dart` — `HomeState` sealed class (activeTrip, welcomeBack, dashboard), `homeStateProvider`, `updateHomLastSeen`
- `lib/features/trips/presentation/screens/home_screen.dart` — `ConsumerStatefulWidget` con 3 vistas: `_ActiveTripView`, `_WelcomeBackView`, `_DashboardView`; animaciones flutter_animate
- `lib/features/trips/presentation/widgets/active_trip_card.dart` — card de viaje activo con mapa miniatura, punto pulsante, stats (tiempo, KM, rendimiento)

### ✅ Fase 5.1 — Sistema de Puntos + Historial
Completa. 24/24 tests pasando. 0 issues `flutter analyze`.

Archivos clave:
- `lib/core/database/daos/points_dao.dart` — `watchByOperador`, `getLastCreatedAt`, `upsertAll`
- `lib/core/services/sync_service.dart` — `syncMovimientos()` pull incremental de `movimientos_puntos`
- `lib/features/points/domain/entities/point_movement.dart` — `PointMovement` (Freezed), `MovementType` enum
- `lib/features/points/data/repositories/points_repository_impl.dart` — patrón `async*`/`await for`
- `lib/features/points/presentation/providers/points_provider.dart` — `movementsProvider` StreamProvider
- `lib/features/points/presentation/screens/points_screen.dart` — balance, progreso de nivel, historial
- `lib/features/points/presentation/widgets/movement_tile.dart` — tile con signo, color, ícono por tipo
- `lib/core/router/app_router.dart` — ruta `/points` fuera del ShellRoute
- `lib/features/trips/presentation/screens/home_screen.dart` — `_PointsBalanceCard` tappable → `/points`
- `supabase/migrations/20240101000001_trigger_puntos_viaje.sql` — trigger `trg_viaje_completado`
- `supabase/functions/calcular-puntos-viaje/index.ts` — Edge Function Deno (invocación manual/admin)

### ✅ Fase 5.2 — Catálogo y Canje de Premios
Completa. 29/29 tests pasando. 0 issues `flutter analyze`.

Archivos clave:
- `lib/core/database/daos/rewards_dao.dart` — `watchCatalogo`, `getLastUpdatedAt`, `upsertPremios`, `watchByOperador`, `upsertCanjes`
- `lib/core/services/sync_service.dart` — `syncCatalogo()` + `syncCanjes()` añadidos
- `lib/features/rewards/domain/entities/premio.dart` — `Premio`/`Canje` (Freezed), `PremioTipo`/`CanjeEstado` enums
- `lib/features/rewards/data/repositories/rewards_repository_impl.dart` — patrón `async*`/`await for`; `canjearPremio` vía Edge Function
- `lib/features/rewards/data/datasources/rewards_remote_datasource.dart` — llama Edge Function `canjear-premio`
- `lib/features/rewards/presentation/providers/rewards_provider.dart` — `premiosProvider`, `canjesProvider`, `canjearUsecaseProvider`
- `lib/features/rewards/presentation/screens/rewards_screen.dart` — catálogo grid + filtros + historial canjes
- `lib/features/rewards/presentation/widgets/premio_card.dart` — card con estado (disponible/próximo/nivel insuficiente)
- `lib/features/rewards/presentation/widgets/canje_sheet.dart` — bottom sheet de confirmación de canje
- `supabase/functions/canjear-premio/index.ts` — Edge Function Deno; valida JWT, puntos, nivel y stock
- `lib/core/router/app_router.dart` — ShellRoute: Home(0), Viajes(1), Premios(2), Settings(3); Perfil fuera del nav bar (accesible por LevelBadge en AppBar)

### ✅ Fase 6 — Roadmap de Premios
Completa. 32/32 tests pasando. 0 issues `flutter analyze`.

Archivos clave:
- `lib/features/rewards/presentation/screens/rewards_roadmap_screen.dart` — timeline con filtro por nivel; `filterAndSortPremios()` top-level (testeable)
- `lib/features/rewards/presentation/widgets/roadmap_milestone.dart` — hito con nodo coloreado por tipo, barra de progreso, nodo pulsante si `isTarget`
- `lib/core/router/app_router.dart` — ruta `/rewards/roadmap` standalone
- `lib/features/rewards/presentation/screens/rewards_screen.dart` — botón mapa en AppBar → `/rewards/roadmap`

### ✅ Fase 7 — Historial de Tractos
Completa. Tests pasando. 0 issues `flutter analyze` esperados.

Archivos clave:
- `lib/core/database/tables.dart` — 14 tablas (+ `TractosTable`, `HistorialTractosTable`); `schemaVersion` → 2
- `lib/core/database/daos/trucks_dao.dart` — join historial↔tracto, viajes por tracto, reportes por tracto
- `lib/core/services/sync_service.dart` — `syncTractos()`, `syncHistorialTractos()`, `syncReportesOperador()` añadidos
- `lib/features/trucks/domain/entities/truck.dart` — `TruckSummary` + `TruckReport` (Freezed sealed)
- `lib/features/trucks/domain/repositories/trucks_repository.dart` — interface
- `lib/features/trucks/data/repositories/trucks_repository_impl.dart` — patrón `async*`/`await for`; rendimiento promedio calculado de viajes
- `lib/features/trucks/presentation/providers/trucks_provider.dart` — `truckSummariesProvider`, `truckReportsProvider`, `truckRendimientoProvider`
- `lib/features/trucks/presentation/screens/trucks_history_screen.dart` — lista de tractos con stats, animaciones flutter_animate
- `lib/features/trucks/presentation/screens/truck_detail_screen.dart` — stats, comparativa de rendimiento, reportes agrupados
- `lib/core/router/app_router.dart` — rutas `/trucks` y `/trucks/:id` standalone
- `lib/features/trips/presentation/screens/trips_list_screen.dart` — botón ícono tracto en AppBar → `/trucks`

### 🔄 Próxima: Fase 8 — Notificaciones In-App + Preparación Push
Ver `docs/ROADMAP.md`.

---

## Comandos útiles

```powershell
# Levantar Supabase local (requiere Docker Desktop corriendo)
supabase start

# Ver credenciales del Supabase local
supabase status
# → Publishable key = SUPABASE_ANON_KEY en .env
# → URL = http://127.0.0.1:54321

# Aplicar migraciones y seed
supabase db reset

# Generar código (Freezed, Riverpod, Drift)
dart run build_runner build

# Correr tests
flutter test

# Analizar código
flutter analyze

# Correr en emulador Android
flutter run -d emulator-5554

# Ver dispositivos disponibles
flutter devices
```

---

## Variables de entorno (.env)

El archivo `.env` está en `.gitignore` — cada dev lo crea manualmente:

```
SUPABASE_URL=http://10.0.2.2:54321       # Android emulator → host
SUPABASE_ANON_KEY=sb_publishable_...      # "Publishable" key de supabase status
MAP_PROVIDER=osm
GOOGLE_MAPS_API_KEY=
```

> Para tests en la máquina host (no emulador), URL sería `http://127.0.0.1:54321`.
> El `.env` debe estar declarado como asset en `pubspec.yaml` — ya está configurado.

---

## Decisiones técnicas importantes

| Decisión | Razón |
|---|---|
| Supabase sobre Firebase | PostgreSQL con RLS real, Edge Functions en Deno, sin vendor lock-in de Google |
| Riverpod sobre Bloc | Menos boilerplate, composición de providers, testeable sin BuildContext |
| Drift sobre Hive | SQL tipado, migraciones versionadas, queries complejas para offline-first |
| fpdart Either | Errores tipados en tiempo de compilación, sin excepciones no controladas |
| `sealed class` en Freezed | Requerido por Freezed 3.x (la v2 usaba `class`; el generador crea un mixin con getters abstractos) |
| `flutter_riverpod/legacy.dart` | Riverpod 3.x movió StateNotifierProvider y ChangeNotifierProvider a legacy — import necesario |
| `[auth.email]` sin `enable_signup` | En Supabase CLI v2.x, `[auth.email] enable_signup = false` mapea a `GOTRUE_EXTERNAL_EMAIL_ENABLED=false`, deshabilitando el login completo. El bloqueo de registro lo hace `[auth] enable_signup = false` |
| Puntos solo en Edge Functions | Seguridad: el cliente no puede alterar el cálculo de puntos |
| `enable_signup = false` en Supabase | RH crea operadores manualmente en Studio — no hay auto-registro |

---

## Gotchas descubiertos

1. **`[auth.email] enable_signup = false` rompe el login** — En Supabase CLI v2.x este campo mapea a `GOTRUE_EXTERNAL_EMAIL_ENABLED=false`, deshabilitando el provider de email completo (no solo el registro). La solución: solo usar `[auth] enable_signup = false`.

2. **Freezed 3.x requiere `sealed class`** — Con `class` el analizador tira error porque el mixin generado tiene getters abstractos que la clase no implementa. Siempre usar `sealed class` con `@freezed`.

3. **`valueOrNull` no existe en Riverpod 3.x** — Fue renombrado a `.value` (que ahora devuelve `T?` en lugar de lanzar). Afecta cualquier uso de `asyncValue.valueOrNull`.

4. **`CardTheme(...)` deprecado en Flutter 3.27+** — Se renombró a `CardThemeData(...)`.

5. **Supabase Anon Key vs Secret Key** — El "Publishable" key (antes "anon key") es el que va en el cliente Flutter. El "Secret" key es equivalente al antiguo `service_role` y solo va en Edge Functions.

6. **`.env` como Flutter asset** — Si `.env` no existe en disco, `flutter test` falla con "No file or variants found for asset". Cada dev debe crear `.env` antes de correr tests.

7. **`dart:async` import en `app_router.dart`** — Estaba importado sin uso; el analizador lo rechaza con `very_good_analysis`.

8. **`tableName` reservado en Drift** — Si nombras una columna `tableName` en una `Table`, Drift lo interpreta como el override del nombre SQL de la tabla, no como columna. Renombrar a `tableKey` u otro nombre.

9. **Super-parámetros en DAOs de Drift** — `ProfileDao(super.db)` dispara el lint `matching_super_parameters` porque el parámetro del padre se llama `attachedDatabase`. Usar la forma explícita: `ProfileDao(AppDatabase db) : super(db);`

10. **`StreamProvider<T>` con repositorio que devuelve `Either`** — El `.watchProfile()` devuelve `Stream<Either<AppError, T>>`. En el `StreamProvider<T>` hay que mapear: `.map((r) => r.fold((e) => throw ..., (v) => v))`. Sin ese `.map`, el analizador lanza error de tipo.

11. **`sqlite3_flutter_libs: ^0.6.0+eol` no funciona en Android** — La versión `+eol` ("end of life") es un stub vacío que no empaqueta `libsqlite3.so` ni exporta `applyWorkaroundToOpenSqlite3OnOldAndroidVersions`. Usar `^0.5.0` en su lugar.

12. **`applyWorkaroundToOpenSqlite3OnOldAndroidVersions()` requerido en Android** — Llamar antes de inicializar `AppDatabase` en `main()` para que SQLite se cargue correctamente. Importar desde `package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart`.

13. **`StateNotifier` constructor fire-and-forget** — Llamar a `_load()` en el constructor de un `StateNotifier` sin `await` genera warning `discarded_futures`. Solución: `unawaited(_load())` con `import 'dart:async'`.

14. **`Stream.handleError` con retorno no emite datos** — `stream.handleError((e) => Left(err))` ignora el valor de retorno (es un `void` handler). Para convertir errores de stream en eventos `Left`, usar el patrón `async*` / `await for` con try-catch: `yield Left(...)` dentro del catch.

15. **`latlong2` — el archivo de librería es `latlong.dart`, no `latlong2.dart`** — El paquete se llama `latlong2` pero su archivo interno es `lib/latlong.dart`. El import correcto es `import 'package:latlong2/latlong.dart'`. Usar `latlong2/latlong2.dart` produce `uri_does_not_exist`.

---

## Crear usuario de prueba (Fase 1)

1. `supabase start`
2. Abrir Studio: `http://127.0.0.1:54323`
3. Authentication → Users → Add user:
   - Email: `12345@operadorapp.internal`
   - Password: 6+ caracteres
4. Copiar el UUID del usuario creado
5. SQL Editor → ejecutar:

```sql
INSERT INTO operadores (auth_user_id, numero_empleado, nombre_completo, fecha_ingreso)
VALUES ('<uuid>', '12345', 'Juan Demo', '2022-01-15');
```

---

## Para la siguiente sesión (Fase 8 — Notificaciones In-App + Preparación Push)

- [ ] `NotificationsScreen` — lista de notificaciones con indicador de no leídas
- [ ] Supabase Realtime conectado a `notificaciones_in_app` (tabla ya en BD + Realtime habilitado en migración)
- [ ] Banner overlay con `flutter_animate` (slide desde arriba, auto-dismiss 4s)
- [ ] Badge en `NavigationBar` actualizado en tiempo real (conteo de no leídas)
- [ ] `FcmNotificationService` implementado pero desactivado vía config (tabla `operador_devices` ya existe)
- [ ] Registrar FCM token en `operador_devices` al hacer login
- [ ] Ver `docs/NOTIFICATIONS.md` para diseño completo de push

Contexto importante para Fase 8:
- `notificaciones_in_app` ya tiene RLS (`notif_select_own`, `notif_update_own`) y Realtime habilitado
- `operador_devices` ya tiene RLS completo (select/insert/update/delete propios)
- El trigger `fn_acreditar_puntos_viaje` ya inserta notificaciones al acreditar puntos
- El trigger `fn_on_canje_aprobado` ya inserta notificación al aprobar canjes
- Falta: leer esas notificaciones en la app y mostrarlas como banners/pantalla

---

## Flujo de trabajo — responsabilidades del desarrollador

- **Tests**: El desarrollador los corre manualmente (`flutter test`) antes de cada commit.
- **Commits**: El desarrollador los hace siempre. Claude NO hace `git add`, `git commit` ni `git push`
bajo ninguna circunstancia, aunque se lo pidan.
- **Análisis**: El desarrollador corre `flutter analyze` cuando quiera verificar calidad.

Claude solo escribe y edita archivos. El ciclo build → test → commit es responsabilidad del
desarrollador.