import '../balance/balance_data.dart';
import '../models/currency.dart';
import '../models/department.dart';
import '../models/player_profile.dart';
import '../models/shift_result.dart';
import '../models/upgrade.dart';
import 'seeded_random.dart';

/// Awards currency from shift outcomes, applies upgrade-driven multipliers,
/// and exposes spend operations for upgrades / room restoration. Pure logic
/// — persistence is handled by repositories outside the domain.
class EconomyService {
  const EconomyService(this._balance);

  final BalanceData _balance;

  int payoutForShift({
    required PlayerProfile profile,
    required ShiftResult result,
  }) {
    final base = result.coins;
    final mult = 1.0 +
        profile.upgradeLevel(UpgradeKind.payoutMultiplier) * 0.10 +
        (result.completed ? 0.0 : -0.5);
    final dailyBonus =
        result.completed && _balance.economy.dailyCompletionBonus > 0
            ? _balance.economy.dailyCompletionBonus
            : 0;
    return ((base * mult) + dailyBonus).round().clamp(0, 1 << 30);
  }

  void award(PlayerProfile profile, int coins) {
    profile.wallet.add(Currency.coins, coins);
  }

  bool purchaseUpgrade(
    PlayerProfile profile, {
    required UpgradeKind kind,
  }) {
    final desc = _balance.upgradeOf(kind);
    if (desc == null) return false;
    final currentLevel = profile.upgradeLevel(kind);
    final nextLevel = currentLevel + 1;
    if (nextLevel > desc.maxLevel) return false;
    final cost = desc.costForLevel(nextLevel);
    if (cost < 0) return false;
    if (!profile.wallet.spend(desc.currency, cost)) return false;

    final idx = profile.upgrades.indexWhere((u) => u.kind == kind);
    if (idx >= 0) {
      profile.upgrades[idx] = OwnedUpgrade(kind: kind, level: nextLevel);
    } else {
      profile.upgrades.add(OwnedUpgrade(kind: kind, level: nextLevel));
    }
    return true;
  }

  bool restoreDepartment(
    PlayerProfile profile, {
    required String departmentId,
  }) {
    if (profile.isDepartmentRestored(departmentId)) return false;
    DepartmentDescriptor? dept;
    for (final d in _balance.departments) {
      if (d.id == departmentId) {
        dept = d;
        break;
      }
    }
    if (dept == null) return false;
    if (!profile.wallet.spend(Currency.coins, dept.restoreCost)) return false;
    profile.restoredDepartments.add(
      RestoredDepartment(id: departmentId, restoredAt: DateTime.now()),
    );
    return true;
  }

  /// Mystery parcel reward — used for the rewarded-ad placement on the
  /// shift-result screen. Deterministic via injected seed for replayable
  /// QA, otherwise time-seeded.
  int rollMysteryParcelReward({int? seed}) {
    final rng = SeededRandom(seed ?? DateTime.now().microsecondsSinceEpoch);
    final econ = _balance.economy;
    return rng.nextIntRange(econ.mysteryParcelMin, econ.mysteryParcelMax + 1);
  }
}
