# Arquitectura — OperadorApp

## Resumen

OperadorApp sigue **Clean Architecture** con tres capas por feature (`domain`, `data`, `presentation`)
y una estrategia **offline-first** donde Drift (SQLite local) es la fuente única de verdad para la UI.
Supabase actúa como origen autoritativo de datos y se sincroniza en background.

---

## Capas de Clean Architecture

```mermaid
graph TD
    subgraph Presentation
        S[Screens]
        W[Widgets]
        P[Riverpod Providers]
    end

    subgraph Domain
        UC[Use Cases]
        E[Entities]
        RI[Repository Interfaces]
    end

    subgraph Data
        RM[Remote Datasource<br>Supabase]
        LM[Local Datasource<br>Drift SQLite]
        M[Models<br>Freezed + json_serializable]
        RP[Repository Implementations]
    end

    S --> P
    W --> P
    P --> UC
    UC --> RI
    RI --> |implementado por| RP
    RP --> RM
    RP --> LM
    RM --> M
    LM --> M
    M --> |mapea a| E
```

**Regla de dependencia:** las flechas solo apuntan hacia `Domain`. `Domain` no importa nada de `Data`
ni de `Presentation`. Esto garantiza que la lógica de negocio sea independiente de Flutter y Supabase.

---

## Flujo de datos completo (lectura)

```mermaid
sequenceDiagram
    participant UI as Screen / Widget
    participant P as Provider (Riverpod)
    participant UC as Use Case
    participant Repo as Repository Impl
    participant Local as Drift (SQLite)
    participant Remote as Supabase

    UI->>P: watch(tripListProvider)
    P->>UC: getTrips(operatorId)
    UC->>Repo: getTrips()
    Repo->>Local: SELECT * FROM viajes
    Local-->>Repo: List<ViajeTableData>
    Repo-->>UC: Either<AppError, List<Trip>>
    UC-->>P: Right(trips)
    P-->>UI: AsyncData(trips) — render inmediato

    Note over Repo,Remote: background sync
    Repo->>Remote: supabase.from('viajes').select()
    Remote-->>Repo: List<Map<String,dynamic>>
    Repo->>Local: batch INSERT OR REPLACE
    Local-->>P: stream actualizado
    P-->>UI: AsyncData(trips) — actualizado
```

---

## Flujo de datos (escritura offline-first)

```mermaid
sequenceDiagram
    participant UI as Screen
    participant UC as Use Case
    participant Repo as Repository
    participant Local as Drift
    participant Queue as PendingOpsQueue
    participant Net as ConnectivityService
    participant Remote as Supabase

    UI->>UC: redeemReward(rewardId)
    UC->>Net: isOnline?

    alt Hay red
        UC->>Remote: Edge Function: canjear_premio
        Remote-->>UC: OK / Error
        UC->>Local: upsert resultado
    else Sin red
        UC->>Local: INSERT premios_canjeados (estado=pendiente_sync)
        UC->>Queue: enqueue(CanjearPremioOp)
        Note over Queue: persiste en Drift tabla pending_ops
    end

    Net->>Queue: evento "red disponible"
    Queue->>Remote: flush operaciones pendientes (FIFO)
    Remote-->>Queue: confirmación
    Queue->>Local: marcar como sincronizado
```

---

## Estrategia offline-first con Drift + Supabase

```mermaid
flowchart LR
    subgraph Dispositivo
        UI[UI Stream]
        Drift[(Drift SQLite\nfuente de verdad local)]
        Queue[(pending_ops\ntabla Drift)]
    end

    subgraph Nube
        Supa[(Supabase\nPostgreSQL)]
        Edge[Edge Functions]
    end

    UI -->|watch stream| Drift
    Drift -->|sync pull cada 5 min\no al abrir app| Supa
    Supa -->|upsert local| Drift
    Queue -->|flush al recuperar red| Edge
    Edge -->|confirma| Drift
```

### Principios:
1. **La UI siempre lee de Drift** → respuesta inmediata, sin pantallas de carga por red
2. **El sync con Supabase es en background** → el operador no espera
3. **Escrituras sin red se encolan** → se envían cuando vuelve la conectividad
4. **Los datos críticos usan server-wins** → si hay conflicto, la versión del servidor gana
5. **Datos editables por el operador usan last-write-wins con timestamp**

---

## Patrón Adapter para mapas

```mermaid
classDiagram
    class MapAdapter {
        <<abstract>>
        +buildMap(config) Widget
        +drawRoute(List~LatLng~ points) void
        +addMarker(LatLng pos, MapMarkerIcon icon) void
        +moveCameraTo(LatLng pos, double zoom) void
        +dispose() void
    }

    class GoogleMapsAdapter {
        -GoogleMapController _controller
        +buildMap(config) Widget
        +drawRoute(points) void
        +addMarker(pos, icon) void
        +moveCameraTo(pos, zoom) void
        +dispose() void
    }

    class OpenStreetMapAdapter {
        -MapController _controller
        +buildMap(config) Widget
        +drawRoute(points) void
        +addMarker(pos, icon) void
        +moveCameraTo(pos, zoom) void
        +dispose() void
    }

    class MapProviderFactory {
        +create(MapProvider provider) MapAdapter
    }

    MapAdapter <|-- GoogleMapsAdapter
    MapAdapter <|-- OpenStreetMapAdapter
    MapProviderFactory --> MapAdapter
```

La selección de implementación se hace en tiempo de ejecución desde `AppConfig`:

```
MAP_PROVIDER=osm   → OpenStreetMapAdapter  (default dev)
MAP_PROVIDER=google → GoogleMapsAdapter    (producción)
```

El widget `TripMapView` usa `MapAdapter` sin saber qué implementación tiene debajo.

---

## Manejo de errores

```mermaid
flowchart TD
    RM[Remote Datasource] -->|lanza Exception| Repo
    LM[Local Datasource] -->|lanza Exception| Repo
    Repo -->|catch → Left AppError| UC
    UC -->|Either L/R| Provider
    Provider -->|AsyncError / AsyncData| UI
    UI -->|fold Left: ErrorWidget\nfold Right: DataWidget| Screen
```

`AppError` es un sealed class con variantes: `NetworkError`, `AuthError`, `NotFoundError`,
`ValidationError`, `UnexpectedError`. La UI maneja cada caso explícitamente.

---

## Decisiones técnicas

### Riverpod 2.x vs Bloc vs GetX
Riverpod unifica DI + state management. Los `AsyncNotifier` encajan con `Either<AppError, T>`.
`riverpod_generator` elimina boilerplate. Mejor aislamiento en tests que GetX.

### Drift vs Hive vs Isar
Drift valida queries SQL en tiempo de compilación. Soporta migrations versionadas, transacciones
ACID, JOINs (necesarios: viajes → gps_points → alertas). `drift_dev` genera mocks para tests.

### Supabase vs Firebase
PostgreSQL real con PostGIS para rutas. SQL sin límites de Firestore. RLS declarativa en BD.
Edge Functions para lógica de negocio que no debe vivir en el cliente. Open source y portable.

### fpdart (Either/Option) vs try/catch
Errores explícitos y tipados en la firma de cada función. La UI sabe exactamente qué puede
fallar sin leer la implementación. Composición funcional: `map`, `flatMap`, `fold` sin anidamiento.

### GoRouter vs Navigator 2.0 directo
Guards de autenticación como `redirect`. Deep linking listo. Compatible con web si se necesita.
Más declarativo y testeable que Navigator imperativo.
