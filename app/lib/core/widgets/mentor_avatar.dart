import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum MentorPose { wave, happy, thinking, sorry, pointing, idle, head }

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
        MentorPose.idle || MentorPose.head => Icons.face_outlined,
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

/// رفيق's face in a soft circle: the chat avatar and the tab icon. The head
/// pose is drawn a little larger than the circle so the cap's tassel can
/// spill over the edge, as on his other screens.
class MentorBadge extends StatelessWidget {
  const MentorBadge({super.key, this.size = 40, this.ring = false});

  final double size;

  /// A teal ring for the selected tab.
  final bool ring;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.mentorSoft,
        border: ring ? Border.all(color: const Color(0xFF44BFB7), width: 2) : null,
      ),
      child: ClipOval(
        child: Transform.scale(
          scale: 1.18,
          child: MentorAvatar(pose: MentorPose.head, size: size),
        ),
      ),
    );
  }
}
