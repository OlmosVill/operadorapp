import 'package:freezed_annotation/freezed_annotation.dart';

part 'operator_profile.freezed.dart';

enum OperatorLevel { plata, oro, platino, esmeralda, diamante }

extension OperatorLevelX on OperatorLevel {
  String get displayName => switch (this) {
        OperatorLevel.plata => 'Plata',
        OperatorLevel.oro => 'Oro',
        OperatorLevel.platino => 'Platino',
        OperatorLevel.esmeralda => 'Esmeralda',
        OperatorLevel.diamante => 'Diamante',
      };

  OperatorLevel? get next => switch (this) {
        OperatorLevel.plata => OperatorLevel.oro,
        OperatorLevel.oro => OperatorLevel.platino,
        OperatorLevel.platino => OperatorLevel.esmeralda,
        OperatorLevel.esmeralda => OperatorLevel.diamante,
        OperatorLevel.diamante => null,
      };

  static OperatorLevel fromString(String value) => switch (value) {
        'oro' => OperatorLevel.oro,
        'platino' => OperatorLevel.platino,
        'esmeralda' => OperatorLevel.esmeralda,
        'diamante' => OperatorLevel.diamante,
        _ => OperatorLevel.plata,
      };
}

@freezed
sealed class OperatorProfile with _$OperatorProfile {
  const factory OperatorProfile({
    required String id,
    required String employeeNumber,
    required String fullName,
    required DateTime startDate,
    required OperatorLevel level,
    required int totalPoints,
    required int availablePoints,
    String? email,
    String? phone,
    String? base,
    String? profilePhotoUrl,
  }) = _OperatorProfile;
}
