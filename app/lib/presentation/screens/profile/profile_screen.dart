import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:masar/presentation/state/providers.dart';
import 'package:masar/domain/entities/entities.dart';
import 'package:masar/presentation/navigation/router.dart';
import 'package:masar/presentation/themes/app_theme.dart';
import 'package:masar/presentation/components/widgets.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  /// Forgets this device's student (name, subjects, progress) after a confirm.
  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تسجيل خروج؟'),
        content: const Text('رح ننسى اسمك وموادك وتقدّمك على هاد الجهاز.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('لا')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('اطلع')),
        ],
      ),
    );
    if (sure != true) return;
    await ref.read(masarRepositoryProvider).signOut();
    ref
      ..invalidate(profileProvider)
      ..invalidate(enrollmentsProvider);
    if (context.mounted) context.go(AppRoutes.onboarding);
  }

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
          onPressed: () => context.push(AppRoutes.addSubject)),
        const SizedBox(height: AppSpacing.md),
        TextButton.icon(
          onPressed: () => _signOut(context, ref),
          icon: const Icon(Icons.logout),
          label: const Text('تسجيل خروج'),
        ),
      ],
    ));
  }
}
