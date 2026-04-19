import 'package:flutter/material.dart';

import '../../../l10n/strings_en.dart';
import '../../../presentation/theme/colors.dart';

/// Lightweight splash. Shown only while the bootstrap async work runs;
/// `bootstrap.dart` swaps it out as soon as providers are ready.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_post_office,
                color: AppColors.accentGold, size: 72),
            SizedBox(height: 16),
            Text(
              Strings.appTitle,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 26,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 24),
            CircularProgressIndicator(color: AppColors.accentGold),
          ],
        ),
      ),
    );
  }
}
