import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';

/// Concept name + status-colored progress bar + mastery %.
/// [warning] adds a red line under the bar (e.g. «بيجي بـ 18% من الامتحانات»).
class ConceptBar extends StatelessWidget {
  const ConceptBar({
    super.key,
    required this.name,
    required this.mastery,
    required this.status,
    this.warning,
    this.onTap,
  });

  ConceptBar.fromMastery(ConceptMastery m, {Key? key, String? warning, VoidCallback? onTap})
      : this(
          key: key,
          name: m.name,
          mastery: m.mastery,
          status: m.status,
          warning: warning,
          onTap: onTap,
        );

  final String name;
  final int mastery;
  final MasteryStatus status;
  final String? warning;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = status.color;
    final known = status != MasteryStatus.unknown;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(name, style: AppText.bodyBold, overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  known ? '$mastery%' : status.labelAr,
                  style: AppText.bodyBold.copyWith(color: known ? color : AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.pill),
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: known ? mastery / 100 : 0),
                duration: AppDurations.slow,
                curve: Curves.easeOutCubic,
                builder: (context, v, _) => LinearProgressIndicator(
                  value: v,
                  minHeight: AppSizes.barHeight,
                  color: color,
                  backgroundColor: AppColors.track,
                ),
              ),
            ),
            if (warning != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.warning),
                  const SizedBox(width: AppSpacing.xxs),
                  Expanded(
                    child: Text(warning!, style: AppText.caption.copyWith(color: AppColors.warning)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
