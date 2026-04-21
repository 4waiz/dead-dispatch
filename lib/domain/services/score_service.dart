import '../balance/balance_data.dart';
import '../models/package.dart';
import '../models/package_type.dart';

/// Pure scoring + combo state machine. The Flame world calls
/// [registerOutcome] when a parcel resolves; the result feeds the HUD and
/// (later) the economy service.
class ScoreService {
  ScoreService(this._balance);

  final BalanceData _balance;

  int _score = 0;
  int _combo = 0;
  int _maxCombo = 0;
  final List<SortRecord> _records = [];

  int get score => _score;
  int get combo => _combo;
  int get maxCombo => _maxCombo;
  int get lastPoints => _records.isEmpty ? 0 : _records.last.scoreDelta;
  List<SortRecord> get records => List.unmodifiable(_records);

  double get comboMultiplier {
    final econ = _balance.economy;
    final m = 1.0 + (_combo * econ.comboMultiplierStep);
    return m > econ.comboMultiplierCap ? econ.comboMultiplierCap : m;
  }

  SortRecord registerOutcome({
    required GamePackage package,
    required SortOutcome outcome,
  }) {
    final desc = _balance.packageOf(package.type);
    final econ = _balance.economy;

    int rawScore;
    switch (outcome) {
      case SortOutcome.perfect:
        rawScore = desc.baseScore + econ.perfectBonus;
        _combo += 1;
      case SortOutcome.acceptable:
        rawScore = desc.baseScore;
        _combo += 1;
      case SortOutcome.miss:
        rawScore = -desc.baseScore ~/ 2;
        _combo = 0;
      case SortOutcome.destroyed:
        rawScore = -desc.baseScore;
        _combo = 0;
    }

    final scaled = (rawScore * comboMultiplier).round();
    _score += scaled;
    if (_score < 0) _score = 0;
    if (_combo > _maxCombo) _maxCombo = _combo;

    final coins = scaled > 0 ? (scaled * econ.coinPerScorePoint).round() : 0;

    final record = SortRecord(
      packageId: package.id,
      type: package.type,
      outcome: outcome,
      scoreDelta: scaled,
      coinDelta: coins,
    );
    _records.add(record);
    return record;
  }

  /// Stamping a priority parcel before it resolves doesn't score on its own,
  /// but it makes the eventual outcome better — surfaced via `wasStamped`.
  bool isStampApplicableTo(PackageType type) {
    return _balance.packageOf(type).canStamp;
  }

  void reset() {
    _score = 0;
    _combo = 0;
    _maxCombo = 0;
    _records.clear();
  }

  int get coinTotal =>
      _records.fold<int>(0, (acc, r) => acc + (r.coinDelta));
}
