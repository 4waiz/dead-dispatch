import 'package.dart';

/// Final tally for one shift. Consumed by the result screen, economy
/// service (to award currency), and progression service (to bump best
/// score). `ShiftResult.coins` is the base payout; the economy service
/// applies upgrade multipliers and daily bonuses on top.
class ShiftResult {
  const ShiftResult({
    required this.shiftId,
    required this.score,
    required this.combo,
    required this.maxCombo,
    required this.coins,
    required this.records,
    required this.completed,
    required this.failureReason,
    required this.duration,
  });

  final String shiftId;
  final int score;
  final int combo;
  final int maxCombo;
  final int coins;
  final List<PlacementRecord> records;

  /// True when the player hit [ShiftConfig.targetScore] before game over.
  final bool completed;
  final String? failureReason;
  final Duration duration;

  /// Total rows + columns cleared across the whole shift.
  int get linesCleared =>
      records.fold<int>(0, (acc, r) => acc + r.linesCleared);

  /// Largest number of lines cleared by a single placement.
  int get biggestClear =>
      records.fold<int>(0, (acc, r) => r.linesCleared > acc ? r.linesCleared : acc);

  int get piecesPlaced => records.length;
}
