import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:operadorapp/features/profile/domain/entities/operator_profile.dart';

part 'ranking_entry.freezed.dart';

// ─── Periodo ─────────────────────────────────────────────────────────────────

enum RankingPeriodo { global, mensual }

extension RankingPeriodoX on RankingPeriodo {
  String get value => switch (this) {
        RankingPeriodo.global => 'global',
        RankingPeriodo.mensual => 'mensual',
      };

  String get displayName => switch (this) {
        RankingPeriodo.global => 'Histórico',
        RankingPeriodo.mensual => 'Este mes',
      };

  static RankingPeriodo fromString(String value) => switch (value) {
        'mensual' => RankingPeriodo.mensual,
        _ => RankingPeriodo.global,
      };
}

// ─── Movimiento de lugares ───────────────────────────────────────────────────

enum RankingTrend {
  /// Ganó lugares respecto al último corte
  subio,

  /// Perdió lugares respecto al último corte
  bajo,

  /// Misma posición que el último corte
  igual,

  /// Sin corte previo con el cual comparar
  nuevo,
}

// ─── Entry ───────────────────────────────────────────────────────────────────

@freezed
sealed class RankingEntry with _$RankingEntry {
  const factory RankingEntry({
    required String operadorId,
    required String numeroEmpleado,
    required String nombreCompleto,
    required OperatorLevel nivel,
    required int puntos,
    required int viajesCompletados,
    required int posicion,
    double? calificacion,
    String? fotoPerfilUrl,
    int? posicionAnterior,
  }) = _RankingEntry;

  const RankingEntry._();

  /// Lugares ganados (positivo) o perdidos (negativo); null si no hay
  /// snapshot previo. La posición 1 es la mejor, por eso la resta se invierte.
  int? get lugaresMovidos =>
      posicionAnterior == null ? null : posicionAnterior! - posicion;

  RankingTrend get trend {
    final delta = lugaresMovidos;
    if (delta == null) return RankingTrend.nuevo;
    if (delta > 0) return RankingTrend.subio;
    if (delta < 0) return RankingTrend.bajo;
    return RankingTrend.igual;
  }

  /// Magnitud del movimiento, siempre positiva (para pintar "▲ 2").
  int get lugaresMovidosAbs => (lugaresMovidos ?? 0).abs();

  bool get esPodio => posicion <= 3;

  /// Iniciales para el avatar cuando no hay foto.
  String get iniciales {
    final partes = nombreCompleto.trim().split(RegExp(r'\s+'));
    if (partes.isEmpty || partes.first.isEmpty) return '?';
    if (partes.length == 1) return partes.first.substring(0, 1).toUpperCase();
    return (partes.first.substring(0, 1) + partes[1].substring(0, 1))
        .toUpperCase();
  }
}
