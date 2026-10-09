// TEMPORARY: stand-ins for Amer's core/widgets. Delete when core lands.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({super.key, required this.label, this.onPressed});
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 52,
        child: FilledButton(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          ),
          onPressed: onPressed,
          child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      );
}

enum MentorPose { wave, happy, thinking, sorry, pointing }

/// Placeholder circle until Salah's 3D poses land in assets/mentor/.
class MentorAvatar extends StatelessWidget {
  const MentorAvatar({super.key, required this.pose, this.size = 56});
  final MentorPose pose;
  final double size;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: cs.secondaryContainer,
      child: Icon(
        switch (pose) {
          MentorPose.happy => Icons.sentiment_very_satisfied,
          MentorPose.thinking => Icons.psychology_alt_outlined,
          MentorPose.sorry => Icons.sentiment_dissatisfied,
          MentorPose.pointing => Icons.lightbulb_outline,
          MentorPose.wave => Icons.waving_hand_outlined,
        },
        color: cs.onSecondaryContainer,
        size: size * 0.5,
      ),
    );
  }
}

/// Loading / error-with-retry / empty / data for any AsyncValue.
class AsyncStateView<T> extends StatelessWidget {
  const AsyncStateView({
    super.key,
    required this.value,
    required this.data,
    this.onRetry,
    this.isEmpty,
    this.emptyMessage = 'ما في إشي هون لسا',
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback? onRetry;
  final bool Function(T data)? isEmpty;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    return value.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('صار في مشكلة، جرّب كمان مرة', textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.md),
              OutlinedButton(onPressed: onRetry, child: const Text('جرّب كمان مرة')),
            ],
          ]),
        ),
      ),
      data: (d) => isEmpty?.call(d) ?? false
          ? Center(child: Text(emptyMessage, textAlign: TextAlign.center))
          : data(d),
    );
  }
}
