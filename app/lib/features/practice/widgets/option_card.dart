import 'package:flutter/material.dart';

import '../fake_core/core.dart';

enum OptionState { idle, pending, correct, wrong, dimmed }

/// How an option looks given what was chosen and, once known, the right answer.
OptionState optionStateFor({
  required String label,
  required String? chosen,
  required String? correctAnswer,
}) {
  if (chosen == null) return OptionState.idle;
  if (correctAnswer == null) return label == chosen ? OptionState.pending : OptionState.idle;
  if (label == correctAnswer) return OptionState.correct;
  if (label == chosen) return OptionState.wrong;
  return OptionState.dimmed;
}

/// A large tappable answer card.
class OptionCard extends StatelessWidget {
  const OptionCard({
    super.key,
    required this.option,
    required this.state,
    required this.showLabel,
    this.onTap,
  });

  final QuestionOption option;
  final OptionState state;
  final bool showLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final good = MasteryStatus.strong.color;
    final bad = MasteryStatus.weak.color;

    final (border, fill, fg) = switch (state) {
      OptionState.idle => (cs.outlineVariant, cs.surface, cs.onSurface),
      OptionState.pending => (cs.primary, cs.primaryContainer, cs.onPrimaryContainer),
      OptionState.correct => (good, good.withValues(alpha: 0.12), good),
      OptionState.wrong => (bad, bad.withValues(alpha: 0.10), bad),
      OptionState.dimmed => (cs.outlineVariant, cs.surface, cs.onSurface.withValues(alpha: 0.5)),
    };
    final icon = switch (state) {
      OptionState.correct => Icons.check_circle,
      OptionState.wrong => Icons.cancel,
      _ => null,
    };

    return Semantics(
      button: true,
      selected: state == OptionState.pending || state == OptionState.wrong,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: border, width: state == OptionState.idle ? 1 : 1.5),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.md),
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                child: Row(
                  children: [
                    if (showLabel) ...[
                      Text('${option.label}.',
                          style: theme.textTheme.bodyLarge?.copyWith(color: fg, fontWeight: FontWeight.w600)),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    Expanded(
                      child: Text(option.text, style: theme.textTheme.bodyLarge?.copyWith(color: fg)),
                    ),
                    if (icon != null) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Icon(icon, color: fg, size: 22),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
