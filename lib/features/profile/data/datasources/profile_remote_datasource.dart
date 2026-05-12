import 'package:operadorapp/features/profile/domain/entities/operator_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class ProfileRemoteDatasource {
  Future<Map<String, dynamic>> getProfile({required String authUserId});
}

final class SupabaseProfileDatasource implements ProfileRemoteDatasource {
  const SupabaseProfileDatasource(this._client);

  final SupabaseClient _client;

  // TODO(fase-2): Después de obtener el perfil remoto, persistir en Drift
  // para disponibilidad offline. El repositorio (no el datasource) orquestará
  // leer Drift primero y llamar aquí solo si hay conexión o el cache expiró.
  @override
  Future<Map<String, dynamic>> getProfile({required String authUserId}) {
    // PostgREST resuelve el join con puntos_operador automáticamente
    // porque puntos_operador.operador_id → operadores.id
    return _client
        .from('operadores')
        .select('*, puntos_operador(*)')
        .eq('auth_user_id', authUserId)
        .single();
  }
}

// Función de mapeo del JSON de Supabase a la entidad de dominio
OperatorProfile profileFromMap(Map<String, dynamic> map) {
  final puntosData = map['puntos_operador'] as Map<String, dynamic>?;
  return OperatorProfile(
    id: map['id'] as String,
    employeeNumber: map['numero_empleado'] as String,
    fullName: map['nombre_completo'] as String,
    startDate: DateTime.parse(map['fecha_ingreso'] as String),
    level: OperatorLevelX.fromString(map['nivel_actual'] as String? ?? 'plata'),
    totalPoints: puntosData?['puntos_ganados'] as int? ?? 0,
    availablePoints: puntosData?['puntos_disponibles'] as int? ?? 0,
    email: map['email'] as String?,
    phone: map['telefono'] as String?,
    base: map['base'] as String?,
    profilePhotoUrl: map['foto_perfil_url'] as String?,
  );
}
