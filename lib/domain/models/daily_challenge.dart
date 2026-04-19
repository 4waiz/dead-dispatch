import 'shift_config.dart';

/// A daily challenge is just a deterministic [ShiftConfig] keyed by date.
class DailyChallenge {
  const DailyChallenge({
    required this.dateKey,
    required this.config,
    required this.modifierLabel,
  });

  /// `YYYY-MM-DD` in UTC. Acts as both the seed key and the storage key.
  final String dateKey;
  final ShiftConfig config;
  final String modifierLabel;
}

class DailyAttempt {
  const DailyAttempt({
    required this.dateKey,
    required this.score,
    required this.completed,
    required this.attemptedAt,
  });

  final String dateKey;
  final int score;
  final bool completed;
  final DateTime attemptedAt;

  Map<String, Object?> toJson() => {
        'dateKey': dateKey,
        'score': score,
        'completed': completed,
        'attemptedAt': attemptedAt.toIso8601String(),
      };

  factory DailyAttempt.fromJson(Map<String, Object?> j) => DailyAttempt(
        dateKey: j['dateKey']! as String,
        score: (j['score']! as num).toInt(),
        completed: j['completed']! as bool,
        attemptedAt: DateTime.parse(j['attemptedAt']! as String),
      );
}
