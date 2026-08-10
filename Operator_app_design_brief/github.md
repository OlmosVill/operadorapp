# GitHub source

repo: OlmosVill/operadorapp
branch: main

## Last sync

date: 2026-08-06T03:20:00Z

### Updated in this project
- Added the Ranking screen (light + dark) — periodo selector (Histórico / Este mes), flat 2-3-1 podium, the LUGAR / OPERADOR / PUNTOS / CAMBIO table with ▲▼ deltas against the last snapshot, and the fixed "Tu lugar" bar
- Added the return-summary popup (light + dark) — points counter from zero, two-phase level bar with the next level's insignia at the end of the track, rank movement and the completed-trip list
- Added the no-active-trip Home (light + dark) covering both `HomeStateDashboard` and `HomeStateReturning`, with the streak rule and the available/paused toggle
- Added the trip-detail screen (light + dark) — status bar, 4-up stat grid, GPS route with alert/incident pins, and incident + security-alert lists with measured-vs-threshold bars
- Added the Viajes screen (light + dark) — month-grouped trip history, the real five-value `TripStatus`, and a per-trip points breakdown by `reglas_puntaje.variable`
- Added the Inicio screen in its active-trip state (HomeStateActiveTrip), with live elapsed timer and route progress
- Trip stats, pulsing in-progress dot and incident reporting grounded in `active_trip_card.dart` and the trips feature
- Perfil Operador screen built from the profile, points and rewards data model
- Added the Premios screen as a vertical ascending trophy road — level banners, path nodes, "Estás aquí" marker and canje sheet, grounded in `roadmap_milestone.dart` / `rewards_roadmap_screen.dart`
- Truck animation grounded in `docs/features/truck-animation.md`: parallax layer ratios (0.05 / 0.2 / 0.7 / 1.0), the five TruckStateMachine states, and the `speed` / `timeOfDay` / `mechanicalState` inputs — a CSS stand-in for the pending `assets/animations/truck_drive.riv` (not yet in the repo)
- Level badge and per-level colors grounded in `level_badge.dart` + `niveles_operador.color_hex`
- Styled in the attached Modernist design system rather than the repo's amber/asphalt Flutter theme

## Screen map

| Project screen | Repo files |
| --- | --- |
| Viajes.dc.html / Viajes Oscuro.dc.html | lib/features/trips/domain/entities/trip.dart, lib/features/trips/presentation/widgets/trip_card.dart, lib/features/trips/presentation/screens/trips_list_screen.dart, lib/features/trips/data/datasources/trips_local_datasource.dart, supabase/functions/calcular-puntos-viaje/index.ts |
| Detalle Viaje.dc.html / Detalle Viaje Oscuro.dc.html | lib/features/trips/presentation/screens/trip_detail_screen.dart, lib/features/trips/domain/entities/trip_detail.dart, lib/features/trips/domain/entities/security_alert.dart, lib/features/trips/domain/entities/trip_incident.dart, lib/features/trips/domain/entities/gps_point.dart |
| Inicio Sin Viaje.dc.html / Inicio Sin Viaje Oscuro.dc.html | lib/features/trips/presentation/providers/home_provider.dart, lib/features/trips/presentation/screens/home_screen.dart, lib/features/profile/presentation/widgets/level_badge.dart, supabase/seed.sql |
| Premios Ruta.dc.html | lib/features/rewards/presentation/widgets/roadmap_milestone.dart, lib/features/rewards/presentation/screens/rewards_roadmap_screen.dart, lib/features/rewards/domain/entities/premio.dart, supabase/seed.sql |
| Inicio Viaje Activo.dc.html | lib/features/trips/presentation/screens/home_screen.dart, lib/features/trips/presentation/widgets/active_trip_card.dart, lib/features/trips/presentation/providers/home_provider.dart, lib/features/profile/presentation/widgets/level_badge.dart, docs/features/truck-animation.md, supabase/seed.sql |
| Ranking.dc.html / Ranking Oscuro.dc.html | lib/features/ranking/domain/entities/ranking_entry.dart, lib/features/ranking/presentation/screens/ranking_screen.dart, lib/features/ranking/presentation/widgets/ranking_tile.dart, lib/features/ranking/presentation/widgets/ranking_podium.dart, lib/features/ranking/presentation/widgets/rank_change_indicator.dart, supabase/migrations/20240101000004_ranking_operadores.sql |
| Resumen Regreso.dc.html / Resumen Regreso Oscuro.dc.html | lib/features/summary/domain/entities/return_summary.dart, lib/features/summary/presentation/widgets/return_summary_dialog.dart, lib/features/summary/presentation/providers/return_summary_provider.dart, lib/features/summary/data/datasources/return_snapshot_store.dart, lib/features/profile/domain/entities/level_thresholds.dart |
| Perfil Operador.dc.html | lib/features/profile/presentation/screens/profile_screen.dart, lib/features/profile/domain/entities/operator_profile.dart, lib/features/points/presentation/screens/points_screen.dart, lib/features/rewards/presentation/screens/rewards_screen.dart, supabase/seed.sql, lib/core/theme/app_theme.dart |
