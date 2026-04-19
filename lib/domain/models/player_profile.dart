import 'currency.dart';
import 'daily_challenge.dart';
import 'department.dart';
import 'upgrade.dart';

/// The full persistable player state. Single root keeps save/load atomic.
class PlayerProfile {
  PlayerProfile({
    required this.schemaVersion,
    required this.createdAt,
    required this.lastPlayedAt,
    required this.tutorialCompleted,
    required this.totalShiftsPlayed,
    required this.bestShiftScore,
    required this.wallet,
    required this.upgrades,
    required this.restoredDepartments,
    required this.dailyAttempts,
    required this.settings,
  });

  final int schemaVersion;
  final DateTime createdAt;
  DateTime lastPlayedAt;
  bool tutorialCompleted;
  int totalShiftsPlayed;
  int bestShiftScore;
  final Wallet wallet;
  final List<OwnedUpgrade> upgrades;
  final List<RestoredDepartment> restoredDepartments;
  final List<DailyAttempt> dailyAttempts;
  final SettingsSnapshot settings;

  int upgradeLevel(UpgradeKind kind) =>
      upgrades.firstWhere(
        (u) => u.kind == kind,
        orElse: () => OwnedUpgrade(kind: kind, level: 0),
      ).level;

  bool isDepartmentRestored(String id) =>
      restoredDepartments.any((d) => d.id == id);

  /// Returns a new profile sharing all collections but with [settings]
  /// replaced. Used by the Settings screen so toggling a switch doesn't
  /// reach into private state.
  PlayerProfile copyWithSettings(SettingsSnapshot newSettings) => PlayerProfile(
        schemaVersion: schemaVersion,
        createdAt: createdAt,
        lastPlayedAt: lastPlayedAt,
        tutorialCompleted: tutorialCompleted,
        totalShiftsPlayed: totalShiftsPlayed,
        bestShiftScore: bestShiftScore,
        wallet: wallet,
        upgrades: upgrades,
        restoredDepartments: restoredDepartments,
        dailyAttempts: dailyAttempts,
        settings: newSettings,
      );

  Map<String, Object?> toJson() => {
        'schemaVersion': schemaVersion,
        'createdAt': createdAt.toIso8601String(),
        'lastPlayedAt': lastPlayedAt.toIso8601String(),
        'tutorialCompleted': tutorialCompleted,
        'totalShiftsPlayed': totalShiftsPlayed,
        'bestShiftScore': bestShiftScore,
        'wallet': wallet.toJson(),
        'upgrades': upgrades.map((u) => u.toJson()).toList(),
        'restoredDepartments':
            restoredDepartments.map((d) => d.toJson()).toList(),
        'dailyAttempts': dailyAttempts.map((d) => d.toJson()).toList(),
        'settings': settings.toJson(),
      };

  static PlayerProfile fromJson(Map<String, Object?> j) => PlayerProfile(
        schemaVersion: (j['schemaVersion']! as num).toInt(),
        createdAt: DateTime.parse(j['createdAt']! as String),
        lastPlayedAt: DateTime.parse(j['lastPlayedAt']! as String),
        tutorialCompleted: j['tutorialCompleted']! as bool,
        totalShiftsPlayed: (j['totalShiftsPlayed']! as num).toInt(),
        bestShiftScore: (j['bestShiftScore']! as num).toInt(),
        wallet: Wallet.fromJson(j['wallet']! as Map<String, Object?>),
        upgrades: (j['upgrades']! as List)
            .cast<Map<String, Object?>>()
            .map(OwnedUpgrade.fromJson)
            .toList(),
        restoredDepartments: (j['restoredDepartments']! as List)
            .cast<Map<String, Object?>>()
            .map(RestoredDepartment.fromJson)
            .toList(),
        dailyAttempts: (j['dailyAttempts']! as List)
            .cast<Map<String, Object?>>()
            .map(DailyAttempt.fromJson)
            .toList(),
        settings:
            SettingsSnapshot.fromJson(j['settings']! as Map<String, Object?>),
      );

  static PlayerProfile fresh(int schemaVersion) {
    final now = DateTime.now();
    return PlayerProfile(
      schemaVersion: schemaVersion,
      createdAt: now,
      lastPlayedAt: now,
      tutorialCompleted: false,
      totalShiftsPlayed: 0,
      bestShiftScore: 0,
      wallet: Wallet(),
      upgrades: const [],
      restoredDepartments: const [],
      dailyAttempts: const [],
      settings: const SettingsSnapshot(),
    );
  }
}

class SettingsSnapshot {
  const SettingsSnapshot({
    this.musicVolume = 0.7,
    this.sfxVolume = 0.9,
    this.hapticsEnabled = true,
    this.reducedMotion = false,
    this.largeText = false,
    this.locale = 'en',
  });

  final double musicVolume;
  final double sfxVolume;
  final bool hapticsEnabled;
  final bool reducedMotion;
  final bool largeText;
  final String locale;

  SettingsSnapshot copyWith({
    double? musicVolume,
    double? sfxVolume,
    bool? hapticsEnabled,
    bool? reducedMotion,
    bool? largeText,
    String? locale,
  }) =>
      SettingsSnapshot(
        musicVolume: musicVolume ?? this.musicVolume,
        sfxVolume: sfxVolume ?? this.sfxVolume,
        hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
        reducedMotion: reducedMotion ?? this.reducedMotion,
        largeText: largeText ?? this.largeText,
        locale: locale ?? this.locale,
      );

  Map<String, Object?> toJson() => {
        'musicVolume': musicVolume,
        'sfxVolume': sfxVolume,
        'hapticsEnabled': hapticsEnabled,
        'reducedMotion': reducedMotion,
        'largeText': largeText,
        'locale': locale,
      };

  factory SettingsSnapshot.fromJson(Map<String, Object?> j) => SettingsSnapshot(
        musicVolume: (j['musicVolume'] as num?)?.toDouble() ?? 0.7,
        sfxVolume: (j['sfxVolume'] as num?)?.toDouble() ?? 0.9,
        hapticsEnabled: j['hapticsEnabled'] as bool? ?? true,
        reducedMotion: j['reducedMotion'] as bool? ?? false,
        largeText: j['largeText'] as bool? ?? false,
        locale: j['locale'] as String? ?? 'en',
      );
}
