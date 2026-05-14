import 'package:operadorapp/features/rewards/domain/entities/premio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RewardsRemoteDatasource {
  const RewardsRemoteDatasource(this._supabase);

  final SupabaseClient _supabase;

  Future<Canje> canjearPremio({
    required String premioId,
    required String operadorId,
  }) async {
    final result = await _supabase.functions.invoke(
      'canjear-premio',
      body: {'premio_id': premioId, 'operador_id': operadorId},
    );
    if (result.status != 200) {
      final data = result.data as Map<String, dynamic>?;
      final msg = data?['error'] as String? ?? 'Error al canjear';
      throw Exception(msg);
    }
    return _canjeFromMap(result.data as Map<String, dynamic>);
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
