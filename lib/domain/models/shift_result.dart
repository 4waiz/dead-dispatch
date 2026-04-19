import 'package.dart';

/// Final tally for one shift. Consumed by the result screen, economy
/// service (to award currency), and progression service (to bump XP).
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
  final List<SortRecord> records;
  final bool completed;
  final String? failureReason;
  final Duration duration;

  int get perfects =>
      records.where((r) => r.outcome == SortOutcome.perfect).length;
  int get misses => records.where((r) => r.outcome == SortOutcome.miss).length;
  int get destroyed =>
      records.where((r) => r.outcome == SortOutcome.destroyed).length;
}
