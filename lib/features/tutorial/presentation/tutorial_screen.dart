import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_router.dart';
import '../../../di/providers.dart';
import '../../../l10n/strings_en.dart';
import '../../../presentation/theme/colors.dart';
import '../../../presentation/widgets/primary_button.dart';
import '../../../presentation/widgets/screen_scaffold.dart';

/// Onboarding. Four slides walking the player through drag → clear →
/// coins → combo + daily. Marking it complete is a one-time write to
/// the save.
class TutorialScreen extends ConsumerStatefulWidget {
  const TutorialScreen({super.key});

  @override
  ConsumerState<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends ConsumerState<TutorialScreen> {
  int _step = 0;

  static const _steps = <String>[
    Strings.tutorialIntro,
    Strings.tutorialFillRow,
    Strings.tutorialClearCoins,
    Strings.tutorialComboDaily,
  ];

  Future<void> _next() async {
    if (_step < _steps.length - 1) {
      setState(() => _step++);
    } else {
      ref.read(playerProfileProvider.notifier).mutate((p) {
        p.tutorialCompleted = true;
      });
      await ref.read(playerProfileProvider.notifier).persist();
      if (!mounted) return;
      context.pushReplacement(AppRoutes.brief);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: Strings.menuTutorial,
      showBack: false,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          const Icon(Icons.school, size: 88, color: AppColors.accentGold),
          const SizedBox(height: 18),
          Text(
            _steps[_step],
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              height: 1.4,
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List<Widget>.generate(
              _steps.length,
              (i) => Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i == _step
                      ? AppColors.accentGold
                      : AppColors.outline,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          PrimaryButton(
            label: _step < _steps.length - 1 ? 'Next' : 'Start shift',
            onPressed: _next,
          ),
        ],
      ),
    );
  }
}
