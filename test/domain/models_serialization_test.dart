import 'package:dead_dispatch/domain/models/currency.dart';
import 'package:dead_dispatch/domain/models/daily_challenge.dart';
import 'package:dead_dispatch/domain/models/department.dart';
import 'package:dead_dispatch/domain/models/player_profile.dart';
import 'package:dead_dispatch/domain/models/upgrade.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Model serialization round-trips', () {
    test('Wallet encodes and decodes all currencies', () {
      final w = Wallet();
      w.add(Currency.coins, 1234);
      final decoded = Wallet.fromJson(w.toJson());
      expect(decoded.get(Currency.coins), 1234);
    });

    test('SettingsSnapshot round-trips with non-default values', () {
      const s = SettingsSnapshot(
        musicVolume: 0.3,
        sfxVolume: 0.5,
        hapticsEnabled: false,
        reducedMotion: true,
        largeText: true,
        locale: 'fr',
      );
      final decoded = SettingsSnapshot.fromJson(s.toJson());
      expect(decoded.musicVolume, s.musicVolume);
      expect(decoded.sfxVolume, s.sfxVolume);
      expect(decoded.hapticsEnabled, s.hapticsEnabled);
      expect(decoded.reducedMotion, s.reducedMotion);
      expect(decoded.largeText, s.largeText);
      expect(decoded.locale, s.locale);
    });

    test('SettingsSnapshot uses defaults for missing keys', () {
      final decoded = SettingsSnapshot.fromJson({});
      expect(decoded.musicVolume, 0.7);
      expect(decoded.sfxVolume, 0.9);
      expect(decoded.hapticsEnabled, isTrue);
    });

    test('OwnedUpgrade round-trips', () {
      const u = OwnedUpgrade(kind: UpgradeKind.comboGrace, level: 2);
      final decoded = OwnedUpgrade.fromJson(u.toJson());
      expect(decoded.kind, UpgradeKind.comboGrace);
      expect(decoded.level, 2);
    });

    test('RestoredDepartment round-trips', () {
      final now = DateTime(2025, 6, 15);
      final d = RestoredDepartment(id: 'vault', restoredAt: now);
      final decoded = RestoredDepartment.fromJson(d.toJson());
      expect(decoded.id, 'vault');
      expect(decoded.restoredAt, now);
    });

    test('DailyAttempt round-trips', () {
      final at = DateTime(2025, 6, 15, 14, 30);
      final a = DailyAttempt(
        dateKey: '2025-06-15',
        score: 980,
        completed: true,
        attemptedAt: at,
      );
      final decoded = DailyAttempt.fromJson(a.toJson());
      expect(decoded.dateKey, '2025-06-15');
      expect(decoded.score, 980);
      expect(decoded.completed, isTrue);
      expect(decoded.attemptedAt, at);
    });

    test('PlayerProfile round-trips a full profile', () {
      final profile = PlayerProfile.fresh(1);
      profile.tutorialCompleted = true;
      profile.totalShiftsPlayed = 7;
      profile.bestShiftScore = 1500;
      profile.wallet.add(Currency.coins, 300);
      profile.upgrades.add(
        const OwnedUpgrade(kind: UpgradeKind.stampSupply, level: 1),
      );
      profile.restoredDepartments.add(
        RestoredDepartment(id: 'lobby', restoredAt: DateTime(2025, 6, 1)),
      );

      final decoded = PlayerProfile.fromJson(profile.toJson());
      expect(decoded.schemaVersion, 1);
      expect(decoded.tutorialCompleted, isTrue);
      expect(decoded.totalShiftsPlayed, 7);
      expect(decoded.bestShiftScore, 1500);
      expect(decoded.wallet.get(Currency.coins), 300);
      expect(decoded.upgrades.first.kind, UpgradeKind.stampSupply);
      expect(decoded.restoredDepartments.first.id, 'lobby');
    });
  });
}
