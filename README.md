# OperadorApp

Aplicación móvil para operadores de tractocamiones. Consulta de estadísticas, historial de viajes,
sistema de puntos gamificado y catálogo de premios. Desarrollada con Flutter + Supabase.

---

## Requisitos

| Herramienta | Versión mínima | Notas |
|-------------|----------------|-------|
| Flutter | 3.22+ | `flutter --version` |
| Dart | 3.3+ | Incluido con Flutter |
| Docker Desktop | 4.x | Necesario para Supabase local |
| Supabase CLI | 1.x | `brew install supabase/tap/supabase` (Mac) o [instalador](https://github.com/supabase/cli) |
| Android SDK | API 21+ | Para compilar Android |
| Xcode 15+ | — | Solo en macOS, para compilar iOS |

---

## Primeros pasos

### 1. Clonar e instalar dependencias

```bash
git clone <repo-url> operadorapp
cd operadorapp
flutter pub get
```

### 2. Configurar variables de entorno

```bash
cp .env.example .env
# Editar .env con tus valores (ver sección Variables de entorno abajo)
```

### 3. Levantar Supabase local

```bash
supabase start
# Primera vez: descarga imágenes Docker (~2 GB). Tarda unos minutos.
# Imprime las URLs y keys locales al terminar.
```

### 4. Aplicar migraciones y datos de ejemplo

```bash
supabase db reset
# Aplica: supabase/migrations/*.sql + supabase/seed.sql
```

### 5. Generar código (Freezed, Drift, Riverpod, JSON)

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 6. Correr la app

```bash
# Android (emulador o dispositivo)
flutter run

# Con dispositivo específico
flutter run -d <device-id>

# Listar dispositivos disponibles
flutter devices
```

---

## Variables de entorno (`.env`)

| Variable | Descripción | Ejemplo |
|----------|-------------|---------|
| `SUPABASE_URL` | URL de Supabase (local o producción) | `http://localhost:54321` |
| `SUPABASE_ANON_KEY` | Clave pública anónima de Supabase | `eyJ...` |
| `MAP_PROVIDER` | Implementación de mapas a usar | `osm` (dev) / `google` (prod) |
| `GOOGLE_MAPS_API_KEY` | API Key de Google Maps | Solo si `MAP_PROVIDER=google` |

> **Nunca** comitear `.env` al repositorio. Está en `.gitignore`.

Para obtener los valores de Supabase local, busca la salida de `supabase start`:
```
API URL: http://localhost:54321
anon key: eyJ...
```

---

## Comandos útiles

```bash
# --- Flutter ---

# Generar código (Freezed, Drift, Riverpod, JSON)
dart run build_runner build --delete-conflicting-outputs

# Regenerar en modo watch (durante desarrollo)
dart run build_runner watch --delete-conflicting-outputs

# Tests unitarios
flutter test

# Tests de integración (requiere emulador/dispositivo)
flutter test integration_test/

# Análisis estático
flutter analyze

# Formatear código
dart format .

# Build APK de release
flutter build apk --release

# Build App Bundle (Google Play)
flutter build appbundle --release

# Limpiar build
flutter clean && flutter pub get


# --- Supabase ---

# Iniciar Supabase local
supabase start

# Ver estado de servicios
supabase status

# Parar Supabase local
supabase stop

# Resetear BD (aplica migrations + seed desde cero)
supabase db reset

# Abrir Supabase Studio (interfaz web local)
# → http://localhost:54323

# Ver logs
supabase logs

# Crear nueva migración
supabase migration new <nombre_migracion>

# Aplicar migraciones pendientes
supabase db push


# --- Git / Calidad ---

# Verificar que lefthook está activo
lefthook run pre-commit

# Ver cobertura de tests
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
# Abrir coverage/html/index.html
```

---

## Estructura del proyecto

```
operadorapp/
├── lib/
│   ├── core/
│   │   ├── constants/       # AppConstants, AppStrings
│   │   ├── theme/           # AppTheme, colores, tipografía
│   │   ├── utils/           # Helpers, formatters
│   │   ├── errors/          # AppError sealed class
│   │   ├── network/         # DioClient, interceptors
│   │   └── services/        # NotificationService, SyncService
│   ├── features/
│   │   ├── auth/            # Login, logout, recuperar contraseña
│   │   ├── profile/         # Perfil, nivel, estadísticas vitalicias
│   │   ├── trips/           # Historial de viajes + detalle con mapa
│   │   ├── rewards/         # Roadmap de premios + flujo de canje
│   │   ├── trucks/          # Historial de tractos manejados
│   │   ├── notifications/   # Notificaciones in-app
│   │   └── settings/        # Tema, idioma, logout
│   └── shared/
│       └── widgets/         # Widgets reutilizables entre features
├── test/                    # Tests unitarios y de widget
├── integration_test/        # Tests de integración (dispositivo real)
├── docs/                    # Documentación de arquitectura y decisiones
├── supabase/
│   ├── migrations/          # Scripts SQL versionados
│   ├── functions/           # Edge Functions (Deno/TypeScript)
│   └── seed.sql             # Datos de ejemplo para desarrollo
├── assets/
│   ├── animations/          # Archivos .riv y .json (Lottie)
│   ├── images/              # Imágenes estáticas
│   └── fonts/               # Tipografías (Montserrat u otra)
└── .github/
    └── workflows/
        └── ci.yml           # Pipeline CI: lint + test + build Android
```

---

## Documentación

| Documento | Descripción |
|-----------|-------------|
| [ARCHITECTURE.md](docs/ARCHITECTURE.md) | Clean Architecture, diagramas, decisiones técnicas |
| [DATABASE.md](docs/DATABASE.md) | Esquema PostgreSQL completo + script SQL |
| [OFFLINE_STRATEGY.md](docs/OFFLINE_STRATEGY.md) | Estrategia offline-first con Drift |
| [NOTIFICATIONS.md](docs/NOTIFICATIONS.md) | Notificaciones in-app y push |
| [ROADMAP.md](docs/ROADMAP.md) | Plan de desarrollo por fases |
| [STACK.md](docs/STACK.md) | Justificación de cada paquete |

---

## Convención de commits

```
feat:     nueva funcionalidad
fix:      corrección de bug
chore:    tareas de mantenimiento (deps, config, build)
docs:     cambios en documentación
test:     agregar o corregir tests
refactor: refactoring sin cambio de comportamiento
style:    formato, espacios, sin cambio de lógica
perf:     mejora de rendimiento
```

Ejemplo: `feat(auth): agregar recuperación de contraseña vía correo`

---

## Estado del proyecto

- **Fase 0** — Planificación ✅
- **Fase 1** — Setup + Auth + Perfil + Temas 🔄
- Ver [ROADMAP.md](docs/ROADMAP.md) para el plan completo
