import 'package:freezed_annotation/freezed_annotation.dart';

part 'operator_session.freezed.dart';

@freezed
sealed class OperatorSession with _$OperatorSession {
  const factory OperatorSession({
    required String operatorId,
    required String employeeNumber,
    required bool isAuthenticated,
  }) = _OperatorSession;

  factory OperatorSession.unauthenticated() => const OperatorSession(
        operatorId: '',
        employeeNumber: '',
        isAuthenticated: false,
      );
}
