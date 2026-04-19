import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/logger.dart';
import '../theme/colors.dart';

/// Catches errors thrown during child widget builds and shows a readable
/// fallback instead of the default red ErrorWidget. Keeps a single crash
/// from breaking navigation — user can always back out to the menu.
///
/// Mount this above each top-level route. Doesn't catch async errors in
/// callbacks or Flame update loops — those go through `FlutterError.onError`,
/// configured in `bootstrap.dart`.
class ErrorBoundary extends StatefulWidget {
  const ErrorBoundary({required this.child, super.key});
  final Widget child;

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  FlutterErrorDetails? _details;
  final AppLogger _log = AppLogger('ErrorBoundary');

  @override
  void initState() {
    super.initState();
    ErrorWidget.builder = (details) {
      _log.e('Widget build failed', details.exception, details.stack);
      if (mounted) setState(() => _details = details);
      return _Fallback(
        details: details,
        onReset: () => setState(() => _details = null),
      );
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_details != null) {
      return _Fallback(
        details: _details!,
        onReset: () => setState(() => _details = null),
      );
    }
    return widget.child;
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({required this.details, required this.onReset});
  final FlutterErrorDetails details;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.bug_report,
                  color: AppColors.accentDanger, size: 48),
              const SizedBox(height: 12),
              const Text(
                'Something went wrong.',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'The screen crashed. You can try again or head back '
                'to the main menu.',
                style: TextStyle(color: AppColors.textMuted),
              ),
              if (kDebugMode) ...[
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      '${details.exception}\n\n${details.stack}',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  FilledButton(
                    onPressed: onReset,
                    child: const Text('Try again'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () =>
                        Navigator.of(context).popUntil((r) => r.isFirst),
                    child: const Text('Home'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
