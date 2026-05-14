# Roadmap de Desarrollo — OperadorApp

## Convenciones

- Cada fase se aprueba antes de iniciar la siguiente
- Cada feature incluye tests unitarios y de integración mínimos
- Los PRs siguen Conventional Commits (`feat:`, `fix:`, `chore:`, `docs:`, `test:`)
- Al cerrar cada fase: `git tag vX.Y.0`

---

## Fase 0 — Planificación y Setup de Documentación ✅

**Objetivo:** Acordar arquitectura, esquema de BD y decisiones técnicas antes de tocar código.

- [x] `docs/ARCHITECTURE.md` — diagramas de Clean Architecture y flujo de datos
- [x] `docs/DATABASE.md` — esquema PostgreSQL completo + script SQL
- [x] `docs/OFFLINE_STRATEGY.md` — estrategia offline-first con Drift
- [x] `docs/NOTIFICATIONS.md` — diseño de notificaciones in-app y push
- [x] `docs/ROADMAP.md` — este documento
- [x] `docs/STACK.md` — justificación de cada paquete
- [x] `README.md` — setup del proyecto
- [x] Estructura de carpetas Clean Architecture
- [x] Archivos de configuración base (pubspec, analysis, CI, docker, etc.)

**Criterio de salida:** El desarrollador puede leer estos docs y entender el sistema completo
antes de ver una sola línea de código Dart.

---

## Fase 1 — Setup + Autenticación + Perfil básico + Temas

**Objetivo:** App funcional con login real, perfil visible y soporte de tema oscuro/claro.

### Setup base
- [ ] `pubspec.yaml` con todas las dependencias instaladas y sin conflictos
- [ ] Configurar `AppConfig` con `.env` (Supabase URL, API key, map provider)
- [ ] `AppTheme` con paleta completa (claro + oscuro): naranja/ámbar, negro, grises asfalto
- [ ] `AppRouter` con GoRouter: rutas `/login`, `/home`, `/profile`, `/settings`
- [ ] `main.dart` inicializando Supabase, Drift y providers

### Autenticación
- [ ] `LoginScreen` — número de empleado + contraseña, validación de formulario
- [ ] `AuthRepository` con `login()`, `logout()`, `currentSession()`
- [ ] Persistencia de sesión con `flutter_secure_storage`
- [ ] Guard de autenticación en GoRouter (redirect si no autenticado)
- [ ] Pantalla de recuperación de contraseña
- [ ] Funciona offline si sesión activa está cacheada

### Perfil básico
- [ ] `ProfileScreen` — foto, nombre, número de empleado, antigüedad, base
- [ ] Badge de nivel con textura visual (Plata inicial)
- [ ] Barra de progreso al siguiente nivel (animada)
- [ ] Carga de foto desde Supabase Storage con `cached_network_image`

### Configuración
- [ ] `SettingsScreen` — toggle tema claro/oscuro/sistema
- [ ] Persistencia del tema en `SharedPreferences`
- [ ] Botón de cerrar sesión

### Tests Fase 1
- [ ] `AuthUseCaseTest` — login correcto, credenciales inválidas, sin red
- [ ] `ProfileRepositoryTest` — carga de perfil, manejo de error 404
- [ ] `ThemeTest` — cambio de tema persiste entre reinicios

**Commit final:** `feat: fase 1 completa — auth + perfil + temas`

---

## Fase 2 — Drift Local + Sincronización Supabase + Repositorios

**Objetivo:** Infraestructura offline-first funcional. La app opera sin red y sincroniza cuando vuelve la conexión.

- [ ] Definir esquema Drift completo (ver `docs/OFFLINE_STRATEGY.md`)
- [ ] Implementar `SyncService` — pull/push con Supabase en background
- [ ] `ConnectivityService` con `connectivity_plus` y streams reactivos
- [ ] `PendingOpsQueue` — tabla Drift + procesador FIFO
- [ ] Repositorios completos: Auth, Profile, Trips, Rewards, Trucks
- [ ] Indicador de sincronización en Settings (n cambios pendientes)
- [ ] Tests de repositorios con base de datos Drift en memoria

**Commit final:** `feat: fase 2 completa — offline-first con Drift + sync Supabase`

---

## Fase 3 — Historial de Viajes + Detalle con Mapa

**Objetivo:** El operador puede ver todos sus viajes pasados con detalles completos, incluso sin red.

- [ ] `TripsListScreen` — lista paginada desde Drift, con pull-to-refresh
- [ ] `TripDetailScreen` — estadísticas, calificación, puntos obtenidos
- [ ] `TripMapView` — polyline desde `viaje_puntos_gps`, ambas implementaciones de mapa
- [ ] `MapAdapter` interface + `GoogleMapsAdapter` + `OpenStreetMapAdapter`
- [ ] Switch de implementación de mapa vía `AppConfig.mapProvider`
- [ ] Lista de incidencias del viaje
- [ ] Lista de alertas de seguridad (frenos bruscos, aceleraciones, velocidad)
- [ ] Reportes asociados al viaje
- [ ] Sincronización incremental: solo descarga viajes nuevos/modificados

**Commit final:** `feat: fase 3 completa — historial de viajes + mapa con adapter`

---

## Fase 4 — Home Dinámico + Animaciones de Viaje Activo

**Objetivo:** La pantalla principal es la más impactante de la app. Cambia según el estado del operador.

- [ ] `HomeProvider` — detecta caso A, B o C en tiempo real
- [ ] **Caso A (viaje activo):**
  - [ ] Animación tracto en movimiento (Rive/Lottie)
  - [ ] Si reporte de mantenimiento abierto → animación mecánico
  - [ ] Si reporte de choque → animación tracto dañado
  - [ ] Mapa mini con ruta en curso
  - [ ] Barra de progreso origen→destino
  - [ ] ETA, km recorridos, rendimiento parcial
- [ ] **Caso B (regresó después de tiempo):**
  - [ ] Animación de bienvenida
  - [ ] Resumen de últimos 3 viajes
  - [ ] Puntos ganados recientemente
  - [ ] Próxima ruta asignada
- [ ] **Caso C (uso frecuente):**
  - [ ] Dashboard con cards de acceso rápido
  - [ ] Estadísticas del mes actual
  - [ ] Balance de puntos

**Commit final:** `feat: fase 4 completa — home dinámico + animaciones`

---

## Fase 5.1 — Sistema de Puntos + Niveles de Operador ✅

**Objetivo:** El operador ve su balance, historial de puntos y progreso de nivel gamificado.

- [x] `PointsScreen` — balance actual, movimientos recientes
- [x] Historial paginado de `movimientos_puntos` (stream reactivo offline-first)
- [x] Barra de progreso de nivel con umbrales reales del seed
- [x] Edge Function `calcular-puntos-viaje` (Deno) probada e integrada
- [x] Trigger SQL `trg_viaje_completado` que dispara el cálculo al cerrar viaje
- [x] `PointsDao` + `syncMovimientos` en SyncService
- [x] `_PointsBalanceCard` en Home tappable → navega a `/points`
- [x] 24/24 tests pasando · 0 issues en `flutter analyze`

**Commit final:** `feat: fase 5.1 completa — sistema de puntos + pantalla de historial`

---

## Fase 5.2 — Catálogo y Canje de Premios ✅

**Objetivo:** El operador navega el catálogo de premios y puede canjear sus puntos.

- [x] Sincronizar `premios_catalogo` en SyncService → `PremiosCatalogoTable` local
- [x] `RewardsRepository` + `GetPremiosUsecase` + `CanjearUsecase` (vía Edge Function)
- [x] `RewardsScreen` — catálogo con filtros (Todos/Disponibles/Mis Canjes)
- [x] Integrar pestaña Premios en ShellRoute (índice 2, Settings al 3; Perfil fuera del nav bar)
- [x] Historial de canjes en `PremiosCanjeadosTable`
- [x] Edge Function `canjear-premio` (Deno) — valida puntos, nivel y stock
- [x] 29/29 tests pasando · 0 issues en `flutter analyze`

**Commit final:** `feat: fase 5.2 completa — catálogo de premios + canje`

---

## Fase 6 — Roadmap de Premios ✅

**Objetivo:** Timeline visual de premios como hitos con animaciones por categoría.

- [x] `RewardsRoadmapScreen` — timeline vertical scrolleable con filtro por nivel
- [x] Cada premio como "hito": nodo coloreado por tipo, barra de progreso, pts restantes
- [x] Nodo pulsante para el próximo objetivo del operador (`isTarget`)
- [x] Animación de entrada por tipo: `tarjetaRegalo` (verde), `producto` (azul), `experiencia` (morado), `vehiculo` (ámbar), `otro` (gris)
- [x] Filtro por nivel requerido (chips horizontales + "Todos")
- [x] Botón "Canjear" en hitos alcanzados → abre `CanjeSheet`
- [x] Accesible desde `RewardsScreen` vía ícono de mapa en AppBar → `/rewards/roadmap`
- [x] `RedeemConfirmationSheet` → ya existía como `CanjeSheet` (5.2) ✅
- [x] Edge Function `canjear-premio` → ya existía (5.2) ✅
- [x] Historial de canjes → ya existía como tab "Mis Canjes" (5.2) ✅
- [ ] Notificación in-app al cambiar estado del canje → movido a Fase 8

**Commit final:** `feat: fase 6 completa — roadmap de premios`

---

## Fase 7 — Historial de Tractos

**Objetivo:** El operador ve cada tracto que ha manejado y sus stats por unidad.

- [ ] `TrucksHistoryScreen` — lista de tractos con resumen visual
- [ ] `TruckDetailScreen` — km totales, viajes, calificación promedio
- [ ] Reportes positivos y negativos por tracto
- [ ] Comparativa de rendimiento por tracto (gráfica simple)

**Commit final:** `feat: fase 7 completa — historial de tractos`

---

## Fase 8 — Notificaciones In-App + Preparación Push

**Objetivo:** Notificaciones en tiempo real dentro de la app; infraestructura push lista para activar.

- [ ] `NotificationsScreen` — lista de notificaciones con indicador de no leídas
- [ ] Supabase Realtime conectado a `notificaciones_in_app`
- [ ] Banner overlay con `flutter_animate` (slide desde arriba, auto-dismiss 4s)
- [ ] Badge en NavigationBar actualizado en tiempo real
- [ ] `FcmNotificationService` implementado pero desactivado vía config
- [ ] Tabla `operador_devices` con registro de FCM token al login
- [ ] Documentación de pasos para activar push (ver `docs/NOTIFICATIONS.md`)

**Commit final:** `feat: fase 8 completa — notificaciones in-app + infraestructura push`

---

## Fase 9 — Testing Exhaustivo + CI/CD

**Objetivo:** Cobertura de tests adecuada y pipeline automatizado.

- [ ] Tests unitarios ≥ 80% cobertura en `domain/` y `data/`
- [ ] Tests de integración: flujo login→home→detalle viaje→canje
- [ ] Tests de widget para pantallas críticas
- [ ] GitHub Actions: lint + test + build APK en cada PR a `main`
- [ ] Codemagic configurado para iOS (pendiente Mac + Apple Dev account)
- [ ] `lefthook` verificado: pre-commit bloquea código que no pasa `analyze`
- [ ] Revisión de seguridad: RLS policies, manejo de tokens, validaciones

**Commit final:** `chore: fase 9 completa — tests + CI/CD`

---

## Fase 10 — Release Android (iOS pendiente macOS)

**Objetivo:** APK firmado listo para distribución interna. iOS documentado para cuando haya Mac.

- [ ] Configurar signing en Android (`key.properties`, keystore)
- [ ] `flutter build appbundle --release` exitoso
- [ ] Firebase App Distribution o Play Store interno configurado
- [ ] `CHANGELOG.md` v1.0.0
- [ ] Documentar pasos para release iOS cuando haya acceso a macOS

**Commit final:** `chore: v1.0.0 — release Android MVP`

---

## Backlog futuro (post-MVP)

- Panel administrativo web para RH (gestión de premios, canjes, reportes)
- Notificaciones push reales (iOS + Android)
- Módulo de capacitación / cursos
- Chat con dispatcher
- Firma digital de documentos de viaje
- Exportar reportes en PDF
- Integración directa con proveedor GPS (actualmente leen datos ya en BD)
