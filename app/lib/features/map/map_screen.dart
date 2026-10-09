import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/providers.dart';
import '../../core/models/models.dart';
import '../../core/router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';

class MapScreen extends ConsumerWidget {
  const MapScreen({super.key, required this.subjectId});
  final String subjectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressProvider(subjectId));
    return Scaffold(
      appBar: AppBar(title: const Text('خريطتك')),
      body: SafeArea(child: AsyncStateView<SubjectProgress>(
        value: progress,
        onRetry: () => ref.invalidate(progressProvider(subjectId)),
        data: (value) => Column(children: [
          Expanded(child: ListView(
            padding: const EdgeInsets.all(AppSpacing.screen),
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(children: [
                    Text('جاهزيتك للامتحان', style: AppText.label),
                    Text('${value.readiness}%', style: AppText.display),
                    Text('بتوصل ${value.projectedReadiness}% إذا مشيت على الخطة',
                      style: AppText.caption, textAlign: TextAlign.center),
                  ]),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('المفاهيم حسب أهميتها بالامتحان', style: AppText.heading),
              const SizedBox(height: AppSpacing.sm),
              for (final concept in value.concepts)
                ConceptBar.fromMastery(concept,
                  warning: concept.status == MasteryStatus.weak && concept.weight >= 0.15
                    ? 'بيجي بـ ${(concept.weight * 100).round()}% من أسئلة الامتحانات'
                    : null,
                  onTap: () => context.push(AppRoutes.practice(subjectId,
                    conceptId: concept.conceptId))),
            ],
          )),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.screen),
            child: PrimaryButton(label: 'شوف خطتك',
              onPressed: () => context.go(AppRoutes.home)),
          ),
        ]),
      )),
    );
  }
}
