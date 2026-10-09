import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:masar/presentation/state/providers.dart';
import 'package:masar/domain/entities/entities.dart';
import 'package:masar/presentation/navigation/router.dart';
import 'package:masar/presentation/themes/app_theme.dart';
import 'package:masar/presentation/components/widgets.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String? _selectedSubjectId;

  @override
  Widget build(BuildContext context) {
    final enrollments = ref.watch(enrollmentsProvider);
    final name = ref.watch(profileProvider).value?.displayName ?? '';
    return SafeArea(child: AsyncStateView<List<Enrollment>>(
      value: enrollments,
      onRetry: () => ref.invalidate(enrollmentsProvider),
      data: (items) {
        if (items.isEmpty) {
          return Center(child: PrimaryButton(
            label: 'سجّل مادتك', onPressed: () => context.go(AppRoutes.onboarding),
          ));
        }
        // Default to the newest subject, so a subject just added is the one shown.
        final selected = items.where((e) => e.subjectId == _selectedSubjectId).firstOrNull ?? items.last;
        return _subjectHome(selected, items, name);
      },
    ));
  }

  Widget _subjectHome(Enrollment selected, List<Enrollment> enrollments, String name) {
    final subjectId = selected.subjectId;
    final progress = ref.watch(progressProvider(subjectId));
    final plan = selected.diagnosticDone ? ref.watch(todayPlanProvider(subjectId)) : null;
    final subjects = ref.watch(subjectsProvider).value ?? [];
    final subjectNames = {for (final s in subjects) s.id: s.name};
    return ListView(padding: const EdgeInsets.all(AppSpacing.screen), children: [
      Row(children: [
        const MentorAvatar(pose: MentorPose.wave, size: 52),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: Text('صباح الخير${name.isEmpty ? '' : ' يا $name'}', style: AppText.title)),
        IconButton(onPressed: () => context.go(AppRoutes.profile),
          icon: const Icon(Icons.person_outline), tooltip: 'ملفي'),
      ]),
      const SizedBox(height: AppSpacing.lg),
      // Your subjects, and a way to add another one to prepare for.
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          for (final e in enrollments) Padding(
            padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
            child: ChoiceChip(
              label: Text(subjectNames[e.subjectId] ?? e.subjectId),
              selected: e.subjectId == subjectId,
              onSelected: (_) => setState(() => _selectedSubjectId = e.subjectId),
            ),
          ),
          ActionChip(
            avatar: const Icon(Icons.add, size: 18),
            label: const Text('مادة'),
            tooltip: 'أضف مادة جديدة',
            onPressed: () => context.push(AppRoutes.addSubject),
          ),
        ]),
      ),
      const SizedBox(height: AppSpacing.md),
      Text(subjectNames[subjectId] ?? 'مادتك', style: AppText.heading),
      const SizedBox(height: AppSpacing.sm),
      _readinessCard(subjectId, progress, selected.daysLeft),
      const SizedBox(height: AppSpacing.xl),
      if (!selected.diagnosticDone) ...[
        Text('باقي التشخيص عشان نبني خطتك', style: AppText.heading),
        const SizedBox(height: AppSpacing.md),
        PrimaryButton(label: 'ابدأ أسئلة التشخيص',
          onPressed: () => context.go(AppRoutes.diagnostic(subjectId))),
      ] else ...[
        Row(children: [
          Expanded(child: Text('خطة اليوم', style: AppText.heading)),
          TextButton(onPressed: () => context.push(AppRoutes.map(subjectId)),
            child: const Text('خريطتك')),
        ]),
        AsyncStateView<TodayPlan>(
          value: plan!,
          onRetry: () => ref.invalidate(todayPlanProvider(subjectId)),
          data: (today) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('${today.minutes} دقيقة · ${today.totalDone} من ${today.totalCount} سؤال',
              style: AppText.label),
            const SizedBox(height: AppSpacing.md),
            for (final item in today.items) Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: ListTile(
                  title: Text(item.conceptName),
                  subtitle: Text(item.isReview ? 'مراجعة' : '${item.done} من ${item.count} أسئلة'),
                  trailing: Text('${item.done}/${item.count}', style: AppText.label),
                  onTap: () => context.push(AppRoutes.practice(subjectId,
                    conceptId: item.conceptId)),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              label: today.completed ? 'تدرّب زيادة' : 'يلا نبلّش',
              onPressed: () async {
                await context.push(AppRoutes.practice(subjectId, mode: 'plan'));
                if (mounted) ref.invalidate(todayPlanProvider(subjectId));
              },
            ),
          ]),
        ),
      ],
      const SizedBox(height: AppSpacing.xl),
    ]);
  }

  Widget _readinessCard(String subjectId, AsyncValue<SubjectProgress> progress, int daysLeft) =>
    DecoratedBox(
      decoration: BoxDecoration(color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(children: [
          Row(children: [
            Expanded(child: Text('باقي $daysLeft أيام', style: AppText.label)),
            Text('جاهزيتك', style: AppText.label),
          ]),
          const SizedBox(height: AppSpacing.md),
          AsyncStateView<SubjectProgress>(
            value: progress,
            onRetry: () => ref.invalidate(progressProvider(subjectId)),
            data: (value) => Column(children: [
              Text('${value.readiness}%', style: AppText.display),
              Text('بتوصل ${value.projectedReadiness}% إذا مشيت على الخطة',
                style: AppText.caption),
            ]),
          ),
        ]),
      ),
    );
}
