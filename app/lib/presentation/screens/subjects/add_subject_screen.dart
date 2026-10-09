import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:masar/domain/entities/entities.dart';
import 'package:masar/presentation/components/widgets.dart';
import 'package:masar/presentation/navigation/routes.dart';
import 'package:masar/presentation/state/providers.dart';
import 'package:masar/presentation/themes/app_theme.dart';

/// Adds one more subject for a student who's already set up: the subjects
/// they don't have yet, an exam date, then that subject's diagnostic. Unlike
/// onboarding it never asks for the name again.
class AddSubjectScreen extends ConsumerStatefulWidget {
  const AddSubjectScreen({super.key});

  @override
  ConsumerState<AddSubjectScreen> createState() => _AddSubjectScreenState();
}

class _AddSubjectScreenState extends ConsumerState<AddSubjectScreen> {
  String? _subjectId;
  DateTime? _examDate;
  bool _busy = false;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: now.add(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
      initialDate: _examDate ?? now.add(const Duration(days: 7)),
      helpText: 'متى امتحانك؟',
    );
    if (picked != null) setState(() => _examDate = picked);
  }

  Future<void> _begin() async {
    final subjectId = _subjectId;
    if (subjectId == null || _examDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختار المادة وتاريخ الامتحان')),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(masarRepositoryProvider).enroll(subjectId, _examDate!);
      ref.invalidate(enrollmentsProvider);
      if (mounted) context.go(AppRoutes.diagnostic(subjectId));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyError(error))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjects = ref.watch(subjectsProvider);
    final enrolled = {...?ref.watch(enrollmentsProvider).value?.map((e) => e.subjectId)};
    return Scaffold(
      appBar: AppBar(title: const Text('أضف مادة')),
      body: SafeArea(
        child: AsyncStateView<List<Subject>>(
          value: subjects,
          onRetry: () => ref.invalidate(subjectsProvider),
          isEmpty: (items) => items.every((s) => enrolled.contains(s.id)),
          emptyMessage: 'سجّلت بكل المواد المتاحة 👏',
          data: (items) {
            final available = items.where((s) => !enrolled.contains(s.id)).toList();
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.screen),
              children: [
                Text('أي مادة بدك تجهّز إلها؟', style: AppText.heading),
                const SizedBox(height: AppSpacing.md),
                for (final s in available)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _SubjectTile(
                      subject: s,
                      selected: s.id == _subjectId,
                      onTap: () => setState(() => _subjectId = s.id),
                    ),
                  ),
                const SizedBox(height: AppSpacing.lg),
                Text('متى الامتحان؟', style: AppText.bodyBold),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.event_outlined),
                  label: Text(_examDate == null
                      ? 'اختَر التاريخ'
                      : '${_examDate!.day}/${_examDate!.month}/${_examDate!.year}'),
                ),
                const SizedBox(height: AppSpacing.xxl),
                PrimaryButton(label: 'ابدأ التشخيص', loading: _busy, onPressed: _begin),
                const SizedBox(height: AppSpacing.sm),
                Text('أسئلة قصيرة عشان نعرف من وين نبلّش بهاي المادة.',
                    style: AppText.caption, textAlign: TextAlign.center),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SubjectTile extends StatelessWidget {
  const _SubjectTile({required this.subject, required this.selected, required this.onTap});

  final Subject subject;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primarySoft : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: selected ? AppColors.primary : AppColors.border, width: selected ? 2 : 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(subject.name, style: AppText.bodyBold),
                const SizedBox(height: AppSpacing.xs),
                Text('${subject.questionCount} سؤال من امتحانات سابقة · ${subject.conceptCount} مفاهيم',
                    style: AppText.caption),
              ]),
            ),
            Icon(selected ? Icons.check_circle : Icons.circle_outlined,
                color: selected ? AppColors.primary : AppColors.textMuted),
          ]),
        ),
      ),
    );
  }
}
