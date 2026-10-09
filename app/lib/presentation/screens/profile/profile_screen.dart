import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:masar/presentation/state/providers.dart';
import 'package:masar/domain/entities/entities.dart';
import 'package:masar/presentation/navigation/router.dart';
import 'package:masar/presentation/themes/app_theme.dart';
import 'package:masar/presentation/components/widgets.dart';
import 'package:masar/presentation/screens/profile/profile_stats.dart';
import 'package:masar/presentation/screens/profile/profile_widgets.dart';

/// «أنا»: who the student is, how they're doing, their subjects, and settings.
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

  Future<void> _editName(BuildContext context, WidgetRef ref, String current) async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => _NameDialog(initial: current),
    );
    if (name == null || name.trim().isEmpty || name.trim() == current) return;
    try {
      await ref.read(masarRepositoryProvider).updateProfile(name.trim());
      ref.invalidate(profileProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyError(e))));
      }
    }
  }

  Future<void> _editExamDate(BuildContext context, WidgetRef ref, Enrollment e) async {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: e.examDate.isBefore(tomorrow) ? tomorrow : e.examDate,
      firstDate: tomorrow,
      lastDate: DateTime(now.year + 1, now.month, now.day),
      helpText: 'إمتى امتحانك؟',
    );
    if (picked == null) return;
    try {
      await ref.read(masarRepositoryProvider).enroll(e.subjectId, picked);
      ref
        ..invalidate(enrollmentsProvider)
        ..invalidate(todayPlanProvider(e.subjectId));
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(friendlyError(error))));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(profileProvider).value?.displayName ?? 'طالب مسار';
    final enrollments = ref.watch(enrollmentsProvider);
    final subjects = ref.watch(subjectsProvider).value ?? const <Subject>[];
    final config = ref.watch(configProvider).value;
    final items = enrollments.value ?? const <Enrollment>[];
    final progress = {
      for (final e in items) e.subjectId: ?ref.watch(progressProvider(e.subjectId)).value,
    };
    final stats = ProfileStats.from(items, progress);

    String subjectName(String id) =>
        subjects.where((s) => s.id == id).firstOrNull?.name ?? id;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.screen),
        children: [
          Text('أنا', style: AppText.title),
          const SizedBox(height: AppSpacing.lg),
          ProfileHeader(
            name: name,
            subjectCount: items.length,
            onEditName: () => _editName(context, ref, name),
          ),

          const ProfileSectionTitle('إحصائياتي'),
          ProfileStatGrid(stats: stats),
          const SizedBox(height: AppSpacing.md),
          MasteryBreakdown(counts: stats.statusCounts),

          const ProfileSectionTitle('موادي'),
          AsyncStateView<List<Enrollment>>(
            value: enrollments,
            onRetry: () => ref.invalidate(enrollmentsProvider),
            isEmpty: (list) => list.isEmpty,
            emptyMessage: 'لسا ما سجّلت مادة',
            data: (list) => Column(
              children: [
                for (final e in list)
                  SubjectProgressCard(
                    enrollment: e,
                    subjectName: subjectName(e.subjectId),
                    onOpen: () => context.push(e.diagnosticDone
                        ? AppRoutes.map(e.subjectId)
                        : AppRoutes.diagnostic(e.subjectId)),
                    onEditDate: () => _editExamDate(context, ref, e),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: () => context.push(AppRoutes.addSubject),
            icon: const Icon(Icons.add_rounded),
            label: const Text('أضف مادة جديدة'),
          ),

          const ProfileSectionTitle('المظهر'),
          const AppearanceSetting(),

          const ProfileSectionTitle('عام'),
          if (config != null && config.mentorEnabled) ...[
            ProfileTile(
              leading: const MentorBadge(size: 36),
              title: config.mentorName,
              subtitle: 'مرشدك بالمادة، اسأله أي إشي',
              onTap: () => context.go(AppRoutes.mentor),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          ProfileTile(
            leading: Icon(Icons.logout_rounded, color: AppColors.error),
            title: 'تسجيل خروج',
            color: AppColors.error,
            onTap: () => _signOut(context, ref),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

/// Asks for the name; owns its text controller so it outlives the close animation.
class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.initial});

  final String initial;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('شو اسمك؟'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 40,
        decoration: const InputDecoration(hintText: 'اسمك', counterText: ''),
        onSubmitted: (v) => Navigator.pop(context, v),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        TextButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('احفظ'),
        ),
      ],
    );
  }
}
