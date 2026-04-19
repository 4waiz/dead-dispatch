import 'dart:convert';

import '../../core/constants.dart';
import '../../core/failures.dart';
import '../../core/result.dart';
import '../../domain/models/player_profile.dart';
import '../sources/local_storage.dart';

/// Independent of the main save file so tweaking settings doesn't risk
/// corrupting progression.
class SettingsRepository {
  SettingsRepository(this._storage);
  final KeyValueStorage _storage;

  Future<Result<SettingsSnapshot>> load() async {
    final raw = await _storage.readString(AppConstants.kSettings);
    return raw.fold((value) {
      if (value == null || value.isEmpty) return const Ok(SettingsSnapshot());
      try {
        final m = jsonDecode(value) as Map<String, Object?>;
        return Ok(SettingsSnapshot.fromJson(m));
      } catch (e) {
        return Err(StorageFailure('Settings decode failed: $e'));
      }
    }, Err.new);
  }

  Future<Result<void>> save(SettingsSnapshot s) async {
    try {
      return _storage.writeString(
          AppConstants.kSettings, jsonEncode(s.toJson()));
    } catch (e) {
      return Err(StorageFailure('Settings encode failed: $e'));
    }
  }
}
