import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../di/providers.dart';
import '../../../domain/models/player_profile.dart';
import '../../../l10n/strings_en.dart';
import '../../../services/analytics_service.dart';
import '../../../presentation/theme/colors.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(playerProfileProvider);
    final s = profile.settings;
    final analytics = ref.read(analyticsServiceProvider);
    final haptics = ref.read(hapticsServiceProvider);
    final audio = ref.read(audioServiceProvider);

    Future<void> replace(SettingsSnapshot next, String changedKey) async {
      await ref.read(playerProfileProvider.notifier).updateSettings(next);
      await analytics.logEvent(
        AnalyticsEvents.settingsChanged,
        params: {'key': changedKey},
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text(Strings.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            title: const Text(Strings.settingsMusic,
                style: TextStyle(color: AppColors.textPrimary)),
            subtitle: Slider(
              value: s.musicVolume,
              activeColor: AppColors.accentGold,
              inactiveColor: AppColors.outline,
              onChanged: (v) async {
                await audio.setMusicVolume(v);
                await replace(s.copyWith(musicVolume: v), 'musicVolume');
              },
            ),
          ),
          ListTile(
            title: const Text(Strings.settingsSfx,
                style: TextStyle(color: AppColors.textPrimary)),
            subtitle: Slider(
              value: s.sfxVolume,
              activeColor: AppColors.accentGold,
              inactiveColor: AppColors.outline,
              onChanged: (v) async {
                await audio.setSfxVolume(v);
                await replace(s.copyWith(sfxVolume: v), 'sfxVolume');
              },
            ),
          ),
          SwitchListTile(
            title: const Text(Strings.settingsHaptics,
                style: TextStyle(color: AppColors.textPrimary)),
            value: s.hapticsEnabled,
            activeThumbColor: AppColors.accentGold,
            onChanged: (v) async {
              haptics.isEnabled = v;
              await replace(s.copyWith(hapticsEnabled: v), 'hapticsEnabled');
            },
          ),
          SwitchListTile(
            title: const Text(Strings.settingsReducedMotion,
                style: TextStyle(color: AppColors.textPrimary)),
            value: s.reducedMotion,
            activeThumbColor: AppColors.accentGold,
            onChanged: (v) async =>
                replace(s.copyWith(reducedMotion: v), 'reducedMotion'),
          ),
          SwitchListTile(
            title: const Text(Strings.settingsLargeText,
                style: TextStyle(color: AppColors.textPrimary)),
            value: s.largeText,
            activeThumbColor: AppColors.accentGold,
            onChanged: (v) async =>
                replace(s.copyWith(largeText: v), 'largeText'),
          ),
          const Divider(color: AppColors.outline),
          ListTile(
            leading: const Icon(Icons.delete_forever,
                color: AppColors.accentDanger),
            title: const Text(Strings.settingsResetSave,
                style: TextStyle(color: AppColors.accentDanger)),
            onTap: () => _confirmReset(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(Strings.settingsResetSave),
        content: const Text(Strings.settingsResetSaveConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(playerProfileProvider.notifier).reset();
    }
  }
}
