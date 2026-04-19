import 'dart:convert';

import '../../core/constants.dart';
import '../../core/failures.dart';
import '../../core/logger.dart';
import '../../core/result.dart';
import '../../domain/models/player_profile.dart';
import '../migrations/save_migrator.dart';
import '../sources/local_storage.dart';

/// Owns the lifecycle of the [PlayerProfile] on disk:
/// load → migrate → decode, and encode → write on save.
class SaveRepository {
  SaveRepository(this._storage, {SaveMigrator? migrator})
      : _migrator = migrator ?? const SaveMigrator();

  final KeyValueStorage _storage;
  final SaveMigrator _migrator;
  final AppLogger _log = AppLogger('SaveRepository');

  Future<Result<PlayerProfile>> load() async {
    final raw = await _storage.readString(AppConstants.kSaveFile);
    return raw.fold(
      (value) {
        if (value == null || value.isEmpty) {
          _log.i('No save found — creating fresh profile.');
          return Ok(PlayerProfile.fresh(AppConstants.saveSchemaVersion));
        }
        try {
          final decoded = jsonDecode(value) as Map<String, Object?>;
          final migrated = _migrator.migrate(decoded);
          return migrated.fold(
            (m) => Ok(PlayerProfile.fromJson(m)),
            (failure) {
              _log.w('Migration failed; falling back to fresh save: $failure');
              return Ok(PlayerProfile.fresh(AppConstants.saveSchemaVersion));
            },
          );
        } catch (e, st) {
          _log.e('Failed to decode save', e, st);
          return Err(StorageFailure('Save decode failed: $e'));
        }
      },
      Err.new,
    );
  }

  Future<Result<void>> save(PlayerProfile profile) async {
    try {
      profile.lastPlayedAt = DateTime.now();
      final encoded = jsonEncode(profile.toJson());
      return _storage.writeString(AppConstants.kSaveFile, encoded);
    } catch (e) {
      return Err(StorageFailure('Save encode failed: $e'));
    }
  }

  Future<Result<void>> wipe() => _storage.remove(AppConstants.kSaveFile);
}
