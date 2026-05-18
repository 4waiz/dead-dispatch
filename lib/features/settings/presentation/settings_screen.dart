import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../di/providers.dart';
import '../../../domain/models/player_profile.dart';
import '../../../l10n/strings_en.dart';
import '../../../presentation/theme/colors.dart';
import '../../../presentation/widgets/screen_scaffold.dart';
import '../../../services/analytics_service.dart';

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

    return ScreenScaffold(
      title: Strings.settingsTitle,
      padding: EdgeInsets.zero,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          _SettingsTile(
            child: ListTile(
              title: const Text(
                Strings.settingsMusic,
                style: TextStyle(color: AppColors.textPrimary),
              ),
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
          ),
          _SettingsTile(
            child: ListTile(
              title: const Text(
                Strings.settingsSfx,
                style: TextStyle(color: AppColors.textPrimary),
              ),
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
          ),
          _SettingsTile(
            child: SwitchListTile(
              title: const Text(
                Strings.settingsHaptics,
                style: TextStyle(color: AppColors.textPrimary),
              ),
              value: s.hapticsEnabled,
              activeColor: AppColors.accentGold,
              onChanged: (v) async {
                haptics.isEnabled = v;
                await replace(s.copyWith(hapticsEnabled: v), 'hapticsEnabled');
              },
            ),
          ),
          _SettingsTile(
            child: SwitchListTile(
              title: const Text(
                Strings.settingsReducedMotion,
                style: TextStyle(color: AppColors.textPrimary),
              ),
              value: s.reducedMotion,
              activeColor: AppColors.accentGold,
              onChanged: (v) async =>
                  replace(s.copyWith(reducedMotion: v), 'reducedMotion'),
            ),
          ),
          _SettingsTile(
            child: SwitchListTile(
              title: const Text(
                Strings.settingsLargeText,
                style: TextStyle(color: AppColors.textPrimary),
              ),
              value: s.largeText,
              activeColor: AppColors.accentGold,
              onChanged: (v) async =>
                  replace(s.copyWith(largeText: v), 'largeText'),
            ),
          ),
          const SizedBox(height: 20),
          _SettingsTile(
            danger: true,
            child: ListTile(
              leading: const Icon(
                Icons.delete_forever,
                color: AppColors.accentDanger,
              ),
              title: const Text(
                Strings.settingsResetSave,
                style: TextStyle(color: AppColors.accentDanger),
              ),
              onTap: () => _confirmReset(context, ref),
            ),
          ),
          const SizedBox(height: 24),
          const Center(
            child: Text(
              'Developed by Kanban Studios · Awaiz Ahmed',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
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

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({required this.child, this.danger = false});
  final Widget child;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: danger ? AppColors.accentDanger : AppColors.outline,
        ),
      ),
      child: child,
    );
  }
}
