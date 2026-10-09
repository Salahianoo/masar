import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/providers.dart';
import '../../core/models/models.dart';
import '../../core/router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final enrollments = ref.watch(enrollmentsProvider);
    final subjects = ref.watch(subjectsProvider).value ?? [];
    return SafeArea(child: ListView(
      padding: const EdgeInsets.all(AppSpacing.screen),
      children: [
        Text('أنا', style: AppText.title),
        const SizedBox(height: AppSpacing.xl),
        const Center(child: CircleAvatar(radius: 38, child: Icon(Icons.person, size: 42))),
        const SizedBox(height: AppSpacing.md),
        Text(profile.value?.displayName ?? 'طالب مسار', style: AppText.heading,
          textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.xl),
        Text('موادي', style: AppText.heading),
        const SizedBox(height: AppSpacing.md),
        AsyncStateView<List<Enrollment>>(
          value: enrollments,
          onRetry: () => ref.invalidate(enrollmentsProvider),
          isEmpty: (items) => items.isEmpty,
          emptyMessage: 'لسا ما سجّلت مادة',
          data: (items) => Column(children: [
            for (final enrollment in items)
              Card(child: ListTile(
                title: Text(subjects.where((s) => s.id == enrollment.subjectId)
                  .firstOrNull?.name ?? enrollment.subjectId),
                subtitle: Text('باقي ${enrollment.daysLeft} أيام · '
                  '${enrollment.diagnosticDone ? 'جاهزيتك ${enrollment.readiness}%' : 'التشخيص لسا ما خلص'}'),
                trailing: const Icon(Icons.chevron_left),
                onTap: () => context.push(enrollment.diagnosticDone
                  ? AppRoutes.map(enrollment.subjectId)
                  : AppRoutes.diagnostic(enrollment.subjectId)),
              )),
          ]),
        ),
        const SizedBox(height: AppSpacing.xl),
        PrimaryButton(label: 'أضف مادة جديدة',
          onPressed: () => context.push(AppRoutes.onboarding)),
      ],
    ));
  }
}
