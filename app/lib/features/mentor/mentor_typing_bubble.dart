import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';

/// Shown while the mentor's answer is on its way: his face beside a bubble
/// that says so, with three dots that keep moving so a slow answer (the PC
/// model can take a few seconds) never looks frozen.
class MentorTypingBubble extends StatefulWidget {
  const MentorTypingBubble({super.key, required this.mentorName});

  final String mentorName;

  @override
  State<MentorTypingBubble> createState() => _MentorTypingBubbleState();
}

class _MentorTypingBubbleState extends State<MentorTypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _dots =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();

  @override
  void dispose() {
    _dots.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.mentorName.isEmpty ? 'رفيق' : widget.mentorName;
    return Semantics(
      liveRegion: true,
      label: '$name عم يحضّرلك الجواب',
      child: Align(
        alignment: AlignmentDirectional.centerEnd,
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const MentorBadge(size: 40),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text('$name عم يحضّرلك الجواب',
                            style: AppText.body.copyWith(color: AppColors.textSecondary)),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      AnimatedBuilder(
                        animation: _dots,
                        builder: (context, _) => Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (var i = 0; i < 3; i++) _dot(i),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Each dot rises and brightens in turn.
  Widget _dot(int i) {
    final phase = (_dots.value - i * .18) % 1.0;
    final lift = phase < .4 ? Curves.easeInOut.transform(1 - (phase - .2).abs() / .2) : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1.5),
      child: Transform.translate(
        offset: Offset(0, -3 * lift),
        child: Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Color.lerp(AppColors.textMuted, const Color(0xFF44BFB7), lift),
          ),
        ),
      ),
    );
  }
}
