import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:logger/logger.dart';
import 'package:operadorapp/core/errors/app_error.dart';
import 'package:operadorapp/core/services/sync_service.dart';
import 'package:operadorapp/features/profile/data/datasources/profile_local_datasource.dart';
import 'package:operadorapp/features/profile/domain/entities/operator_profile.dart';
import 'package:operadorapp/features/profile/domain/repositories/profile_repository.dart';

final class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl({
    required ProfileLocalDatasource localDatasource,
    required SyncService syncService,
    required Logger logger,
  })  : _local = localDatasource,
        _sync = syncService,
        _logger = logger;

  final ProfileLocalDatasource _local;
  final SyncService _sync;
  final Logger _logger;

  @override
  Stream<Either<AppError, OperatorProfile>> watchProfile({
    required String authUserId,
  }) async* {
    // Kick off background sync — does not block the stream
    unawaited(_sync.syncProfile(authUserId));

    await for (final profile in _local.watchProfile(authUserId)) {
      if (profile != null) {
        yield Right(profile);
      }
    }
  }

  @override
  Future<Either<AppError, OperatorProfile>> getProfile({
    required String authUserId,
  }) async {
    try {
      // 1. Check local cache
      final cached = await _local.getProfile(authUserId);
      if (cached != null) {
        // Background sync
        unawaited(_sync.syncProfile(authUserId));
        return Right(cached);
      }

      // 2. No cache — block on sync then read again
      await _sync.syncProfile(authUserId);
      final synced = await _local.getProfile(authUserId);

      if (synced == null) {
        return const Left(NotFoundError(resource: 'perfil de operador'));
      }

      return Right(synced);
    } on Exception catch (e, st) {
      _logger.e('getProfile error', error: e, stackTrace: st);
      return Left(UnexpectedError(error: e, stackTrace: st));
    }
  }
}
