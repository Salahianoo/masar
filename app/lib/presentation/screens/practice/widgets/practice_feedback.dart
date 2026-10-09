import 'dart:math';

import 'package:flutter/material.dart';

import 'package:masar/presentation/screens/practice/practice_core.dart';

const correctLines = ['هيك!', 'برافو 💪', 'عاش!', 'صح عليك 👌', 'ممتاز، كمّل هيك'];
const wrongLines = [
  'ولا يهمك، هاي بتصير',
  'قريبة! شوف الجواب الصح',
  'ولا يهمك، المرة الجاية بتزبط',
  'عادي، هيك بنتعلم',
];

String pickFeedbackLine({required bool correct, required Random random}) {
  final lines = correct ? correctLines : wrongLines;
  return lines[random.nextInt(lines.length)];
}

/// «الجاهزية 36% (+2)» for a positive delta, otherwise «الجاهزية 34%».
String readinessChipText(int readiness, int delta) =>
    delta > 0 ? 'الجاهزية $readiness% (+$delta)' : 'الجاهزية $readiness%';

/// The strip under the options after an answer: a short line + the readiness chip.
class PracticeFeedback extends StatelessWidget {
  const PracticeFeedback({
    super.key,
    required this.correct,
    required this.line,
    required this.readiness,
    required this.delta,
  });

  final bool correct;
  final String line;
  final int readiness;
  final int delta;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = (correct ? MasteryStatus.strong : MasteryStatus.weak).color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              line,
              style: theme.textTheme.titleSmall?.copyWith(color: color, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              readinessChipText(readiness, delta),
              style: theme.textTheme.labelLarge?.copyWith(
                color: delta > 0 ? MasteryStatus.strong.color : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
