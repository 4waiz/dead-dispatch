import '../balance/balance_data.dart';
import '../models/department.dart';
import '../models/player_profile.dart';
import '../models/shift_result.dart';

/// Applies post-shift state changes that aren't strictly economy:
/// totals, best score, last-played timestamp.
///
/// Currency rewards live in [EconomyService] so the rewarded-ad path
/// (double rewards) can compose payouts without re-running stats logic.
class ProgressionService {
  const ProgressionService(this._balance);

  final BalanceData _balance;

  void recordShift(PlayerProfile profile, ShiftResult result) {
    profile.totalShiftsPlayed += 1;
    profile.lastPlayedAt = DateTime.now();
    if (result.score > profile.bestShiftScore) {
      profile.bestShiftScore = result.score;
    }
  }

  /// Departments visible in the restoration screen (already-restored ones
  /// stay visible to show the unlock fanfare).
  List<DepartmentDescriptor> visibleDepartments(PlayerProfile profile) {
    final list = [..._balance.departments];
    list.sort((a, b) {
      final f = a.floor.compareTo(b.floor);
      if (f != 0) return f;
      return a.restoreCost.compareTo(b.restoreCost);
    });
    return list;
  }

  /// Departments the player can currently *afford and unlock*.
  List<DepartmentDescriptor> nextRestorableDepartments(PlayerProfile profile) {
    final visible = visibleDepartments(profile);
    return visible
        .where((d) => !profile.isDepartmentRestored(d.id))
        .take(3)
        .toList(growable: false);
  }
}
