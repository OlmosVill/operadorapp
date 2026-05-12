import 'package:fpdart/fpdart.dart';
import 'package:logger/logger.dart';
import 'package:operadorapp/core/errors/app_error.dart';
import 'package:operadorapp/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:operadorapp/features/profile/domain/entities/operator_profile.dart';
import 'package:operadorapp/features/profile/domain/repositories/profile_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl({
    required ProfileRemoteDatasource remoteDatasource,
    required Logger logger,
  })  : _remote = remoteDatasource,
        _logger = logger;

  final ProfileRemoteDatasource _remote;
  final Logger _logger;

  @override
  Future<Either<AppError, OperatorProfile>> getProfile({
    required String authUserId,
  }) async {
    try {
      final data = await _remote.getProfile(authUserId: authUserId);
      return Right(profileFromMap(data));
    } on PostgrestException catch (e) {
      _logger.w('Perfil no encontrado', error: e.message);
      if (e.code == 'PGRST116') {
        return const Left(NotFoundError(resource: 'perfil de operador'));
      }
      return Left(ServerError(statusCode: int.tryParse(e.code ?? '') ?? 500));
    } catch (e, st) {
      _logger.e('Error al cargar perfil', error: e, stackTrace: st);
      return Left(UnexpectedError(error: e, stackTrace: st));
    }
  }
}
