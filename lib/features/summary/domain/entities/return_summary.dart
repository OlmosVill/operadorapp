import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:operadorapp/features/profile/domain/entities/level_thresholds.dart';
import 'package:operadorapp/features/profile/domain/entities/operator_profile.dart';
import 'package:operadorapp/features/trips/domain/entities/trip.dart';

part 'return_summary.freezed.dart';

/// Lo que pasó mientras la app estuvo cerrada.
///
/// Se calcula contra el snapshot guardado al cerrar la sesión anterior, no
/// contra un rango de tiempo fijo: así da igual si el operador estuvo fuera
/// dos horas o dos semanas, o si se le juntaron varios viajes.
@freezed
sealed class ReturnSummary with _$ReturnSummary {
  const factory ReturnSummary({
    /// Viajes cerrados desde la última vez que abrió la app
    required List<Trip> completedTrips,

    /// Puntos ganados acumulados antes y después del periodo ausente
    required int pointsBefore,
    required int pointsAfter,

    required OperatorLevel levelBefore,
    required OperatorLevel levelAfter,

    /// Momento del snapshot anterior — "desde entonces…"
    required DateTime since,

    /// Posición en el ranking global; null si no había dato
    int? rankBefore,
    int? rankAfter,
  }) = _ReturnSummary;

  const ReturnSummary._();

  /// Puntos ganados en el periodo. Se deriva del acumulado, no de la suma de
  /// movimientos, para que el número y la barra de progreso nunca se
  /// contradigan.
  int get pointsEarned => pointsAfter - pointsBefore;

  bool get leveledUp => levelAfter.index > levelBefore.index;

  /// Lugares ganados (positivo) o perdidos (negativo). null si falta un dato.
  int? get rankDelta => (rankBefore == null || rankAfter == null)
      ? null
      : rankBefore! - rankAfter!;

  double get progressBefore => levelProgress(pointsBefore, levelBefore);
  double get progressAfter => levelProgress(pointsAfter, levelAfter);

  /// Puntos que faltan para el siguiente nivel; null en el nivel máximo.
  int? get pointsToNextLevel {
    final target = nextLevelPoints(levelAfter);
    if (target == null) return null;
    final faltan = target - pointsAfter;
    return faltan < 0 ? 0 : faltan;
  }

  double get totalKm => completedTrips.fold<double>(
        0,
        (sum, t) => sum + (t.kmRecorridos ?? 0),
      );

  /// Si no hubo nada que contar, no se abre el popup: volver a entrar a los
  /// cinco minutos no debe disparar un resumen vacío.
  bool get hasContent =>
      completedTrips.isNotEmpty ||
      pointsEarned != 0 ||
      leveledUp ||
      (rankDelta ?? 0) != 0;
}
