import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/providers.dart';
import '../../core/models/models.dart';
import '../../core/router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';

// TODO(amer): step 5 replaces this dev hub with the real «خطة اليوم» screen.
// For now it shows the core widgets on live mock data and links to every route.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enrollments = ref.watch(enrollmentsProvider);
    return Scaffold(
      body: SafeArea(
        child: AsyncStateView<List<Enrollment>>(
          value: enrollments,
          onRetry: () => ref.invalidate(enrollmentsProvider),
          isEmpty: (list) => list.isEmpty,
          emptyMessage: 'لسا ما سجّلت بأي مادة',
          data: (list) => _DevHub(subjectId: list.first.subjectId),
        ),
      ),
    );
  }
}

class _DevHub extends ConsumerWidget {
  const _DevHub({required this.subjectId});

  final String subjectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressProvider(subjectId));
    final plan = ref.watch(todayPlanProvider(subjectId));
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screen),
      children: [
        Row(
          children: [
            const MentorAvatar(pose: MentorPose.wave),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text('شاشة تجربة للـ core', style: AppText.title)),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        AsyncStateView<SubjectProgress>(
          value: progress,
          onRetry: () => ref.invalidate(progressProvider(subjectId)),
          data: (p) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: ReadinessRing(value: p.readiness, label: 'جاهزيتك للامتحان')),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'بتوصل ${p.projectedReadiness}% إذا مشيت على الخطة',
                style: AppText.label,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              for (final c in p.concepts) ConceptBar.fromMastery(c),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        AsyncStateView<TodayPlan>(
          value: plan,
          onRetry: () => ref.invalidate(todayPlanProvider(subjectId)),
          data: (t) => Text(
            'خطة اليوم · ${t.minutes} دقيقة\n'
            '${t.items.map((i) => '${i.conceptName} ${i.done}/${i.count}${i.isReview ? ' (مراجعة)' : ''}').join('\n')}',
            style: AppText.body,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        PrimaryButton(
          label: 'جاوب سؤال عشوائي (يحدّث الأرقام)',
          onPressed: () => _answerRandom(ref),
        ),
        const SizedBox(height: AppSpacing.md),
        for (final (label, route) in [
          ('التشخيص', AppRoutes.diagnostic(subjectId)),
          ('الخريطة', AppRoutes.map(subjectId)),
          ('تمرين الخطة', AppRoutes.practice(subjectId, mode: 'plan')),
          ('تمرين مفهوم', AppRoutes.practice(subjectId, conceptId: 'bleeding')),
          ('ملخص', AppRoutes.summary(subjectId)),
        ])
          TextButton(onPressed: () => context.push(route), child: Text(label)),
      ],
    );
  }

  /// Dev only: answers the next question with a random option to show live updates.
  Future<void> _answerRandom(WidgetRef ref) async {
    final repo = ref.read(masarRepositoryProvider);
    final q = await repo.nextQuestion(subjectId);
    if (q == null) return;
    final options = [...q.options]..shuffle();
    await repo.submitAnswer(
      questionId: q.id,
      chosen: options.first.label,
      ms: 4000,
      source: AnswerSource.plan,
    );
    ref.invalidate(todayPlanProvider(subjectId));
  }
}
