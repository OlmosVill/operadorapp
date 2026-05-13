import 'package:freezed_annotation/freezed_annotation.dart';

part 'security_alert.freezed.dart';

@freezed
sealed class SecurityAlert with _$SecurityAlert {
  const factory SecurityAlert({
    required String id,
    required String viajeId,
    required String tipo,
    required DateTime timestampAlerta,
    double? valorMedido,
    double? umbralPermitido,
    double? lat,
    double? lng,
    @Default(0) int impactoPuntos,
  }) = _SecurityAlert;
}
