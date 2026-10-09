import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum MentorPose { wave, happy, thinking, sorry, pointing }

/// The mentor character. Loads `assets/mentor/{pose}.png` (Salah's exports);
/// until those exist it shows a colored circle placeholder.
///
/// When the images land, add `assets/mentor/` under `flutter: assets:` in pubspec.yaml.
class MentorAvatar extends StatelessWidget {
  const MentorAvatar({super.key, this.pose = MentorPose.wave, this.size = AppSizes.mentorAvatar});

  final MentorPose pose;
  final double size;

  String get assetPath => 'assets/mentor/${pose.name}.png';

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Image.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stack) => _Placeholder(pose: pose, size: size),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.pose, required this.size});

  final MentorPose pose;
  final double size;

  IconData get _icon => switch (pose) {
        MentorPose.wave => Icons.waving_hand_outlined,
        MentorPose.happy => Icons.sentiment_very_satisfied_outlined,
        MentorPose.thinking => Icons.psychology_outlined,
        MentorPose.sorry => Icons.sentiment_dissatisfied_outlined,
        MentorPose.pointing => Icons.lightbulb_outline,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: AppColors.mentorSoft, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Icon(_icon, size: size * 0.5, color: AppColors.mentor),
    );
  }
}
