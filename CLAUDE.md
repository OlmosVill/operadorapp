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

### ✅ Extra — Ranking entre Operadores
Construida fuera de orden (antes que Fase 8), a petición del usuario. No corresponde
a la "Fase 9" de `docs/ROADMAP.md` (esa es tests + CI/CD).

Tabla de posiciones entre todos los operadores activos, con nivel, calificación promedio
y movimiento de lugares (▲ n / ▼ n / — ) respecto al último corte.

Archivos clave:
- `supabase/migrations/20240101000004_ranking_operadores.sql` — tabla `ranking_snapshots`,
  RPC `fn_ranking_operadores(p_periodo)` (SECURITY DEFINER) y `fn_capturar_snapshot_ranking(p_periodo)`
- `supabase/seed.sql` — 6 operadores DEMO sin `auth_user_id` + snapshot de ayer para que las flechas tengan contenido
- `lib/core/database/tables.dart` — `RankingTable` (PK compuesta `{periodo, operadorId}`); `schemaVersion` → 3
- `lib/core/database/daos/ranking_dao.dart` — `watchByPeriodo`, `replacePeriodo` (borra+inserta, las posiciones se recorren)
- `lib/core/services/sync_service.dart` — `syncRanking(periodo)` vía `supabase.rpc`
- `lib/features/ranking/domain/entities/ranking_entry.dart` — `RankingEntry` (Freezed),
  `RankingPeriodo` (global/mensual), `RankingTrend` (subio/bajo/igual/nuevo)
- `lib/features/ranking/data/repositories/ranking_repository_impl.dart` — patrón `async*`/`await for`
- `lib/features/ranking/presentation/providers/ranking_provider.dart` — `rankingProvider`,
  `rankingPeriodoProvider` (StateProvider legacy), `myRankingEntryProvider`
- `lib/features/ranking/presentation/screens/ranking_screen.dart` — podio top-3, tabla, barra fija "Tu lugar"
- `lib/features/ranking/presentation/widgets/rank_change_indicator.dart` — la flecha ▲ n / ▼ n / —
- `lib/core/router/app_router.dart` — ruta `/ranking` standalone
- Accesos: ícono de leaderboard en el AppBar de Home y de `PointsScreen`

**Pendiente operativo**: programar `SELECT fn_capturar_snapshot_ranking('global');` y `('mensual')`
una vez al día (pg_cron o job externo con la service key). Sin el snapshot diario todos los
operadores muestran guion, porque no hay corte previo contra el cual comparar.

### ✅ Extra — Resumen de Regreso (popup animado)
**Verificado en emulador el 2026-08-06: el popup sale correctamente.**

Cuando el operador vuelve a abrir la app después de que se le cerraron viajes, un popup le
resume qué pasó: puntos ganados con contador animado, viajes completados, lugares que subió
o bajó en el ranking, y la barra de nivel llenándose desde donde estaba.

Si hubo cambio de nivel la barra corre en **dos fases**: llena la del nivel viejo hasta el
tope, cambia badge y color, y arranca de cero en el nuevo. Con una sola animación se vería
como si el progreso hubiera retrocedido.

Archivos clave:
- `lib/features/profile/domain/entities/level_thresholds.dart` — umbrales compartidos
  (`levelProgress`, `nextLevelPoints`, `levelForPoints`)
- `lib/features/summary/domain/entities/return_summary.dart` — `ReturnSummary` (Freezed)
  con `pointsEarned`, `rankDelta`, `leveledUp`, `hasContent`
- `lib/features/summary/data/datasources/return_snapshot_store.dart` — snapshot en SharedPreferences
- `lib/features/summary/presentation/providers/return_summary_provider.dart` —
  `returnSummaryProvider`, `returnSummaryShownProvider`, `saveReturnSnapshot`
- `lib/features/summary/presentation/widgets/return_summary_dialog.dart` — el popup
- `lib/features/trips/presentation/screens/home_screen.dart` — guarda el snapshot al pausar,
  y al volver del segundo plano rearma el resumen y vuelve a revisar (`_handleResume`)
- `lib/core/providers/app_refresh.dart` — `refreshFromServer`, la sincronización manual del
  regreso (perfil, viajes, movimientos, ranking)

**Cómo decide qué mostrar**: compara contra el snapshot guardado al cerrar la app (puntos
acumulados, nivel, posición), no contra una ventana de tiempo fija. Da igual si estuvo fuera
dos horas o dos semanas, o si se le juntaron varios viajes.

**Funciona igual matando la app que volviendo del segundo plano.** El regreso desde segundo
plano necesita tres cosas que no pasan solas, y por eso `_handleResume` las hace a mano:

1. `ReturnSnapshotStore.rotate()` — el punto de comparación se captura una sola vez, al
   construir el store. Sin rotarlo, al volver se seguiría comparando contra el arranque en
   frío. Rota desde `_latest` (memoria), no releyendo SharedPreferences, porque entre el
   `paused` y el `resumed` puede pasar menos de lo que tarda la escritura en disco.
2. `refreshFromServer` — cada repositorio sincroniza al ABRIR su stream de Drift, una sola
   vez. Al volver del segundo plano esos streams siguen vivos, así que nadie le vuelve a
   preguntar a Supabase y el viaje cerrado no aparece nunca.
3. Rearmar `returnSummaryShownProvider` y `_summaryHandled` — si no, la bandera de "ya se
   mostró en esta sesión" bloquea el popup hasta que se mate la app.

Lo que trae la sincronización llega asíncrono, así que el popup puede no salir en el mismo
`resumed`: el `_scheduleSummaryCheck` de cada build lo reintenta cuando Drift emite.

**Se muestra una sola vez por regreso** (`returnSummaryShownProvider`) y sólo si hay algo que
contar (`hasContent`). El snapshot se reescribe al cerrar el popup y al pasar a segundo plano.

**Cómo forzarlo para probar** (requiere el admin en `localhost:4321` y `supabase start`):
1. Abrir la app y mandarla a segundo plano con el botón home — ahí se guarda el snapshot.
   Si se mata la app a la fuerza el snapshot no se guarda y el resumen compara contra un
   punto más viejo: sigue saliendo, pero con más cosas de las esperadas.
2. En el admin: Viajes → Nuevo viaje, elegir el operador `12345`, crear y luego "Cerrar viaje".
3. Volver a la app — sirve tanto reabrirla desde el multitarea como matarla y arrancarla.

Pendientes menores de esta feature (nada bloqueante):
- `HomeStateReturning` en `home_provider.dart` quedó como código muerto: el popup cubre mejor
  ese caso. Está intacto por si se quiere reutilizar la vista; si no, se puede retirar junto
  con `updateHomLastSeen` y la clave `home_last_seen_ms`.
- El popup no muestra canjes ni notificaciones recibidas durante la ausencia. Se puede sumar
  cuando exista la Fase 8.

### 🔄 En curso — Rediseño Modernist (export de Claude Design)

**Las 8 vistas del export están portadas**, cada una en claro y oscuro: Inicio
(con viaje y sin viaje), Viajes, Detalle Viaje, Perfil Operador, Premios Ruta,
Ranking y el popup de Resumen de Regreso.

**Configuración** también está en el sistema, aunque no tiene export: se compuso
con las piezas existentes y se llega por el **engrane del perfil**. Con eso
desapareció el `ShellRoute` de Material y `AppBottomNav`; toda pantalla trae su
barra.

**Las cuatro pestañas se deslizan.** Viven en un `StatefulShellRoute` que no
dibuja chrome —cada pantalla conserva su `ModernistTabBar`— y cuyo contenedor,
`ModernistTabShell`, pone las ramas en una tira horizontal: Viajes entra desde
la derecha viniendo de Inicio y desde la izquierda viniendo de Premios. Arrastrar
desde cualquiera de los dos bordes mueve la tira con el dedo y cambia de pestaña
al soltar. Ranking sigue apilándose encima, como el detalle de viaje o Ajustes,
y esas pantallas entran desde la derecha con `modernistPage()`.

Las pantallas viejas siguen en el repo sin usarse; conviene retirarlas en un
commit aparte una vez validado todo en emulador.

Los fuentes están en `Operator_app_design_brief/` — un `.dc.html` por vista y
por tema. Usar esos, no el `.html` «offline» de 1.1 MB del botón de descarga.

Ver `docs/features/modernist-home.md` — cómo leer los exports, las decisiones
que conviene repetir y la lista de pendientes.

Archivos clave:
- `assets/fonts/Archivo.ttf` — fuente variable; declarada en `pubspec.yaml`
- `lib/core/theme/modernist/modernist_tokens.dart` — `ModernistPalette` (claro/oscuro), tipografía y helpers
- `lib/core/theme/modernist/modernist_icons.dart` — íconos pintados (Archivo no trae símbolos)
- `lib/features/*/presentation/screens/modernist/` — una carpeta por feature
- `lib/features/trips/presentation/widgets/modernist/` — `truck_scene`, `dock_scene`, los dos mapas ilustrados y `modernist_tab_bar`
- `lib/core/router/app_router.dart` — shell de 4 ramas (`modernistBranchTabs`) + rutas apiladas
- `lib/core/router/modernist_tab_shell.dart` — la tira que desliza y sigue al dedo desde los bordes
- `lib/core/router/modernist_transitions.dart` — `modernistPage()`, entrada desde la derecha
- `test/core/router/modernist_tab_shell_test.dart` — sentido del deslizamiento y arrastre
- `lib/shared/widgets/app_bottom_nav.dart` — nav anterior, solo para Ajustes
- `test/features/*/modernist/` — goldens 412×880, un par claro/oscuro por vista
- `test/features/trips/modernist/modernist_golden_harness.dart` — montaje común de los goldens

**La escena del tracto reemplaza el plan de Rive**: el export ya trae la máquina
de estados completa en CSS/SVG, así que se portó a `CustomPaint` y ya no hace
falta el `.riv` del animador. `docs/features/truck-animation.md` queda como
referencia de la telemetría, no de la animación.

**La escena no depende del tema**, solo de `horaDelDia`: los exports claro y
oscuro la declaran idéntica y el oscuro simplemente arranca a las 21:00.

### 🔄 Próxima: Fase 8 — Notificaciones In-App + Preparación Push
Ver `docs/ROADMAP.md`.

---

## Proyecto hermano — `operadorapp-admin`

Panel admin en Astro + React (`D:\dev\operadorapp-admin`) que comparte esta misma BD Supabase local.
Sirve para sembrar escenarios completos y simular operaciones (cerrar viajes, aprobar canjes, ajustar puntos).

| Concepto | Dónde vive |
|---|---|
| Migraciones, `seed.sql`, Edge Functions | Este repo (fuente de verdad) |
| `docs/DATABASE.md` | Este repo; el admin tiene una copia de referencia que no se edita allí |
| Tipos TypeScript del admin | `src/types/database.ts` — regenerar con `npm run gen:types` |

**Al cambiar el esquema hay que actualizar el admin**: regenerar tipos y revisar el seeder,
el truncado y export/import, que enumeran tablas explícitamente.

El truncado del admin **preserva el operador `12345`** (el login de la app). Sin esa excepción,
cada truncado dejaba la sesión cacheada apuntando a un operador inexistente y había que correr
`supabase db reset` para volver a entrar.

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

16. **`auth_user_id` ≠ `operadores.id`** — `OperatorSession.operatorId` guarda el UUID de Supabase Auth (`auth_user_id`). Las FKs de `viajes`, `movimientos_puntos`, `historial_tractos_operador` y demás tablas referencian `operadores.id` (el PK propio de la tabla). Nunca pasar `authStateProvider.value?.operatorId` a queries o sync que involucren esas tablas. Siempre usar `profileProvider.value?.id`.

17. **RLS impide leer otros operadores** — `operador_select_own` restringe `operadores` a la fila
propia, así que cualquier pantalla comparativa (ranking, promedios de flota) necesita una función
`SECURITY DEFINER` que exponga solo las columnas públicas. Nunca aflojar la policy para lograrlo.

18. **El delta de posiciones no se calcula en el cliente** — Si cada dispositivo comparara contra
su propia caché, dos operadores verían flechas distintas para el mismo movimiento. El servidor
compara contra `ranking_snapshots` (último corte anterior a hoy) y devuelve `posicion_anterior`.

19. **El nivel lo define `puntos_ganados`, no `puntos_disponibles`** — `fn_actualizar_puntos_operador()`
calcula el nivel con el acumulado histórico. Cualquier barra de progreso debe usar
`OperatorProfile.totalPoints`; con `availablePoints` un canje hace "bajar de nivel" en la UI
mientras el servidor mantiene el nivel. Umbrales compartidos en `level_thresholds.dart`.

20. **Escribir un timestamp en `initState` antes de leerlo lo deja inservible** —
`updateHomLastSeen` guardaba "ahora" en `initState`, y `homeStateProvider` leía ese mismo valor
al construir: la diferencia daba siempre 0 y `HomeStateReturning` nunca se activaba. El
`ReturnSnapshotStore` evita la trampa capturando el valor anterior una sola vez, al construirse.

21. **`format()` de PostgreSQL no acepta especificadores printf** — Solo entiende `%s`, `%I`,
`%L` y `%%`. Un `%.1f` falla con *unrecognized format() type specifier "."*. El redondeo va
fuera: `format('%s km', ROUND(v_km))`. Este bug en `fn_calcular_puntos_viaje()` hacía abortar
CUALQUIER `UPDATE viajes SET estado='completado'`, así que el ciclo viaje completado → puntos
→ notificación nunca llegó a correr. Corregido en `20240101000005`.

22. **Escribir en un provider dentro de `build()` revienta la pantalla** — Riverpod aborta el
build si se modifica estado mientras se construye el árbol, y en la app se veía como un flash
rojo que desaparecía solo (al siguiente build la bandera ya estaba puesta y no se reescribía).
Todo lo que mute estado va en `addPostFrameCallback`, nunca en `build`.

23. **Repositorios que no disparan sync quedan con tablas locales vacías** — Cualquier `XxxRepositoryImpl` que solo lea de Drift sin llamar al `SyncService` correspondiente mostrará datos vacíos aunque Supabase tenga registros. El patrón correcto al inicio de cada stream watch es `unawaited(_sync.syncXxx(operadorId))`, igual que `TripsRepositoryImpl`. Afectó a `PointsRepositoryImpl`, `RewardsRepositoryImpl` y `TrucksRepositoryImpl`.

24. **Flutter no instancia el eje `wght` de una fuente variable desde el pubspec** —
Declarar `Archivo.ttf` con `weight:` no basta: sin
`fontVariations: [FontVariation('wght', n)]` en el `TextStyle`, todos los pesos
salen en 400. Por eso todo texto Modernist pasa por `ModernistType.of()`.

25. **`DecoratedBox` pinta detrás del hijo** — Las secciones que dibujan a
sangre (la escena, el mapa) tapan la regla de 2 px si va como decoración de
fondo. Necesita `position: DecorationPosition.foreground`.

26. **En los exports de Claude Design hay texto que hereda el color de `<a>`** —
El chip de nivel de la cabecera es un enlace, y la hoja del sistema define
`a { color:#8f0000 }` en claro y `#ff8a8a` en oscuro. El span del nombre del
nivel no declara color, así que «ORO» va en rojo y no en tinta. Antes de portar
un texto sin `color`, revisar de quién hereda — para eso existe
`ModernistPalette.link`.

27. **Archivo no trae `▲ ▼ ★`** — En Android los cubre el respaldo del sistema,
pero en los goldens salen como cuadros. En `ranking_screen.dart` van pintados
con `CustomPaint`. Comprobar que la fuente tenga el glifo antes de portarlo.

28. **`DateFormat` interpreta las letras del patrón, también dentro de una
palabra** — `'d de MMMM'` imprime «6 6e agosto» porque la `e` es el día de la
semana. El texto literal va entre comillas simples *dentro* del patrón:
`DateFormat("d 'de' MMMM", 'es_MX')`.

29. **Un `AnimationController` en `late final` que solo se usa a veces truena al
desmontar** — Si `build` no lo toca en algún estado, `dispose()` acaba
*construyéndolo* durante la finalización del árbol y el test falla. Crearlos
siempre en `initState`.

30. **Un `Stack` con puros hijos `Positioned` no tiene altura** — Falla con
`size.isFinite` salvo que algo de fuera le imponga una altura definida. Si el
`Stack` solo dibuja rieles o líneas, darle un hijo sin posicionar o cambiarlo
por `Padding` + `Align`.

31. **Un sync que solo inserta deja huérfanos que rompen el canje** —
`supabase db reset` regenera los `id` del catálogo, y como `syncCatalogo()`
hacía upsert incremental por `updated_at` sin borrar nada, Drift acumulaba el
catálogo de cada base anterior: cada premio salía dos veces y el de arriba
llevaba un `id` que el servidor ya no conoce. Canjearlo devolvía 404 «Premio no
encontrado o inactivo». Un premio dado de baja tampoco desaparecía nunca,
porque la consulta filtra `activo = true`. Las tablas que el servidor manda
enteras se reemplazan: `replaceCatalogo`, `replaceCanjes`, `replaceMovimientos`,
`replaceViajes`, `replaceTractos`, `replaceHistorial`, `replaceReportesByOperador`
y `replaceProfile`. Ningún `syncXxx` quedó solo-inserción. Cuatro cosas que
aprendimos al extender el barrido a todas:
   - **Ojo con `NOT IN ()`**, que no es SQL válido. Si el servidor no devolvió nada hay que borrar
     todo (acotado por operador), no armar el `isNotIn` con una lista vacía.
   - **El reemplazo obliga a descarga completa.** Un corte incremental por `updated_at` nunca trae
     las filas borradas, así que no hay con qué podar; peor, borraría todo lo que no cambió desde
     el último sync. Por eso `syncTrips`, `syncCatalogo`, `syncMovimientos`, `syncTractos` y
     `syncHistorialTractos` dejaron de usar cursor.
   - **Las tablas hijas se barren por su padre, sin lista de ids.** El servidor devuelve el set
     completo del viaje, así que `replaceGpsPoints`/`replaceIncidencias`/`replaceAlertas`/
     `replaceReportesByViaje` borran la rebanada entera y reinsertan: un viaje puede traer miles
     de puntos GPS y drift bindea una variable por id (`SQLITE_MAX_VARIABLE_NUMBER`).
   - **Drift no declara FKs, así que no hay ON DELETE CASCADE.** `TripsDao.replaceViajes`
     borra a mano los puntos GPS, incidencias y alertas de los viajes que desaparecieron; sin eso
     quedan como basura invisible que nadie vuelve a leer. Y `replaceProfile` borra los perfiles
     de otros `auth_user_id`, que cada reset regenera — ojo si algún día un dispositivo alterna
     operadores.

32. **`functions.invoke` lanza, no devuelve el status** — En
`functions_client` ≥ 2.x cualquier respuesta fuera de 2xx sale como
`FunctionException`; el `if (result.status != 200)` que había en
`RewardsRemoteDatasource` era código muerto y el motivo del servidor se perdía.
El cuerpo viene en `e.details['error']`. Además, un repositorio que atrapa solo
`on Exception` deja escapar los `Error` de parseo, y la pantalla se queda
colgada en «ENVIANDO…» porque el `await` nunca vuelve: usar `on Object`.

33. **`reportes` no tiene columnas `lat`/`lng`, tiene `coordenada` GEOGRAPHY** —
`_syncReportes` armaba su companion con `r['lat']`/`r['lng']` (siempre null) y
pisaba las coordenadas que el sync por operador sí parseaba con
`_parseGeography`. Cualquier lectura de `reportes` desde Supabase debe pasar por
`_reporteCompanion`.

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

### Dónde quedó todo (última sesión: 2026-08-06)

Estado verificado end-to-end: `flutter analyze` en 0 issues, **68 tests pasando**, BD local
sembrada y app corriendo en emulador.

| Área | Estado |
|---|---|
| Ranking entre operadores | Funcionando, con flechas ▲/▼/— |
| Resumen de regreso | Funcionando, verificado en emulador |
| Cerrar viaje desde el admin | Funcionando; acredita puntos y genera notificación |
| Migraciones | 6 archivos, la última es `20240101000005` |

Sin trabajo a medias. Se puede arrancar Fase 8 en limpio.

**Cuenta de prueba**: `12345` / `123456`. La crea `seed.sql`, sobrevive al truncado del admin
y se recrea en cada `supabase db reset`.

**Ojo con el estado de la BD local**: el operador `12345` quedó en nivel **oro** con ~5589
puntos ganados tras las pruebas de cierre de viajes. Si se quiere un punto de partida limpio,
`supabase db reset`.

**Pendiente operativo, no de código**: programar `fn_capturar_snapshot_ranking('global')` y
`('mensual')` una vez al día en producción (pg_cron o job externo con la service key). En local
el seed ya deja un corte de ayer, por eso se ven flechas.

### Trabajo de Fase 8

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

**Ya hay notificaciones reales que leer**: la BD local tiene 12 sin leer, generadas por los
triggers al cerrar viajes desde el admin. Sirven para probar la pantalla sin sembrar a mano:
```sql
SELECT titulo, cuerpo, leida FROM notificaciones_in_app ORDER BY created_at DESC;
```

La tabla usa `cuerpo`, no `mensaje` — la tabla Drift `NotificacionesTable` la mapea como
`mensaje`, hay que respetar esa diferencia al escribir el sync. `lib/features/notifications/`
ya existe con la estructura de carpetas vacía (solo `.gitkeep`).

---

## Flujo de trabajo — responsabilidades del desarrollador

- **Tests**: El desarrollador los corre manualmente (`flutter test`) antes de cada commit.
- **Commits**: El desarrollador los hace siempre. Claude NO hace `git add`, `git commit` ni `git push`
bajo ninguna circunstancia, aunque se lo pidan.
- **Análisis**: El desarrollador corre `flutter analyze` cuando quiera verificar calidad.

Claude solo escribe y edita archivos. El ciclo build → test → commit es responsabilidad del
desarrollador.