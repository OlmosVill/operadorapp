import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Hora decimal 0–24 que ilumina la escena del tracto.
///
/// Hoy es la hora local del dispositivo, que es lo que
/// `docs/features/truck-animation.md` define para el MVP. Existe como provider
/// y no como `DateTime.now()` suelto por dos razones: es el punto donde
/// entrará `TruckTelemetryService` cuando se implemente, y permite fijar la
/// hora en tests para que los goldens no cambien según cuándo se corran.
final sceneTimeOfDayProvider = Provider<double>((ref) {
  final now = DateTime.now();
  return now.hour + now.minute / 60;
});
