import 'package:operadorapp/features/profile/domain/entities/operator_profile.dart';

/// Umbrales de nivel, alineados con `niveles_operador` en `seed.sql`.
///
/// El nivel lo decide el servidor en `fn_actualizar_puntos_operador()` a partir
/// de `puntos_ganados` (el acumulado histórico), NO de `puntos_disponibles`.
/// Cualquier barra de progreso tiene que usar `OperatorProfile.totalPoints`:
/// con `availablePoints` un canje haría "bajar de nivel" en la UI mientras el
/// servidor mantiene el nivel intacto.
const levelThresholds = <OperatorLevel, (int, int?)>{
  OperatorLevel.plata: (0, 4999),
  OperatorLevel.oro: (5000, 14999),
  OperatorLevel.platino: (15000, 29999),
  OperatorLevel.esmeralda: (30000, 59999),
  OperatorLevel.diamante: (60000, null),
};

/// Puntos con los que arranca el nivel.
int levelFloor(OperatorLevel level) => levelThresholds[level]?.$1 ?? 0;

/// Puntos necesarios para alcanzar el siguiente nivel; null en el máximo.
int? nextLevelPoints(OperatorLevel level) {
  final next = level.next;
  return next == null ? null : levelFloor(next);
}

/// Avance dentro del nivel actual, de 0 a 1. Devuelve 1 en el nivel máximo.
double levelProgress(int totalPoints, OperatorLevel level) {
  final target = nextLevelPoints(level);
  if (target == null) return 1;

  final floor = levelFloor(level);
  final span = target - floor;
  if (span <= 0) return 1;

  return ((totalPoints - floor) / span).clamp(0.0, 1.0);
}

/// Nivel que corresponde a un acumulado de puntos ganados.
OperatorLevel levelForPoints(int totalPoints) {
  var result = OperatorLevel.plata;
  for (final level in OperatorLevel.values) {
    if (totalPoints >= levelFloor(level)) result = level;
  }
  return result;
}
