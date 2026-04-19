/// Maps a calendar date (UTC) to a deterministic 32-bit seed.
///
/// We avoid `hashCode` here — Dart strings hash to platform-dependent values,
/// so two devices could pull different daily challenges for the same date.
/// FNV-1a is stable across platforms and trivially fast.
class DailySeed {
  const DailySeed._();

  /// `dateKey` must be `YYYY-MM-DD` (UTC). Pure function.
  static int seedFor(String dateKey) {
    const int prime = 16777619;
    int hash = 2166136261;
    for (var i = 0; i < dateKey.length; i++) {
      hash ^= dateKey.codeUnitAt(i);
      hash = (hash * prime) & 0xFFFFFFFF;
    }
    if (hash == 0) hash = 0xDEADBEEF;
    return hash;
  }

  static String dateKey(DateTime when) {
    final utc = when.toUtc();
    final y = utc.year.toString().padLeft(4, '0');
    final m = utc.month.toString().padLeft(2, '0');
    final d = utc.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static String todayKey() => dateKey(DateTime.now());
}
