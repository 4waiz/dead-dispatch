import '../../core/constants.dart';
import '../../core/failures.dart';
import '../../core/result.dart';

/// Migrates a save JSON map from any earlier schema version to the current
/// one. Each migration is a pure function `Map -> Map`; we apply them in
/// order until the version matches.
///
/// Adding a new migration:
///   1. Bump `AppConstants.saveSchemaVersion`.
///   2. Append a function below keyed at the previous version.
///   3. Add a unit test in `test/data/save_migrator_test.dart`.
class SaveMigrator {
  const SaveMigrator();

  Result<Map<String, Object?>> migrate(Map<String, Object?> raw) {
    var current = Map<String, Object?>.from(raw);
    final originalVersion = (current['schemaVersion'] as num?)?.toInt() ?? 0;
    if (originalVersion > AppConstants.saveSchemaVersion) {
      return Err(SaveMigrationFailure(
        'Save schema $originalVersion is newer than supported '
        '(${AppConstants.saveSchemaVersion}). Refusing to downgrade.',
      ));
    }
    var v = originalVersion;
    while (v < AppConstants.saveSchemaVersion) {
      final step = _migrations[v];
      if (step == null) {
        return Err(SaveMigrationFailure('No migration registered from v$v'));
      }
      try {
        current = step(current);
        v += 1;
        current['schemaVersion'] = v;
      } catch (e) {
        return Err(SaveMigrationFailure('Migration v$v failed: $e'));
      }
    }
    return Ok(current);
  }

  /// Registered migrations: key = "from version", value = transformer.
  static final Map<int, Map<String, Object?> Function(Map<String, Object?>)>
      _migrations = {
    // v0 → v1 fills out the initial shape for any pre-release dev save.
    0: (raw) {
      final now = DateTime.now().toIso8601String();
      return {
        'schemaVersion': 1,
        'createdAt': raw['createdAt'] ?? now,
        'lastPlayedAt': raw['lastPlayedAt'] ?? now,
        'tutorialCompleted': raw['tutorialCompleted'] ?? false,
        'totalShiftsPlayed': raw['totalShiftsPlayed'] ?? 0,
        'bestShiftScore': raw['bestShiftScore'] ?? 0,
        'wallet': raw['wallet'] ?? <String, Object?>{},
        'upgrades': raw['upgrades'] ?? const <Object?>[],
        'restoredDepartments':
            raw['restoredDepartments'] ?? const <Object?>[],
        'dailyAttempts': raw['dailyAttempts'] ?? const <Object?>[],
        'settings': raw['settings'] ?? const <String, Object?>{},
      };
    },
    // v1 → v2 (block-puzzle pivot): rename conveyor-era upgrade kinds in
    // the persisted upgrades list. PlayerProfile shape is otherwise
    // identical, so no structural surgery is required.
    1: (raw) {
      const renames = <String, String>{
        'beltSpeedTolerance': 'bagSoftness',
        'stampSupply': 'stampBlastCharges',
        'hazardWarning': 'modifierTelegraph',
      };
      final upgrades = raw['upgrades'];
      if (upgrades is List) {
        final migrated = upgrades.map((entry) {
          if (entry is Map<String, Object?>) {
            final kind = entry['kind'];
            if (kind is String && renames.containsKey(kind)) {
              return <String, Object?>{...entry, 'kind': renames[kind]};
            }
          }
          return entry;
        }).toList();
        return <String, Object?>{...raw, 'upgrades': migrated};
      }
      return raw;
    },
  };
}
