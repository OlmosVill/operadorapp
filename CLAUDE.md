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
| DB local | drift (SQLite) | configurado, sin tablas aún (Fase 2) |
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
Completa. 15/15 tests pasando. App corre en emulador Android.

Archivos clave completados:
- `lib/main.dart` — inicialización completa (AppConfig → Supabase → SharedPrefs → ProviderScope)
- `lib/core/router/app_router.dart` — GoRouter con auth guard y ShellRoute (home/perfil/settings)
- `lib/features/auth/` — Login, ForgotPassword, providers, usecases, repositorio con Supabase
- `lib/features/profile/` — ProfileScreen con foto, nivel badge, barra de progreso, stats
- `lib/features/settings/` — SettingsScreen (tema, notificaciones, logout)
- `lib/features/trips/presentation/screens/home_screen.dart` — placeholder Fase 4

### 🔄 Próxima: Fase 2 — Offline-first con Drift
Sin empezar. Ver `docs/OFFLINE_STRATEGY.md` para diseño detallado.

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

8. **`StateNotifier` constructor fire-and-forget** — Llamar a `_load()` en el constructor de un `StateNotifier` sin `await` genera warning `discarded_futures`. Solución: `unawaited(_load())` con `import 'dart:async'`.

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

## Para la próxima sesión

- [ ] Confirmar que el login funciona end-to-end (email provider desbloqueado + usuario creado)
- [ ] Aprobar inicio de **Fase 2**: offline-first con Drift (tablas locales, sync con Supabase, operaciones pendientes)
- [ ] Fase 2 depende de: Drift setup, `database.dart`, modelos locales, sync providers
