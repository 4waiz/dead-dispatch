import 'package:dead_dispatch/core/constants.dart';
import 'package:dead_dispatch/core/result.dart';
import 'package:dead_dispatch/data/migrations/save_migrator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SaveMigrator', () {
    const migrator = SaveMigrator();

    test('v0 upgrades to current schema', () {
      final result = migrator.migrate(<String, Object?>{});
      expect(result, isA<Ok<Map<String, Object?>>>());
      final map = (result as Ok<Map<String, Object?>>).value;
      expect(map['schemaVersion'], AppConstants.saveSchemaVersion);
      expect(map['tutorialCompleted'], false);
      expect(map['totalShiftsPlayed'], 0);
    });

    test('already-current save passes through untouched except version', () {
      final input = <String, Object?>{
        'schemaVersion': AppConstants.saveSchemaVersion,
        'tutorialCompleted': true,
      };
      final out = migrator.migrate(input);
      expect(out.valueOrNull?['tutorialCompleted'], true);
    });

    test('newer-than-supported save is rejected', () {
      final out = migrator
          .migrate({'schemaVersion': AppConstants.saveSchemaVersion + 1});
      expect(out.isErr, isTrue);
    });
  });
}
