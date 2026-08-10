/// Tokens del sistema de diseño **Modernist** exportado desde Claude Design.
///
/// Es un sistema distinto al de `AppTheme`: esquinas a 0, reglas de 2 px y
/// rojo de marca en lugar del ámbar. Vive aparte a propósito — las pantallas se
/// migran una por una y mientras tanto ambos coexisten.
///
/// Los valores salen de los exports `Inicio Viaje Activo.dc.html` y
/// `Inicio Viaje Activo Oscuro.dc.html`; cambiarlos rompe la paridad con el
/// mockup.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:operadorapp/features/profile/domain/entities/operator_profile.dart';

final _numberFormat = NumberFormat.decimalPattern('es_MX');

/// Formatea una cifra como lo hace el export: `Intl.NumberFormat('es-MX')`
/// sobre el valor redondeado, y nunca en negativo.
String modernistNumber(num value) =>
    _numberFormat.format(value.round().clamp(0, 1 << 31));

/// Folio corto de un viaje, para el `V-####` de los exports.
///
/// `viajes` no tiene columna de folio, así que se usan los últimos cuatro
/// caracteres del UUID. Ver pendientes en `docs/features/modernist-home.md`.
String modernistFolio(String id) {
  final clean = id.replaceAll('-', '');
  if (clean.length < 4) return clean.toUpperCase();
  return clean.substring(clean.length - 4).toUpperCase();
}

/// Convierte un valor de BD (`frenado_brusco`) en una etiqueta legible
/// (`Frenado brusco`), que es como los exports muestran `tipo`.
String modernistLabel(String raw) {
  final clean = raw.replaceAll('_', ' ').trim();
  if (clean.isEmpty) return clean;
  return clean[0].toUpperCase() + clean.substring(1);
}

/// Estilo monoespaciado del sistema, el único texto de los exports que no va
/// en Archivo: fechas del historial, folios y el rótulo del andén.
///
/// Android resuelve `monospace`; en los goldens se sustituye por Archivo (ver
/// `modernist_golden_harness.dart`).
TextStyle modernistMono({required double size, required Color color}) =>
    TextStyle(
      fontFamily: 'monospace',
      fontFamilyFallback: const ['Courier'],
      fontSize: size,
      letterSpacing: size * 0.08,
      color: color,
    );

/// Colores que **no** dependen del tema: son idénticos en claro y en oscuro.
abstract final class ModernistColors {
  /// Rojo de marca. Rellena el banner del viaje, el botón primario, la regla
  /// de la pestaña activa y el punto de posición del mapa — en ambos temas.
  static const Color red = Color(0xFFC80000);

  /// Texto y elementos sobre el rojo de marca.
  static const Color onRed = Color(0xFFFFFFFF);

  /// Color de marca del nivel. Espeja `niveles_operador.color_hex` del seed;
  /// difiere de `AppColors` en platino y diamante — manda la BD.
  static Color level(OperatorLevel level) => switch (level) {
        OperatorLevel.plata => const Color(0xFFC0C0C0),
        OperatorLevel.oro => const Color(0xFFFFD700),
        OperatorLevel.platino => const Color(0xFFE5E4E2),
        OperatorLevel.esmeralda => const Color(0xFF50C878),
        OperatorLevel.diamante => const Color(0xFFB9F2FF),
      };
}

/// Los colores que sí cambian entre el export claro y el oscuro.
///
/// Se resuelve con [ModernistPalette.of], que lee el brillo del tema activo —
/// así la pantalla respeta el selector de tema que ya existe en Ajustes.
@immutable
class ModernistPalette {
  const ModernistPalette({
    required this.bg,
    required this.sectionBg,
    required this.ink,
    required this.onInk,
    required this.kicker,
    required this.note,
    required this.bodyMuted,
    required this.bodyStrong,
    required this.disabled,
    required this.neutralMark,
    required this.outlineMuted,
    required this.progressTrack,
    required this.onPositive,
    required this.positiveSurface,
    required this.activeRowBg,
    required this.rankUp,
    required this.rankDown,
    required this.danger,
    required this.positive,
    required this.accentText,
    required this.link,
    required this.scrim,
    required this.rowDivider,
    required this.mapBg,
    required this.mapHillFront,
    required this.mapHillBack,
    required this.mapGrid,
    required this.routePending,
    required this.routeDone,
    required this.routeHalo,
    required this.isDark,
  });

  static const light = ModernistPalette(
    bg: Color(0xFFF3F2F2),
    sectionBg: Color(0xFFEAE9E9),
    ink: Color(0xFF201E1D),
    onInk: Color(0xFFF3F2F2),
    kicker: Color(0xFF7D7979),
    note: Color(0xFF605D5D),
    bodyMuted: Color(0xFF444141),
    bodyStrong: Color(0xFF444141),
    disabled: Color(0xFF9B9797),
    neutralMark: Color(0xFF807C7C),
    outlineMuted: Color(0xFFBAB6B6),
    progressTrack: Color(0xFFD7D3D3),
    onPositive: Color(0xFFFFFFFF),
    positiveSurface: Color(0xFFEAF5EE),
    activeRowBg: Color(0xFFFFF0F0),
    rankUp: Color(0xFF1C7A3E),
    rankDown: Color(0xFFC80000),
    danger: Color(0xFF8F0000),
    positive: Color(0xFF1A7A3C),
    accentText: Color(0xFFC80000),
    link: Color(0xFF8F0000),
    scrim: Color(0x8C201E1D), // rgba(32,30,29,.55)
    rowDivider: Color(0x66201E1D), // rgba(32,30,29,.4)
    mapBg: Color(0xFFD7D3D3),
    mapHillFront: Color(0xFFCFCBCB),
    mapHillBack: Color(0xFFDCD8D8),
    mapGrid: Color(0xFFBAB6B6),
    routePending: Color(0xFF605D5D),
    routeDone: Color(0xFF201E1D),
    routeHalo: Color(0xFFF3F2F2),
    isDark: false,
  );

  static const dark = ModernistPalette(
    bg: Color(0xFF2D2B2B),
    sectionBg: Color(0xFF3A3838),
    ink: Color(0xFFF3F2F2),
    onInk: Color(0xFF201E1D),
    kicker: Color(0xFF9B9797),
    note: Color(0xFFBAB6B6),
    bodyMuted: Color(0xFF565353),
    bodyStrong: Color(0xFFEAE9E9),
    disabled: Color(0xFF8E8A8A),
    neutralMark: Color(0xFF6E6A6A),
    outlineMuted: Color(0xFF807C7C),
    progressTrack: Color(0xFF565353),
    onPositive: Color(0xFF14301F),
    positiveSurface: Color(0xFF16301F),
    activeRowBg: Color(0xFF4A0F0F),
    rankUp: Color(0xFF4FBE7C),
    rankDown: Color(0xFFFF6A52),
    danger: Color(0xFFFF8A8A),
    positive: Color(0xFF7DDB9B),
    accentText: Color(0xFFFF8A8A),
    link: Color(0xFFFF8A8A),
    scrim: Color(0xB3000000), // rgba(0,0,0,.7)
    rowDivider: Color(0x52F3F2F2), // rgba(243,242,242,.32)
    mapBg: Color(0xFF565353),
    mapHillFront: Color(0xFF4A4747),
    mapHillBack: Color(0xFF565353),
    mapGrid: Color(0xFF807C7C),
    routePending: Color(0xFFBAB6B6),
    routeDone: Color(0xFFF3F2F2),
    routeHalo: Color(0xFF2D2B2B),
    isDark: true,
  );

  static ModernistPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;

  /// Fondo de la pantalla y de las barras.
  final Color bg;

  /// Fondo de una sección que debe despegarse del resto — la escena del
  /// almacén en «Inicio sin viaje».
  final Color sectionBg;

  /// Texto principal y las reglas de 2 px que estructuran la pantalla.
  final Color ink;

  /// Texto sobre un bloque relleno de [ink] (el chip «Desliza para ver más»).
  final Color onInk;

  /// Rótulos en versalitas (`RENDIMIENTO`, `NIVEL`, …).
  final Color kicker;

  /// Notas al pie de cada stat (`km/l · meta 4.5`).
  final Color note;

  /// Párrafos largos de texto corrido. En oscuro baja de tono para no
  /// competir con los datos.
  final Color bodyMuted;

  /// Texto de lista o notas cortas. Es la contraparte de [bodyMuted] que en
  /// oscuro **sube** de tono en vez de bajar, porque se lee de un vistazo.
  final Color bodyStrong;

  /// Elementos inertes: un viaje cancelado, una fila sin acción.
  final Color disabled;

  /// Marca de un evento sin gravedad propia — la incidencia en el mapa de la
  /// ruta, el recuadro de severidad. Contrasta contra el rojo de las alertas.
  final Color neutralMark;

  /// Contorno de lo que todavía no se alcanza: el riel y los nodos apagados
  /// de la ruta de premios, el borde de una tarjeta bloqueada.
  final Color outlineMuted;

  /// Canal vacío de una barra de progreso.
  final Color progressTrack;

  /// Texto sobre un relleno de [positive].
  final Color onPositive;

  /// Fondo tenue para destacar un total en positivo.
  final Color positiveSurface;

  /// Fondo de la fila del viaje en curso dentro del historial.
  final Color activeRowBg;

  /// Lugares ganados en el ranking. **No** es [positive]: los exports le dan
  /// su propio verde al movimiento de posiciones.
  final Color rankUp;

  /// Lugares perdidos. Tampoco es [danger] — en oscuro tira a naranja.
  final Color rankDown;

  /// Cifra de alertas y el motivo ya enviado.
  final Color danger;

  /// Puntos estimados.
  final Color positive;

  /// Etiqueta de la pestaña activa. Ojo: la regla superior de esa pestaña se
  /// queda en [ModernistColors.red] en ambos temas — solo cambia el texto.
  final Color accentText;

  /// Color de enlace (`a { color: … }` en la hoja del export).
  ///
  /// Vale la pena tenerlo aparte aunque hoy coincida con [danger]: en el HTML
  /// varios textos no declaran color y **heredan este** por estar dentro de un
  /// `<a>` — el nombre del nivel en el chip de la cabecera es el primer caso.
  /// Es fácil pasarlo por alto al portar y sale un texto en tinta donde el
  /// mockup lo tiene en rojo.
  final Color link;

  /// Velo detrás del panel de reporte.
  final Color scrim;

  /// Separador entre motivos del panel de reporte.
  final Color rowDivider;

  final Color mapBg;
  final Color mapHillFront;
  final Color mapHillBack;
  final Color mapGrid;
  final Color routePending;
  final Color routeDone;

  /// Halo bajo el punto de posición: es el fondo del mapa recortando la ruta.
  final Color routeHalo;

  final bool isDark;
}

/// Escala de espaciado del sistema (`--space-*`).
abstract final class ModernistSpace {
  static const double x1 = 4;
  static const double x2 = 8;
  static const double x3 = 12;
  static const double x4 = 16;
  static const double x6 = 24;
  static const double x8 = 32;
}

/// Grosor de las reglas que dividen las secciones. El sistema usa 2 px casi en
/// todos lados y 3 px solo en la pestaña activa.
abstract final class ModernistRule {
  static const double thin = 1;
  static const double base = 2;
  static const double tab = 3;
}

/// Constructor de estilos de texto sobre la fuente variable Archivo.
///
/// Flutter no instancia el eje `wght` a partir del `weight:` declarado en
/// pubspec, así que hay que pedirlo con `fontVariations` en cada estilo. Este
/// helper es el único lugar que lo sabe.
///
/// `tracking` va en **em** igual que el CSS del export
/// (`letter-spacing: .14em`); aquí se convierte a px lógicos multiplicando por
/// el tamaño de la fuente.
///
/// El color es obligatorio a propósito: con dos temas vivos, un color por
/// omisión sería un bug esperando a que alguien lo herede en la pantalla
/// equivocada.
abstract final class ModernistType {
  static const String family = 'Archivo';

  static TextStyle of({
    required double size,
    required int weight,
    required Color color,
    double tracking = 0,
    double? height,
  }) {
    return TextStyle(
      fontFamily: family,
      fontSize: size,
      color: color,
      height: height,
      letterSpacing: tracking * size,
      fontWeight: _weight(weight),
      fontVariations: [FontVariation('wght', weight.toDouble())],
    );
  }

  /// Rótulo en versalitas: el patrón que se repite sobre cada dato.
  static TextStyle kicker({
    required double size,
    required double tracking,
    required Color color,
    int weight = 700,
  }) =>
      of(size: size, weight: weight, color: color, tracking: tracking);

  /// Cifra grande de un stat: peso 900 y tracking negativo.
  static TextStyle figure({required double size, required Color color}) => of(
        size: size,
        weight: 900,
        color: color,
        tracking: -0.02,
        height: 1.05,
      );

  static FontWeight _weight(int w) => switch (w) {
        <= 400 => FontWeight.w400,
        <= 500 => FontWeight.w500,
        <= 600 => FontWeight.w600,
        <= 700 => FontWeight.w700,
        <= 800 => FontWeight.w800,
        _ => FontWeight.w900,
      };
}
