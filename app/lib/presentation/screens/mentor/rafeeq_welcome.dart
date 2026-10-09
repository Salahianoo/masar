import 'package:flutter/material.dart';

import 'package:masar/presentation/components/widgets.dart';
import 'package:masar/presentation/themes/app_theme.dart';

/// The chat's empty state: رفيق over a soft glow beside his greeting, and four
/// suggestion cards. Scrolls with the chat list, so it never overflows.
class RafeeqWelcome extends StatelessWidget {
  const RafeeqWelcome({
    super.key,
    required this.mentorName,
    required this.onAsk,
    required this.onPractice,
    required this.onExplainTopic,
  });

  final String mentorName;

  /// Sends [text] as the student's message.
  final ValueChanged<String> onAsk;

  /// «اختبرني بأسئلة سنوات»: opens practice, sends nothing.
  final VoidCallback onPractice;

  /// «اشرحلي موضوع من المادة»: lets the student pick a concept.
  final VoidCallback onExplainTopic;

  static const examSoon = 'عندي امتحان قريب، شو أركز عليه؟';
  static const topTopics = 'شو أهم المواضيع بمادتي؟';
  static const quizMe = 'اختبرني بأسئلة سنوات';
  static const explainTopic = 'اشرحلي موضوع من المادة';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // رفيق beside his hello, so all four suggestions fit without scrolling.
        Row(children: [
          const _GlowingRafeeq(size: 96),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                'أهلاً، أنا $mentorName',
                style: AppText.title.copyWith(color: AppColors.brand, fontSize: 24),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'بعرف مادتك وقديش باقي على امتحانك. اسألني عن أي مفهوم، '
                'وبشرحلك من أسئلة امتحانات حقيقية.',
                style: AppText.label.copyWith(height: 1.5),
              ),
            ]),
          ),
        ]),
        const SizedBox(height: AppSpacing.lg),
        Text('جرّب تسأل:', style: AppText.bodyBold, textAlign: TextAlign.start),
        const SizedBox(height: AppSpacing.sm),
        SuggestionCard(icon: Icons.timer_outlined, text: examSoon, onTap: () => onAsk(examSoon)),
        const SizedBox(height: AppSpacing.sm),
        SuggestionCard(icon: Icons.star_outline, text: topTopics, onTap: () => onAsk(topTopics)),
        const SizedBox(height: AppSpacing.sm),
        SuggestionCard(icon: Icons.check_circle_outline, text: quizMe, onTap: onPractice),
        const SizedBox(height: AppSpacing.sm),
        SuggestionCard(
            icon: Icons.menu_book_outlined, text: explainTopic, onTap: onExplainTopic),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

/// رفيق waving over a radial teal halo.
class _GlowingRafeeq extends StatelessWidget {
  const _GlowingRafeeq({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final halo = size * 1.2;
    return SizedBox.square(
      dimension: halo,
      child: Stack(
        alignment: Alignment.center,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.accent.withValues(alpha: 0.22),
                  AppColors.accent.withValues(alpha: 0),
                ],
                stops: const [0.35, 1],
              ),
            ),
            child: SizedBox.square(dimension: halo),
          ),
          ExcludeSemantics(child: MentorAvatar(pose: MentorPose.wave, size: size)),
        ],
      ),
    );
  }
}

/// A full-width tappable suggestion: teal icon at the start, text in the middle.
class SuggestionCard extends StatelessWidget {
  const SuggestionCard({super.key, required this.icon, required this.text, required this.onTap});

  final IconData icon;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: text,
      excludeSemantics: true,
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSizes.optionMinHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: [
                  Icon(icon, color: AppColors.accent, size: 24),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: Text(text, style: AppText.body)),
                  const SizedBox(width: AppSpacing.sm),
                  Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
