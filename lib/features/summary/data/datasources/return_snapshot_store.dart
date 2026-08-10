import 'package:operadorapp/features/profile/domain/entities/operator_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Foto del estado del operador al cerrar la app. Es el punto de comparación
/// del resumen de regreso.
class ReturnSnapshot {
  const ReturnSnapshot({
    required this.savedAt,
    required this.points,
    required this.level,
    this.rankGlobal,
  });

  final DateTime savedAt;
  final int points;
  final OperatorLevel level;
  final int? rankGlobal;
}

/// Persiste el snapshot en SharedPreferences.
///
/// El valor anterior se captura UNA vez, al construir el store, y se conserva
/// en memoria aunque después se sobrescriba en disco. Sin eso, guardar el
/// snapshot nuevo borraría la referencia contra la que se calcula el resumen
/// —el bug que dejaba muerta a la vista de bienvenida original, que escribía
/// el timestamp en `initState` antes de leerlo—.
///
/// Ese punto de comparación solo se mueve cuando alguien llama a [rotate]: al
/// volver del segundo plano, porque lo guardado al salir es exactamente lo que
/// el operador ya vio.
class ReturnSnapshotStore {
  ReturnSnapshotStore(this._prefs) : _previous = _read(_prefs);

  static const _kSavedAt = 'return_summary_saved_at_ms';
  static const _kPoints = 'return_summary_points';
  static const _kLevel = 'return_summary_level';
  static const _kRank = 'return_summary_rank_global';

  final SharedPreferences _prefs;
  ReturnSnapshot? _previous;

  /// Último snapshot escrito en esta sesión, aún no promovido a [previous].
  ReturnSnapshot? _latest;

  /// Snapshot de la sesión anterior; null en el primer arranque.
  ReturnSnapshot? get previous => _previous;

  /// Convierte el último snapshot guardado en el nuevo punto de comparación.
  ///
  /// Se guarda el valor en memoria en vez de releer SharedPreferences para no
  /// depender de que la escritura en disco haya terminado: entre el `paused` y
  /// el `resumed` puede pasar menos de lo que tarda el canal de plataforma.
  void rotate() {
    if (_latest != null) _previous = _latest;
  }

  static ReturnSnapshot? _read(SharedPreferences prefs) {
    final savedAtMs = prefs.getInt(_kSavedAt);
    if (savedAtMs == null) return null;

    return ReturnSnapshot(
      savedAt: DateTime.fromMillisecondsSinceEpoch(savedAtMs),
      points: prefs.getInt(_kPoints) ?? 0,
      level: OperatorLevelX.fromString(
        prefs.getString(_kLevel) ?? 'plata',
      ),
      rankGlobal: prefs.getInt(_kRank),
    );
  }

  Future<void> save({
    required int points,
    required OperatorLevel level,
    int? rankGlobal,
  }) async {
    final savedAt = DateTime.now();
    // Antes de cualquier `await`: quien llame con `unawaited` desde
    // `didChangeAppLifecycleState` necesita que el valor quede registrado ya.
    _latest = ReturnSnapshot(
      savedAt: savedAt,
      points: points,
      level: level,
      rankGlobal: rankGlobal,
    );

    await _prefs.setInt(_kSavedAt, savedAt.millisecondsSinceEpoch);
    await _prefs.setInt(_kPoints, points);
    await _prefs.setString(_kLevel, level.name);

    if (rankGlobal == null) {
      await _prefs.remove(_kRank);
    } else {
      await _prefs.setInt(_kRank, rankGlobal);
    }
  }
}
