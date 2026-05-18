import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/colors.dart';
import 'screen_background.dart';

/// Standard page chrome used by every non-gameplay screen. Composes:
///   • the dark haunted-desk background colour
///   • the shared [ScreenBackground] (diagonal stripes + bottom glow)
///   • a slim header row (back button + title + optional trailing slot)
///   • a SafeArea-padded body
///
/// Using this wrapper everywhere keeps splash → tutorial → menu →
/// brief → game → result → upgrades → departments → settings → daily
/// looking like one app, not 10.
class ScreenScaffold extends StatelessWidget {
  const ScreenScaffold({
    required this.body,
    this.title,
    this.trailing,
    this.showBack = true,
    this.padding = const EdgeInsets.fromLTRB(16, 12, 16, 16),
    super.key,
  });

  /// Title shown in the header row. Null hides the header entirely
  /// (use for splash / hero pages).
  final String? title;

  /// Optional widget on the right of the header (e.g. coin chip).
  final Widget? trailing;

  /// Show a back button on the left of the header. Defaults to true.
  final bool showBack;

  /// Body padding. Use `EdgeInsets.zero` to manage padding yourself
  /// (e.g. for a `ListView`).
  final EdgeInsetsGeometry padding;

  final Widget body;

  @override
  Widget build(BuildContext context) {
    final hasHeader = title != null || trailing != null || showBack;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const ScreenBackground(),
          SafeArea(
            child: Column(
              children: [
                if (hasHeader)
                  _Header(
                    title: title,
                    trailing: trailing,
                    showBack: showBack,
                  ),
                Expanded(
                  child: Padding(padding: padding, child: body),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.trailing,
    required this.showBack,
  });

  final String? title;
  final Widget? trailing;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
      child: Row(
        children: [
          if (showBack)
            IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: AppColors.textMuted,
                size: 18,
              ),
              padding: EdgeInsets.zero,
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/menu');
                }
              },
            )
          else
            const SizedBox(width: 8),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              (title ?? '').toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
