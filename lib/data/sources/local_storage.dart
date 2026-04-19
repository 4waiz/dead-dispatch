import 'package:shared_preferences/shared_preferences.dart';

import '../../core/failures.dart';
import '../../core/result.dart';

/// Thin wrapper over SharedPreferences. Repositories depend on this
/// abstraction so we can later swap to Hive / sqlite without a domain change.
abstract class KeyValueStorage {
  Future<Result<String?>> readString(String key);
  Future<Result<void>> writeString(String key, String value);
  Future<Result<void>> remove(String key);
  Future<Result<int?>> readInt(String key);
  Future<Result<void>> writeInt(String key, int value);
}

class SharedPrefsStorage implements KeyValueStorage {
  SharedPrefsStorage(this._prefs);

  final SharedPreferences _prefs;

  static Future<SharedPrefsStorage> open() async {
    final prefs = await SharedPreferences.getInstance();
    return SharedPrefsStorage(prefs);
  }

  @override
  Future<Result<String?>> readString(String key) async {
    try {
      return Ok(_prefs.getString(key));
    } catch (e) {
      return Err(StorageFailure('readString($key) failed: $e'));
    }
  }

  @override
  Future<Result<void>> writeString(String key, String value) async {
    try {
      await _prefs.setString(key, value);
      return const Ok(null);
    } catch (e) {
      return Err(StorageFailure('writeString($key) failed: $e'));
    }
  }

  @override
  Future<Result<void>> remove(String key) async {
    try {
      await _prefs.remove(key);
      return const Ok(null);
    } catch (e) {
      return Err(StorageFailure('remove($key) failed: $e'));
    }
  }

  @override
  Future<Result<int?>> readInt(String key) async {
    try {
      return Ok(_prefs.getInt(key));
    } catch (e) {
      return Err(StorageFailure('readInt($key) failed: $e'));
    }
  }

  @override
  Future<Result<void>> writeInt(String key, int value) async {
    try {
      await _prefs.setInt(key, value);
      return const Ok(null);
    } catch (e) {
      return Err(StorageFailure('writeInt($key) failed: $e'));
    }
  }
}
