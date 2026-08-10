# Sistema Modernist

Feature: `modernist`
Estado: **las 8 vistas del export portadas**, claro y oscuro.
Última actualización: 2026-08-06

---

## Qué se hizo

Se portaron a Flutter todos los exports de Claude Design (proyecto
`8d732192-a475-4fcb-9cba-3c074ca473d8`, sistema *Modernist*), cada uno en sus
dos temas:

| Export | Pantalla nueva | Sustituye a |
|---|---|---|
| `Inicio Viaje Activo` | `ActiveTripHomeScreen` | rama de `HomeScreen` |
| `Inicio Sin Viaje` | `IdleHomeScreen` | ramas de `HomeScreen` |
| `Viajes` | `ModernistTripsScreen` | `TripsListScreen` |
| `Detalle Viaje` | `ModernistTripDetailScreen` | `TripDetailScreen` |
| `Perfil Operador` | `OperatorProfileScreen` | `ProfileScreen` |
| `Premios Ruta` | `RewardsRouteScreen` | `RewardsScreen` **y** `RewardsRoadmapScreen` |
| `Ranking` | `ModernistRankingScreen` | `RankingScreen` |
| `Resumen Regreso` | `ModernistReturnSummaryDialog` | `ReturnSummaryDialog` |

Las pantallas anteriores quedaron sin usar pero **no se borraron**; ver
pendientes.

## Configuración: la primera pantalla sin export

`ModernistSettingsScreen` no viene de Claude Design — se compuso con las piezas
que el sistema ya tenía: cabecera con retroceso como la del detalle de viaje,
bandas separadas por reglas de 2 px, y el selector segmentado de los periodos
del ranking reutilizado para el tema. Sirve de prueba de que el sistema aguanta
pantallas nuevas sin inventar tokens.

Lo único que hubo que diseñar de cero fue el **interruptor**: el `Switch` de
Material, con su píldora redondeada, rompe un lenguaje de esquinas a 0. Es un
recuadro de 48×28 con borde de 2 px y un botón cuadrado que se desliza.

Se llega por el **engrane del perfil**, arriba de las iniciales. Con eso
desapareció el último `ShellRoute` y `AppBottomNav` se borró: todas las
pantallas traen su propia barra.

### Los íconos también se dibujan

`modernist_icons.dart` pinta el engrane con `CustomPaint`, por lo mismo que los
triángulos del ranking: Archivo no trae símbolos, los de Material desentonan
con el trazo plano del sistema, y ninguno de los dos resuelve en los goldens.

El export es un sistema visual distinto al de `AppTheme`, no un retoque:

| | `AppTheme` actual | Modernist |
|---|---|---|
| Fondo | `#0D0D0D` (dark-first) | `#F3F2F2` claro |
| Acento | Ámbar `#FF8C00` | Rojo `#C80000` |
| Radio | 8–10 px | **0 px** |
| Bordes | 1 px `#333` sutil | **2 px sólido `#201E1D`** |
| Tipografía | Roboto por defecto | **Archivo** 400–900 |
| Layout | Cards con margen 16 px | Secciones a sangre separadas por reglas |
| Nav | `NavigationBar` de Material | Pestañas propias con regla superior de 3 px |

---

## Cómo se lee el diseño

Los fuentes están en `Operator_app_design_brief/`, un `.dc.html` por vista y por
tema (~15–27 KB cada uno). **Usar esos**, no el `.html` «offline» que exporta el
botón de descarga: ese pesa ~1.1 MB porque es un *bundle* con el contenido real
escondido en dos `<script>` al final (`__bundler/template` con el markup y
`__bundler/manifest` con los assets en base64 + gzip).

Cada `.dc.html` trae el markup, los tokens CSS y la clase `DCLogic` con toda la
lógica derivada: paletas por hora, duraciones de parallax, fórmulas de avance.
**Esa lógica es la especificación** — conviene portarla antes que adivinar desde
el screenshot.

### Empezar por el diff claro ↔ oscuro

Las dos variantes de una vista tienen el mismo número de líneas y difieren solo
en colores, así que un `Compare-Object` entre ambas da la tabla de la paleta en
un paso, y de paso revela qué **no** cambia. En esta pantalla salieron dos
sorpresas que ahorraron trabajo:

- La escena del tracto es **idéntica** en los dos archivos. No depende del tema:
  la iluminan `horaDelDia` y nada más. El mockup oscuro simplemente arranca a
  las 21:00. `truck_scene.dart` no necesitó un solo cambio.
- El banner rojo, el botón primario y la regla de la pestaña activa **siguen en
  `#c80000`** en oscuro. Lo único que cambia ahí es la etiqueta de la pestaña.

### Ojo con lo que el HTML hereda

Varios textos no declaran color y lo heredan del CSS del sistema. El caso que
costó encontrar: el chip de nivel de la cabecera es un `<a href="#">`, y la hoja
define `a { color:#8f0000 }` en claro y `a { color:#ff8a8a }` en oscuro. El
span de `{{ nivelNombre }}` no trae color propio, así que «ORO» va en rojo, no
en tinta. Por eso existe `ModernistPalette.link` — revisar la herencia antes de
asumir que un texto sin `color` va en el color de texto principal.

### Los PNG de `assets/` no son la fuente de verdad

`assets/inicio-claro.png` e `inicio-oscuro.png` son de una revisión distinta a
la de los `.dc.html`: pintan «PUNTOS EST. +137» en rojo, mientras que ambos
`.dc.html` lo declaran verde (`#1a7a3c` claro, `#7ddb9b` oscuro). La
implementación sigue al `.dc.html`. Ante una discrepancia, **manda el HTML** —
es lo que Claude Design renderiza hoy; el PNG es una captura vieja.

---

## Archivos

```
Operator_app_design_brief/                ← los .dc.html fuente, claro y oscuro
assets/fonts/Archivo.ttf                  ← fuente variable (ejes wdth + wght)
lib/core/theme/modernist/
  modernist_tokens.dart                   ← paleta de dos temas + tipografía
lib/features/trips/presentation/
  providers/truck_scene_provider.dart     ← hora del día de la escena
  screens/modernist/
    active_trip_home_screen.dart          ← con viaje en curso
    idle_home_screen.dart                 ← sin viaje asignado
  widgets/modernist/
    truck_scene.dart                      ← tracto en marcha, con parallax
    route_map_illustration.dart           ← mapa ilustrado
    dock_scene.dart                       ← almacén con el tracto estacionado
    modernist_tab_bar.dart                ← pestañas, compartidas
lib/core/router/
  app_router.dart                         ← shell de 4 ramas + rutas apiladas
  modernist_tab_shell.dart                ← la tira que desliza y sigue al dedo
  modernist_transitions.dart              ← entrada desde la derecha de lo apilado
lib/shared/widgets/app_bottom_nav.dart    ← nav anterior, extraída del ShellRoute
test/features/trips/modernist/
  active_trip_home_golden_test.dart       ← arnés de comparación
  idle_home_golden_test.dart
  goldens/*.png                           ← un par claro/oscuro por sección
```

---

## Decisiones que conviene repetir en las demás pantallas

### La fuente variable necesita `fontVariations`

Archivo es una fuente variable y **Flutter no instancia el eje `wght` a partir
del `weight:` declarado en `pubspec.yaml`**: si solo se pide `fontWeight`, todo
sale en 400. Hay que pasar `fontVariations: [FontVariation('wght', n)]`.
`ModernistType.of()` es el único lugar que lo sabe; usarlo siempre en vez de
construir `TextStyle` a mano.

### El `tracking` del CSS va en em

`letter-spacing: .14em` a 11 px son 1.54 px lógicos. `ModernistType` recibe em y
hace la conversión, igual que el export.

### Los dos temas viven en `ModernistPalette`, no en `ThemeData`

`ModernistPalette.of(context)` elige claro u oscuro leyendo
`Theme.of(context).brightness`, así que la pantalla respeta el selector de tema
que ya existe en Ajustes sin tocar `AppTheme`. Lo que **no** cambia entre temas
—rojo de marca, blanco sobre rojo, colores de nivel— vive aparte en
`ModernistColors`, para que quede claro de un vistazo qué es invariante.

`ModernistType` exige el color a propósito: con dos temas vivos, un color por
omisión es un bug esperando a que alguien lo herede en la pantalla equivocada.

### `DecorationPosition.foreground` para las reglas sobre contenido a sangre

Las secciones que pintan a sangre (escena, mapa) tapan una decoración de fondo.
La regla de 2 px tiene que ir en primer plano o desaparece.

### `scroll-snap` es un `PageView`

«Inicio Sin Viaje» son dos pantallas completas que se recorren de una en una.
El export lo declara con `scroll-snap-type: y mandatory` +
`scroll-snap-stop: always` sobre secciones de `height:100%`, que es exactamente
el comportamiento de un `PageView(scrollDirection: Axis.vertical)`. La lista
interna de «Tus últimos viajes» se desplaza dentro de su página sin pelearse
con el snap.

### Los glifos que Archivo no trae hay que dibujarlos

`▲` `▼` `★` no existen en Archivo. En el dispositivo Android el respaldo del
sistema los cubre, pero en los goldens salen como cuadros y en otras
plataformas dependen de la suerte. En `ranking_screen.dart` van pintados con
`CustomPaint`. Antes de portar un carácter decorativo, comprobar que la fuente
lo tenga.

### Un `late final` que solo se toca a veces revienta al desmontar

En la ruta de premios, el nodo objetivo late y los demás no. Con
`late final AnimationController _c = AnimationController(...)`, un nodo apagado
nunca lo tocaba en `build`, y `dispose()` acababa **construyéndolo** al cerrar
la pantalla. Los controladores se crean siempre en `initState`.

### Migrar sacando la pantalla del `ShellRoute`

`/home` salió del shell para llevar su propio chrome. La `NavigationBar` anterior
se extrajo a `AppBottomNav` para que las pantallas sin migrar la sigan usando.
Cada pantalla que se porte repite el mismo movimiento.

### Las pestañas volvieron a un shell, pero sin chrome

Con cada pestaña como ruta suelta, cambiar de pestaña era un corte seco: la
pantalla nueva aparecía sin decir de dónde venía, y el scroll de la anterior se
perdía. Las cuatro pestañas viven ahora en un `StatefulShellRoute`
(`app_router.dart`) que **no dibuja nada alrededor** —cada pantalla sigue
trayendo su propia `ModernistTabBar`—: sólo conserva el estado de cada rama y
anima el paso de una a otra.

El contenedor es `ModernistTabShell` (`lib/core/router/modernist_tab_shell.dart`),
que sustituye al `IndexedStack` por defecto de go_router. Coloca las cuatro ramas
en una tira horizontal y anima la posición de la tira, así que Viajes entra desde
la derecha viniendo de Inicio y desde la izquierda viniendo de Premios.

Detalles que importan:

- **El orden de `modernistBranchTabs` es el orden del deslizamiento.** El router
  arma sus ramas desde esa lista; cambiarla cambia por dónde entra cada pestaña.
- **Ranking no es una rama**: se apila encima con `push`, igual que el detalle de
  viaje o Ajustes. Su barra muestra Ranking en lugar de Premios, y tocar otra
  pestaña ahí cierra la pantalla y deja la pestaña puesta —`goToModernistTab`
  detecta que no hay shell a la vista y navega por ruta.
- **Cualquier salto entre pestañas va por `goToModernistTab`**, no por un
  `context.go` suelto: el «ver todos» de Inicio, el atajo a Premios del perfil,
  el chip de nivel del viaje activo.
- **Las ramas 2 a 4 llevan `preload: true`.** Sin eso su navegador no existe
  hasta la primera visita y el arrastre mostraría un hueco en blanco. El precio
  es que las cuatro pantallas se construyen al arrancar.
- **De Inicio a Premios la tira salta antes de animar.** Recorrer las dos
  pestañas dejaría pasar Viajes como un borrón; la tira se teletransporta a un
  ancho del destino, del lado correcto, y desde ahí sí se desliza.

### El arrastre desde el borde cambia de pestaña

`ModernistTabShell` pone dos franjas de 48 px, una en cada borde, que escuchan
arrastres horizontales. La tira sigue al dedo en tiempo real —se ven las dos
pantallas moviéndose— y al soltar remata hacia la pestaña que quedó más cerca:
basta con recorrer el 28 % del ancho, o soltar con impulso.

Las franjas son `HitTestBehavior.translucent`, así que no le roban los toques al
contenido de abajo y un scroll vertical de la lista sigue ganando la arena de
gestos. La franja es de 48 px y no de 20 porque **en Android los primeros ~20 dp
de cada lado se los queda el gesto de «atrás» del sistema**: si la zona fuera
justa, el borde izquierdo no respondería nunca.

`test/core/router/modernist_tab_shell_test.dart` cubre el sentido del
deslizamiento, el arrastre desde cada borde, el arrastre corto que se devuelve y
que la pantalla entrante no reciba toques a media transición.

### Las pantallas apiladas también entran desde la derecha

`modernistPage()` (`lib/core/router/modernist_transitions.dart`) es la página de
todo lo que se apila sobre las pestañas: detalle de viaje, tractos, ranking,
puntos, ajustes. Entra desde la derecha y empuja a la de abajo un cuarto de
pantalla, el mismo lenguaje que el deslizamiento entre pestañas. La transición de
Material por defecto en Android sube desde abajo y no dice nada del recorrido.

### El golden como arnés de comparación

`active_trip_home_golden_test.dart` renderiza la pantalla en 412×880 —el lienzo
del `android-frame.jsx` del export— y guarda un PNG por tema, comparable contra
el mockup. Requiere cargar Archivo con `FontLoader`, o el golden sale con la
fuente de prueba. Para regenerarlos:

```sh
flutter test --update-goldens test/features/trips/modernist
```

Todo lo que dependa de la hora o del reloj debe inyectarse (ver
`sceneTimeOfDayProvider`), o el golden cambia según cuándo se corra. El test
recorre las dos variantes con la hora que cada export trae por omisión: 15:00 en
claro, 21:00 en oscuro.

Dos cosas que hacen fallar el arnés y no son culpa del diseño: los formatos de
fecha en español necesitan `initializeDateFormatting('es_MX')` antes del
`pumpWidget`, y cualquier familia tipográfica que no sea Archivo sale como
cuadros porque el entorno de pruebas no tiene fuentes del sistema — le pasa al
rótulo monoespaciado «Almacén · Andén 3», que en Android sí resuelve.

---

## La escena del tracto reemplaza al plan de Rive

`truck-animation.md` planeaba resolver la animación con un `.riv` encargado a un
animador. **El export ya la resuelve con CSS + SVG**, incluida la máquina de
estados completa, así que se portó a un `CustomPaint` y no hace falta el `.riv`.

Lo que quedó implementado:

- Parallax de 4 capas con las velocidades del doc (`FarBg ×0.05 · MidBg ×0.2 ·
  Poles ×0.7 · Road ×1.0`), derivadas de `46 / max(6, velocidad)`
- Estados `TruckDriving` · `TruckIdle` · `TruckFlatTire` · `TruckInService` ·
  `TruckCrashed`, con sus animaciones (`bobDrive`, `bobIdle`, `limp`)
- Paletas de día, atardecer y noche; estrellas, faros, humo, «Z z z»
- Ráfagas de velocidad a partir de 88 km/h

Las fases avanzan por incrementos (`fase += dt / duración`) en vez de derivarse
de un tiempo absoluto: así un cambio de velocidad acelera el desplazamiento sin
el brinco que produciría recalcular `elapsed / duración` con otra duración.

---

## Pendientes

### Datos que el diseño inventa

| Dato | Estado | Qué falta |
|---|---|---|
| Folio `V-1842` | Se usan los últimos 4 del UUID del viaje | Columna `folio` en `viajes` (y exponerla en el admin) |
| `meta 4.5` de rendimiento | Hardcodeado | ¿Meta por tracto, por ruta o global? Definir y sacarla de BD |
| `+137 puntos est.` | Fórmula del mockup (`142 - alertas*5`) | El cálculo real vive en Edge Functions. Es un **estimado visual**, nunca un saldo acreditado — no moverlo al cliente |
| Velocidad | Último `viaje_puntos_gps.velocidad_kmh`; si no hay, 76 km/h | Telemetría real (Fase 2 de `truck-animation.md`) |
| Estado mecánico | Se derivan de `TripIncident.tipo` **todas** las incidencias | `TripIncident` no expone el estado del reporte: falta filtrar solo los abiertos |

### Diseño

- **El mapa es una ilustración fija.** El trazo, los cerros y los marcadores no
  corresponden a las coordenadas del viaje; lo único real es el avance del punto
  rojo. Acordado como temporal: cuando se dibuje con los puntos GPS reales de
  origen y destino, `RouteMapIllustration` se reemplaza conservando el lenguaje
  visual (trazo punteado, línea negra de avance, marcadores cuadrados).
- **El punto del rin va centrado**, igual que en el export, así que el giro de
  las ruedas no se percibe. Se mantuvo por paridad; si se quiere que se note,
  hay que descentrarlo (y dejará de ser idéntico al mockup).
- **Origen y destino se encogen antes que partirse en dos líneas.** Un par como
  «Monterrey, NL → Guadalajara, JAL» llena el ancho al ras; si se parte, el
  banner engorda y le roba altura a la escena y al mapa.
- **El mapa recorta a los lados** (`preserveAspectRatio="xMidYMid slice"` del
  export, equivalente a `BoxFit.cover`). Es el comportamiento declarado en el
  diseño, pero deja los marcadores al filo.

- **«PUNTOS EST.» va en verde**, siguiendo ambos `.dc.html`. Los PNG de
  `Operator_app_design_brief/assets/` lo pintan en rojo, pero son de otra
  revisión. Si el rojo es lo que se quiere, cambiar `ModernistPalette.positive`
  a `danger` — está en un solo lugar.

### De «Inicio Sin Viaje»

| Dato | Estado | Qué falta |
|---|---|---|
| Racha en `HomeStateReturning` | Queda en 0 | Ese estado no la calcula. Hoy no se nota porque el popup de resumen cubre ese caso y `HomeStateReturning` es código muerto |

- **El botón Disponible / Pausado del export se retiró.** La disponibilidad del
  operador la decide administración, no él: el export lo propone como control
  del operador y eso no corresponde al flujo real. Con él se fue el mensaje
  «Marcado como no disponible…»; el texto de espera quedó fijo.

- **La caja de abajo del apilamiento mide distinto en cada export** (97 px en
  claro, 86 en oscuro), y en claro sobresale de la columna de 94 px. Parece
  descuido del diseño; se respetó cada valor para no desviarse de su mockup.
- **«Ver ruta de premios» apunta a `/rewards/catalog`**, que es la ruta que la
  app ya tenía para el roadmap. El export enlaza a `Premios Ruta.dc.html`;
  confirmar que son la misma pantalla al portar ese export.

### De «Viajes» y «Detalle Viaje»

- **El desglose de puntos no tiene columna propia.** Se rescata parseando
  `movimientos_puntos.descripcion`. **Y hay un desajuste en la BD**: la Edge
  Function `calcular-puntos-viaje` escribe
  `«Viaje completado. rendimiento: +113, puntualidad: +50, …»`, pero el trigger
  `fn_calcular_puntos_viaje` —que es el que corre de verdad al cerrar un
  viaje— escribe `«Viaje completado — 486 km, calif 4.8, 1 alertas, 0
  incidencias»`, **sin desglose**. Para los viajes cerrados por el trigger la
  hoja muestra una nota en vez del desglose. Conviene unificar los dos
  formatos, o mejor, guardar el desglose en una columna `jsonb`.
- **El chip «Mis tractos» dice VER** en vez del económico del tracto
  (`T-003` en el export): la lista de viajes no tiene ese dato a mano.
- **La ruta GPS sigue siendo una ilustración fija.** Lo que sí sale de datos
  reales son los marcadores de alertas e incidencias, repartidos sobre el
  trazo según el momento del viaje en que ocurrieron.
- **La unidad de una alerta se deduce del tipo** (`velocidad` → km/h,
  `frenado` → m/s²): `SecurityAlert` no la guarda.

### De «Ranking»

- **Ningún export enlaza al ranking.** Su barra de pestañas cambia Premios por
  Ranking, pero nada lleva ahí, y al quitar el AppBar del Home se perdió el
  ícono que servía de entrada. Se añadió un botón **«Ver ranking de la flota»**
  al final de Perfil, que no está en ningún export — confirmar si es el lugar.
- **El total de operadores sale del corte cargado**, no de un conteo de la
  flota; el export dice «Flota Monterrey · 12 operadores» y aquí es
  «Flota · N operadores» porque la base no viene en `RankingEntry`.

### De «Configuración»

- **`pushNotificationsEnabled` viene en `true` por omisión** (`app_settings.dart`)
  para una función que todavía no existe: no hay FCM ni registro en
  `operador_devices`. La fila sale encendida pero inerte, lo que se lee raro
  junto a «Disponibles próximamente». Conviene que arranque en `false` hasta
  la Fase 8. Es un valor previo a este rediseño, no se tocó.

### Alcance

- **Las pantallas viejas siguen en el repo sin usarse**: `TripsListScreen`,
  `TripDetailScreen`, `ProfileScreen`, `RewardsScreen`,
  `RewardsRoadmapScreen`, `RankingScreen` y el `ReturnSummaryDialog` anterior,
  más sus widgets (`TripCard`, `PremioCard`, `RoadmapMilestone`,
  `CanjeSheet`, `LevelBadge`, `RankChangeIndicator`, `ActiveTripCard`…). No se
  borraron para no arrastrar el cambio; conviene hacerlo en un commit aparte
  una vez validado todo en emulador.
