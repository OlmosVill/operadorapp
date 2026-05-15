# Brief para Animador Rive — Tractocamión en Viaje Activo

**Proyecto:** OperadorApp — App móvil para operadores de tractocamiones  
**Feature:** Animación reactiva del tracto en viaje activo  
**Archivo de salida:** `truck_drive.riv`  
**Fecha:** 2026-05-14

---

## 1. Propósito de la animación

La app muestra al operador un card de "viaje en curso" mientras conduce.
Actualmente ese card tiene un mapa estático. Lo reemplazamos por una escena
animada de su tractocamión viajando en carretera — una animación infinita,
**siempre viva**, que cambia visualmente según el estado real del viaje:
hora del día, si hay algún reporte mecánico abierto, y la velocidad.

La animación debe sentirse como la "ventana al viaje" del operador. Es la
pieza visual más importante de toda la app. Debe ser memorable, limpia y
técnicamente robusta (sin bitmaps, peso mínimo, state machine bien definida).

---

## 2. Estilo visual

### Referencia
Flat design / vector cartoon. Vista lateral pura. Minimalista. Sin gradientes complejos.
Sin sombras realistas. Líneas limpias con relleno de colores sólidos o con variaciones
de luminosidad muy sutiles (máximo 2 tonos del mismo color por forma).

**Referencias de estilo:** ilustración de transporte en apps como Lalamove, apps logísticas
latinoamericanas, o cartoons de camiones de juegos como Truck Simulator en su versión UI.

### Composición
Tractocamión (cab + trailer) en vista lateral, moviéndose de izquierda a derecha.
Ocupa aproximadamente 55–65% del ancho del artboard. Ruedas en la línea de la carretera.
Fondo con paisaje desplazándose de derecha a izquierda (parallax).

### Paleta de colores principal

| Elemento               | Color propuesto      | Hex       | Notas                            |
|------------------------|----------------------|-----------|----------------------------------|
| Cab (cabina)           | Azul petróleo        | `#2A5C7A` | Color corporativo principal      |
| Cab sombra interna     | Azul petróleo oscuro | `#1D3F55` | Para profundidad en flat         |
| Trailer (caja)         | Naranja señalización | `#E76F3B` | Contraste fuerte con el cab      |
| Trailer franja         | Naranja oscuro       | `#C4572A` | Detalle lateral del trailer      |
| Llantas                | Gris carbón          | `#2D2D2D` | Casi negro                       |
| Rin de llanta          | Gris plata           | `#8A8A8A` | Detalle en el centro             |
| Cristal cabina         | Azul cyan            | `#89D4E8` | Con ligera transparencia (alpha) |
| Carretera              | Gris asfalto         | `#3A3A3A` |                                  |
| Líneas carretera       | Blanco intermitente  | `#F5F5F5` | Líneas discontinuas              |
| Cielo día              | Azul cielo           | `#87CEEB` |                                  |
| Cielo atardecer        | Naranja/púrpura      | `#F4A261` → `#6B3FA0` | Gradiente flat, 2 stops |
| Cielo noche            | Azul marino oscuro   | `#0D1B2A` |                                  |
| Faros (cono de luz)    | Amarillo cálido      | `#FFE08A` | Alpha 60%, triángulo             |
| Colinas lejanas        | Verde grisáceo       | `#7BAF7B` | Saturación baja                  |
| Colinas medias         | Verde olivo          | `#5C8A5C` |                                  |
| Postes de luz          | Gris medio           | `#6B6B6B` |                                  |
| Humo (estado crashed)  | Gris claro           | `#BDBDBD` | Alpha variable, nubes circulares |

> La paleta es una propuesta base. El animador puede ajustar tonos para coherencia visual,
> pero debe mantener el cab azul petróleo y el trailer naranja como identidad del tracto.

---

## 3. Especificaciones técnicas

| Parámetro          | Valor                                   |
|--------------------|-----------------------------------------|
| Artboard name      | `TruckScene`                            |
| Artboard size      | **900 × 400 px**                        |
| Aspect ratio       | 2.25 : 1 (horizontal, paisaje)          |
| FPS objetivo       | **60 FPS**                              |
| State machine name | `TruckStateMachine` (exacto)            |
| Peso máximo        | **≤ 200 KB** (solo vectores, sin raster)|
| Formato de salida  | `.riv` (Rive binary, no `.rev`)         |

> El artboard de 900×400 px define el espacio de coordenadas del animador.
> Flutter escala la animación al tamaño real del widget (aprox. 360×160 dp en pantalla)
> con `BoxFit.cover`. Los elementos deben estar bien centrados en el artboard.

---

## 4. Capas del artboard (orden de z, fondo a frente)

```
TruckScene (900 × 400 px)
│
├── [z=0] Sky                Cielo. Full artboard. Color animado por timeOfDay.
├── [z=1] FarBackground      Colinas lejanas + luna/sol. Parallax muy lento.
├── [z=2] MidBackground      Colinas medias, arbustos, horizonte. Parallax lento.
├── [z=3] Poles              Postes de luz telegráficos. Parallax rápido.
├── [z=4] Road               Carretera + líneas discontinuas animadas. Parallax base.
├── [z=5] ShadowGround       Sombra plana elíptica bajo las llantas del tracto.
├── [z=6] Truck              Tractocamión completo.
│   ├── Group: Cab           Cabina. Cristal. Faros frontales.
│   ├── Group: Trailer       Caja. Reflectores traseros.
│   ├── Group: WheelFront    Llanta delantera. Rota según speed.
│   ├── Group: WheelRear1    Primera llanta trasera. Rota según speed.
│   └── Group: WheelRear2    Segunda llanta trasera (si doble eje). Rota según speed.
└── [z=7] FX                 Efectos visuales de estado.
    ├── Headlights           Cono de luz amarillo. Visible en noche.
    ├── Smoke                Nube de humo gris del cofre. Solo en Crashed.
    ├── Mechanic             Silueta de mecánico con caja de herramientas. Solo en InService.
    └── Stars                Estrellas y luna. Visible en noche.
```

### Velocidad de parallax por capa (relativa a `speed`)

| Capa          | Multiplicador | Ejemplo (speed=60)     |
|---------------|---------------|------------------------|
| Sky           | 0 (estático)  | No se mueve            |
| FarBackground | 0.05          | 3 px/frame equiv.      |
| MidBackground | 0.20          | 12 px/frame equiv.     |
| Poles         | 0.70          | 42 px/frame equiv.     |
| Road          | 1.00          | 60 px/frame equiv. (base) |

> La velocidad real del parallax la controla la animación interna de cada estado.
> El input `speed` modula esa velocidad proporcionalmente.
> Cuando `speed = 0`, todas las capas de fondo se detienen.

---

## 5. State Machine: TruckStateMachine

### 5.1 Inputs (nombres EXACTOS — case-sensitive)

El código Flutter escribe estos inputs para controlar la animación.
**Los nombres deben ser idénticos al pie de la letra.**

| Nombre            | Tipo      | Rango         | Descripción                                                    |
|-------------------|-----------|---------------|----------------------------------------------------------------|
| `speed`           | **Number**| 0.0 – 120.0   | Velocidad en km/h. 0 = detenido. Afecta parallax y ruedas.   |
| `timeOfDay`       | **Number**| 0.0 – 24.0    | Hora del día en formato decimal (ej: 14.5 = 2:30 PM).         |
| `mechanicalState` | **Number**| 0, 1, 2, 3   | Estado mecánico. Ver tabla de mapeo abajo.                     |

**Mapeo de `mechanicalState`:**

| Valor | Estado       | Descripción                             |
|-------|--------------|-----------------------------------------|
| 0     | `ok`         | Tracto en buen estado, viaje normal     |
| 1     | `flatTire`   | Llanta ponchada, conducción irregular   |
| 2     | `inService`  | Detenido para mantenimiento             |
| 3     | `crashed`    | Accidentado, fuera de servicio          |

**Mapeo de `timeOfDay` → apariencia:**

| Rango         | Momento       | Cielo                   | Faros | Estrellas |
|---------------|---------------|-------------------------|-------|-----------|
| 5.0 – 6.5     | Amanecer      | Transición oscuro→naranja | Apagándose | Desapareciendo |
| 6.5 – 17.5    | Día           | Azul cielo claro        | Apagados | Ocultas |
| 17.5 – 20.0   | Atardecer     | Naranja/púrpura         | Encendiéndose | Apareciendo |
| 20.0 – 5.0    | Noche         | Azul marino oscuro      | Encendidos | Visibles |

> Usar blending de colores (interpolación lineal) para transiciones suaves entre rango y rango.
> No usar cortes abruptos.

### 5.2 States (5 estados)

**`TruckDriving`** (estado base / default)
- Parallax activo en todas las capas de fondo
- Ruedas girando proporcionalmente a `speed`
- Cab + trailer con bounce vertical sutil: ~±3px, frecuencia 1.2 Hz (simulación de suspensión)
- Sombra debajo de las llantas se deforma ligeramente con el bounce
- Faros: visibles solo si `timeOfDay` indica noche
- Estrellas + luna: visibles solo si `timeOfDay` indica noche
- Líneas de carretera: animadas, desaparecen en el borde izquierdo y reaparecen en el derecho

**`TruckIdle`**
- Fondo completamente estático (parallax detenido)
- Ruedas quietas (sin rotación)
- Bounce vertical más lento y suave: ±1.5px, frecuencia 0.5 Hz (motor al ralentí)
- El escape del tracto puede tener una nubecita de humo gris pequeña y ocasional
- Faros y estrellas: igual que Driving según timeOfDay

**`TruckFlatTire`**
- El tracto avanza, pero el bounce vertical es asimétrico: cae más hacia el lado de la llanta ponchada (abajo a la derecha), efecto de "cojera"
- Velocidad de parallax reducida a máximo 20 km/h sin importar el input `speed`
- La llanta ponchada (WheelRear2 o WheelFront, a definir) visualmente desinflada: elipse vertical aplastada, sin centrar en el eje, levemente torcida
- Sombra del tracto se inclina ligeramente

**`TruckInService`**
- Tracto completamente detenido (igual que Idle pero sin bounce de motor)
- Fondo estático
- FX: Mechanic — silueta plana de un mecánico (flat design, sin detalle) con caja de herramientas a su lado. Aparece junto al lado del cab. Animación: el mecánico hace movimientos lentos de trabajo (levantar/bajar el brazo, ~0.5 Hz).
- No hay faros encendidos (motor apagado)

**`TruckCrashed`**
- Tracto completamente detenido y ligeramente torcido (rotación 2-4° en el artboard)
- Fondo estático
- FX: Smoke — nubes de humo gris saliendo del cofre del cab. Animación: nubes circulares que suben y se disipan (alpha 100% → 0%), en loop. 3-4 nubes en diferentes fases del ciclo para efecto continuo.
- La llanta delantera o el cab muestran una abolladura visual (deformación de la forma vectorial)
- No hay faros encendidos

### 5.3 Transitions

Las condiciones se evalúan sobre los inputs. Flutter actualiza los inputs; Rive decide la transición.

| Desde           | Hacia          | Condición                                       |
|-----------------|----------------|-------------------------------------------------|
| `TruckDriving`  | `TruckIdle`    | `speed ≤ 0`                                     |
| `TruckIdle`     | `TruckDriving` | `speed > 0`                                     |
| Cualquier estado| `TruckFlatTire`| `mechanicalState == 1`                          |
| `TruckFlatTire` | `TruckDriving` | `mechanicalState == 0` AND `speed > 0`          |
| `TruckFlatTire` | `TruckIdle`    | `mechanicalState == 0` AND `speed ≤ 0`          |
| Cualquier estado| `TruckInService`| `mechanicalState == 2`                         |
| `TruckInService`| `TruckDriving` | `mechanicalState == 0` AND `speed > 0`          |
| `TruckInService`| `TruckIdle`    | `mechanicalState == 0` AND `speed ≤ 0`          |
| Cualquier estado| `TruckCrashed` | `mechanicalState == 3`                          |
| `TruckCrashed`  | `TruckDriving` | `mechanicalState == 0` AND `speed > 0`          |
| `TruckCrashed`  | `TruckIdle`    | `mechanicalState == 0` AND `speed ≤ 0`          |

> "Cualquier estado" significa que la transición existe desde todos los demás estados.
> Las transiciones hacia estados de emergencia (`crashed`, `inService`) tienen prioridad alta.

**Duración recomendada de transiciones:**
- Driving ↔ Idle: 300–400 ms (suave)
- Cualquiera → FlatTire: 200 ms
- Cualquiera → InService: 500 ms (el tracto "se va frenando")
- Cualquiera → Crashed: 150 ms (impacto rápido)
- Crashed / InService → normal: 500 ms

---

## 6. Especificaciones de animación por elemento

### Ruedas (WheelFront, WheelRear1, WheelRear2)
- Giran en sentido horario (para un tracto moviéndose hacia la derecha)
- Velocidad de rotación proporcional a `speed`: `speed=60` → ~2 rev/seg
- En `TruckIdle` y `TruckInService`: sin rotación
- En `TruckFlatTire`: WheelRear2 (o la designada como ponchada) gira irregular o deformada

### Bounce del tracto (suspensión)
- Aplica a todo el grupo `Truck` completo en Y
- `TruckDriving`: ±3 px, sinusoide suave, 1.2 Hz
- `TruckIdle`: ±1.5 px, sinusoide suave, 0.5 Hz
- `TruckFlatTire`: asimétrico: +2px / -5px, 0.8 Hz, con ligera rotación de ±0.5°
- `TruckInService` / `TruckCrashed`: sin bounce

### Líneas de carretera
- Líneas blancas discontinuas en la banda central de la carretera
- Se mueven de derecha a izquierda a velocidad proporcional a `speed`
- Cuando `speed = 0`: estáticas
- Loop infinito: cuando una línea sale por el borde izquierdo, reaparece por la derecha

### Cono de faros (FX/Headlights)
- Triángulo con punta en los faros frontales del cab, se expande hacia adelante-izquierda
- Color: amarillo cálido `#FFE08A`, alpha 60%
- Visible únicamente cuando `timeOfDay < 6.5 OR timeOfDay > 17.5`
- Parpadeo muy sutil opcional: alpha oscila ±5% a 2 Hz

### Humo (FX/Smoke) — solo `TruckCrashed`
- 3 nubes circulares en posiciones distintas sobre el cofre
- Cada nube: inicia pequeña y opaca, crece y se vuelve transparente, luego desaparece
- Ciclo por nube: ~2 segundos
- Las 3 nubes desfasadas 0.66 s entre sí para efecto continuo
- Color: `#BDBDBD`, alpha max 80%

### Mecánico (FX/Mechanic) — solo `TruckInService`
- Silueta flat sin detalle facial
- Colores: overol naranja o azul (contraste con el tracto), zapatos oscuros
- Acción en loop: levantar llave/herramienta, bajarla, pausa. ~2 seg ciclo
- Caja de herramientas estática en el suelo a su lado

### Cielo / Fondo (Sky)
- No tiene animación propia de movimiento
- El color cambia suavemente basado en `timeOfDay` (blending de colores en timeline)
- En noche: la capa Stars aparece con luna y 4–6 estrellas estáticas simples (puntos o + pequeños)

---

## 7. Entregables esperados

### Obligatorios

| Archivo                          | Descripción                                              |
|----------------------------------|----------------------------------------------------------|
| `truck_drive.riv`                | Archivo Rive final, listo para producción                |
| `truck_drive.rive` (fuente)      | Proyecto editable en Rive editor (para ajustes futuros)  |
| `input-reference.md`             | Tabla con cada input: nombre exacto, tipo, valores válidos |
| Preview GIF o MP4 por cada state | 1 por estado (5 estados × variantes día/noche = ~8 clips)|

### Opcionales pero muy bienvenidos
- Artboard de exploración de estilo (variantes de color del tracto)
- Versión del tracto sin trailer (futuro: para otros tipos de unidad)

---

## 8. Restricciones técnicas

| Restricción             | Detalle                                                   |
|-------------------------|-----------------------------------------------------------|
| **Peso máximo**         | ≤ 200 KB para el archivo `.riv`                          |
| **Sin raster**          | Nada de PNG/JPG embebido. Todo debe ser vectorial.       |
| **Sin fuentes**         | No incluir texto ni fonts (se superpone desde Flutter)   |
| **FPS objetivo**        | 60 FPS. Evitar técnicas que causen drops en mid-range    |
| **Un solo artboard**    | Todo en `TruckScene`. No artboards separados por estado. |
| **Una sola SM**         | `TruckStateMachine` como única state machine del artboard|
| **Nombres exactos**     | Artboard, state machine e inputs deben coincidir exacto  |
| **Bucles infinitos**    | Todos los estados deben loopearse. No animaciones de un disparo.|

---

## 9. Notas de optimización para rendimiento en mobile

- Evitar `clipPath` complejos — son costosos en GPU. Usar formas con bordes redondeados nativas.
- Las ruedas pueden ser un solo grupo con `arcToPoint` simple — no necesitan detalle interno.
- El parallax de fondo puede ser un único rectángulo que se desplaza en loop (no múltiples objetos).
- Para el bounce, animar el grupo completo del tracto en Y es más eficiente que animar subgrupos por separado.
- Las nubes de humo: preferir alpha animation sobre scale+alpha combinado (menos recalculos).
- Mantener menos de 200 nodos vectoriales totales si es posible.

---

## 10. Preguntas frecuentes del animador

**¿Cómo sabe Rive cuándo cambiar entre estados?**
Flutter actualiza los inputs (`speed`, `timeOfDay`, `mechanicalState`) en tiempo real.
Rive evalúa las condiciones de las transitions automáticamente. El animador no necesita
conectar nada extra — solo definir bien las condiciones en el editor de Rive.

**¿Qué pasa si speed es, por ejemplo, 73.5?**
El input es un Number continuo. La velocidad del parallax y las ruedas debe ser proporcional
y lineal. Si a speed=60 las ruedas dan 2 rev/seg, a speed=73.5 deben dar 2.45 rev/seg.
Esto se logra usando el input `speed` como driver de la velocidad del timeline en Rive.

**¿Puedo usar más de 3 inputs?**
Para esta versión MVP, usar solo los 3 inputs listados. Los inputs de Fase 2 (`weather`,
`driverState`) se añadirán después y el animador podrá agregar más estados/inputs entonces.

**¿Los estados de InService y Crashed tienen parallax?**
No. Cuando el tracto está detenido (InService, Crashed, e Idle), el fondo está completamente
estático. Solo se mueven los FX locales (humo, mecánico).

**¿Qué artboard size debo usar exactamente?**
900 × 400 px. Flutter escala la animación al espacio disponible del widget con BoxFit.cover,
así que el artboard define el espacio de coordenadas del animador, no el tamaño final en pantalla.

---

*Contacto para dudas técnicas: equipo de desarrollo de OperadorApp.*
*Referencia técnica completa en: `docs/features/truck-animation.md`*
