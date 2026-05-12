import '../balance/balance_data.dart';
import '../models/block_type.dart';
import '../models/package.dart';

/// Pure scoring + combo state machine for the block-puzzle. Each
/// successful placement calls [registerPlacement]; the returned
/// [PlacementRecord] holds the delta the HUD should reflect.
///
/// Scoring rules:
///   • Placing N cells of type T → `N × blockOf(T).baseScore / cellWeight`
///     (we use the block's `baseScore` as a per-cell multiplier so chunky
///     pieces feel weightier).
///   • Clearing K lines in one placement → `K × clearLineBonus`
///     + `(K-1) × multiClearBonusPerExtraLine` (combo bonus).
///   • If the placement leaves the board empty → `perfectClearBonus`.
///   • All bonuses scale by the current combo multiplier
///     (`1 + combo × comboMultiplierStep`, capped at `comboMultiplierCap`).
///   • Combo increments on any placement that clears ≥1 line, resets to 0
///     on a placement that clears nothing.
class ScoreService {
  ScoreService(this._balance);

  final BalanceData _balance;

  int _score = 0;
  int _combo = 0;
  int _maxCombo = 0;
  final List<PlacementRecord> _records = [];

  int get score => _score;
  int get combo => _combo;
  int get maxCombo => _maxCombo;
  int get lastPoints => _records.isEmpty ? 0 : _records.last.scoreDelta;
  List<PlacementRecord> get records => List.unmodifiable(_records);

  double get comboMultiplier {
    final econ = _balance.economy;
    final m = 1.0 + (_combo * econ.comboMultiplierStep);
    return m > econ.comboMultiplierCap ? econ.comboMultiplierCap : m;
  }

  /// Register a successful piece placement.
  ///
  /// [type] is the block type for the piece (drives per-cell scoring).
  /// [cellsPlaced] is the count of cells the piece occupies.
  /// [linesCleared] is the rows + columns cleared by this placement (0+).
  /// [boardCleared] is true when the placement leaves the board empty.
  PlacementRecord registerPlacement({
    required int pieceId,
    required BlockType type,
    required int cellsPlaced,
    required int linesCleared,
    required bool boardCleared,
  }) {
    final econ = _balance.economy;
    final desc = _balance.blockOf(type);

    // Per-cell placement award (small, rewards every drop).
    var raw = cellsPlaced * (desc.baseScore ~/ 5).clamp(1, 999);

    if (linesCleared > 0) {
      raw += linesCleared * econ.clearLineBonus;
      if (linesCleared > 1) {
        raw += (linesCleared - 1) * econ.multiClearBonusPerExtraLine;
      }
      raw += econ.perfectBonus;
      _combo += 1;
    } else {
      _combo = 0;
    }
    if (boardCleared) raw += econ.perfectClearBonus;
    if (_combo > _maxCombo) _maxCombo = _combo;

    final scaled = (raw * comboMultiplier).round();
    _score += scaled;
    if (_score < 0) _score = 0;
    final coins = scaled > 0 ? (scaled * econ.coinPerScorePoint).round() : 0;

    final record = PlacementRecord(
      pieceId: pieceId,
      type: type,
      cellsPlaced: cellsPlaced,
      linesCleared: linesCleared,
      scoreDelta: scaled,
      coinDelta: coins,
    );
    _records.add(record);
    return record;
  }

  void reset() {
    _score = 0;
    _combo = 0;
    _maxCombo = 0;
    _records.clear();
  }

  int get coinTotal => _records.fold<int>(0, (acc, r) => acc + r.coinDelta);
}
