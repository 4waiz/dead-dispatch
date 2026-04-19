import 'dart:convert';

import '../../core/constants.dart';
import '../../core/failures.dart';
import '../../core/result.dart';
import '../../domain/models/daily_challenge.dart';
import '../sources/local_storage.dart';

/// Persists daily attempt history separately so we can show streaks /
/// "best score today" without loading the whole profile blob.
class DailyRepository {
  DailyRepository(this._storage);
  final KeyValueStorage _storage;

  Future<Result<List<DailyAttempt>>> loadAll() async {
    final raw = await _storage.readString(AppConstants.kDaily);
    return raw.fold((value) {
      if (value == null || value.isEmpty) return const Ok([]);
      try {
        final list = (jsonDecode(value) as List).cast<Map<String, Object?>>();
        return Ok(list.map(DailyAttempt.fromJson).toList());
      } catch (e) {
        return Err(StorageFailure('Daily decode failed: $e'));
      }
    }, Err.new);
  }

  Future<Result<void>> saveAll(List<DailyAttempt> attempts) async {
    try {
      final payload = jsonEncode(attempts.map((a) => a.toJson()).toList());
      return _storage.writeString(AppConstants.kDaily, payload);
    } catch (e) {
      return Err(StorageFailure('Daily encode failed: $e'));
    }
  }

  Future<Result<DailyAttempt?>> latestFor(String dateKey) async {
    final all = await loadAll();
    return all.fold((list) {
      DailyAttempt? best;
      for (final a in list) {
        if (a.dateKey != dateKey) continue;
        if (best == null || a.score > best.score) best = a;
      }
      return Ok(best);
    }, Err.new);
  }
}
