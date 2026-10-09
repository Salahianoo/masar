import 'package:flutter/material.dart';

import 'package:masar/presentation/themes/app_theme.dart';

/// Temporary screen for routes whose real screen isn't built yet.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.title, this.details, this.showAppBar = true});

  final String title;

  /// Route params etc., shown small so it's clear the route got them.
  final String? details;
  final bool showAppBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: showAppBar ? AppBar(title: Text(title)) : null,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.construction_rounded, size: 48, color: AppColors.textMuted),
              const SizedBox(height: AppSpacing.lg),
              Text(title, style: AppText.heading, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.sm),
              Text('قيد البناء', style: AppText.label),
              if (details != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(details!, style: AppText.caption, textAlign: TextAlign.center,
                    textDirection: TextDirection.ltr),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
