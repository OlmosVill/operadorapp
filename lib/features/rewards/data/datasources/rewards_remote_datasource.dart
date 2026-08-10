import 'package:operadorapp/features/rewards/domain/entities/premio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Error de la Edge Function `canjear-premio` con el motivo que dio el
/// servidor («Puntos insuficientes», «Premio no encontrado o inactivo»…).
class CanjeRejected implements Exception {
  const CanjeRejected(this.message, this.statusCode);

  final String message;
  final int statusCode;

  @override
  String toString() => message;
}

class RewardsRemoteDatasource {
  const RewardsRemoteDatasource(this._supabase);

  final SupabaseClient _supabase;

  Future<Canje> canjearPremio({
    required String premioId,
    required String operadorId,
  }) async {
    final FunctionResponse result;
    try {
      result = await _supabase.functions.invoke(
        'canjear-premio',
        body: {'premio_id': premioId, 'operador_id': operadorId},
      );
    } on FunctionException catch (e) {
      // `invoke` lanza en cualquier respuesta fuera de 2xx; el cuerpo trae el
      // motivo. Sin esto la pantalla solo podía decir «no se pudo».
      final details = e.details;
      final message = details is Map
          ? details['error'] as String? ?? 'Error al canjear'
          : 'Error al canjear';
      throw CanjeRejected(message, e.status);
    }

    final data = result.data;
    if (data is! Map<String, dynamic>) {
      throw const CanjeRejected('Respuesta inesperada del servidor', 500);
    }
    return _canjeFromMap(data);
  }

  static Canje _canjeFromMap(Map<String, dynamic> r) => Canje(
        id: r['id'] as String,
        operadorId: r['operador_id'] as String,
        premioId: r['premio_id'] as String,
        puntosCanjeados: r['puntos_canjeados'] as int,
        estado: CanjeEstadoX.fromString(r['estado'] as String),
        fechaSolicitud: DateTime.parse(r['fecha_solicitud'] as String).toUtc(),
        updatedAt: DateTime.parse(r['updated_at'] as String).toUtc(),
      );
}
