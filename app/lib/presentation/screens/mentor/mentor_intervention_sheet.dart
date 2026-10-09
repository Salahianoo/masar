import 'package:flutter/material.dart';

import 'package:masar/presentation/screens/practice/practice_core.dart';

/// What the student chose in the intervention sheet.
enum MentorInterventionOutcome { dismissed, openMentor }

/// The mentor steps in after two wrong answers in a row on one concept.
Future<MentorInterventionOutcome> showMentorIntervention(
  BuildContext context, {
  required MentorNudge nudge,
}) async {
  final outcome = await showModalBottomSheet<MentorInterventionOutcome>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MentorAvatar(pose: MentorPose.thinking, size: 72),
            const SizedBox(height: AppSpacing.lg),
            Text(
              nudge.message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: 'آه اشرحلي',
              onPressed: () => Navigator.of(context).pop(MentorInterventionOutcome.openMentor),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton(
              child: const Text('لا، بكمل'),
              onPressed: () => Navigator.of(context).pop(MentorInterventionOutcome.dismissed),
            ),
          ],
        ),
      ),
    ),
  );
  return outcome ?? MentorInterventionOutcome.dismissed;
}
