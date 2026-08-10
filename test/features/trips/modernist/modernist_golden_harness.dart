import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Lienzo del `android-frame.jsx` de los exports. Todos los goldens del
/// sistema Modernist se comparan a esta medida.
const modernistViewport = Size(412, 880);

/// Deja el entorno de pruebas listo para comparar contra un export.
///
/// Hay que llamarlo antes del `pumpWidget`:
///
/// - Sin Archivo cargada, el golden sale con la fuente de prueba y no sirve
///   para comparar contra el mockup.
/// - Los formatos de fecha en español (`dd MMM yyyy`) lanzan sin los símbolos
///   de la configuración regional.
/// - El entorno no tiene fuentes del sistema, así que los textos que piden
///   `monospace` —el rótulo del andén, las fechas del historial— saldrían como
///   cuadros. Se registra Archivo bajo ese nombre para poder verificar
///   posición, tamaño y contenido; en el dispositivo sí se ven monoespaciados,
///   así que **ese es el único punto donde el golden y la app difieren**.
Future<void> setUpModernistGolden(WidgetTester tester) async {
  await initializeDateFormatting('es_MX');

  for (final family in ['Archivo', 'monospace']) {
    final loader = FontLoader(family)
      ..addFont(rootBundle.load('assets/fonts/Archivo.ttf'));
    await loader.load();
  }

  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = modernistViewport;
  addTearDown(tester.view.reset);
}

/// Los dos temas que trae cada export, para recorrerlos en un `for`.
const modernistThemes = <(String, Brightness)>[
  ('claro', Brightness.light),
  ('oscuro', Brightness.dark),
];
