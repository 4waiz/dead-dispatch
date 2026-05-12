import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_router.dart';
import '../../../presentation/theme/colors.dart';

/// Placeholder while the block-puzzle gameplay is being built out in
/// Batches 2–4 of the conveyor → block-puzzle migration. Routing still
/// resolves so the rest of the menu chain compiles and is testable.
class GameScreen extends ConsumerWidget {
  const GameScreen({this.dailyDateKey, super.key});

  final String? dailyDateKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(dailyDateKey == null ? 'Classic Shift' : 'Daily Seal'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.construction_rounded,
                size: 64,
                color: AppColors.accentGold,
              ),
              const SizedBox(height: 16),
              const Text(
                'New gameplay coming online…',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Dead Dispatch's haunted block puzzle is wiring up. "
                'Check back next batch.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go(AppRoutes.menu),
                child: const Text('Back to menu'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
