import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:masar/presentation/state/providers.dart';
import 'package:masar/domain/entities/entities.dart';
import 'package:masar/presentation/navigation/router.dart';
import 'package:masar/presentation/themes/app_theme.dart';
import 'package:masar/presentation/components/widgets.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _name = TextEditingController();
  String? _subjectId;
  DateTime? _examDate;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _examDate ?? now.add(const Duration(days: 7)),
      firstDate: now.add(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
      helpText: 'متى امتحانك؟',
    );
    if (date != null && mounted) setState(() => _examDate = date);
  }

  Future<void> _begin(List<Subject> subjects) async {
    final name = _name.text.trim();
    final subjectId = _subjectId ?? (subjects.isEmpty ? null : subjects.first.id);
    if (name.isEmpty || subjectId == null || _examDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اكتب اسمك، اختَر المادة، وحدّد موعد الامتحان')),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final repo = ref.read(masarRepositoryProvider);
      await repo.updateProfile(name);
      await repo.enroll(subjectId, _examDate!);
      ref.invalidate(profileProvider);
      ref.invalidate(enrollmentsProvider);
      if (mounted) context.go(AppRoutes.diagnostic(subjectId));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyError(error))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjects = ref.watch(subjectsProvider);
    return Scaffold(
      body: SafeArea(
        child: AsyncStateView<List<Subject>>(
          value: subjects,
          onRetry: () => ref.invalidate(subjectsProvider),
          isEmpty: (items) => items.isEmpty,
          emptyMessage: 'لسا ما في مواد جاهزة. ارجع بعد ما نضيف بنك الأسئلة.',
          data: (items) => SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.screen),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.xl),
                const Center(child: MentorAvatar(pose: MentorPose.wave, size: 108)),
                const SizedBox(height: AppSpacing.lg),
                Text('أهلاً في مسار', style: AppText.title, textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.sm),
                Text('خطوة بخطوة لامتحانك، وعلى سرعتك.', style: AppText.label,
                    textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.xxl),
                Text('شو اسمك؟', style: AppText.bodyBold),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _name,
                  textInputAction: TextInputAction.done,
                  maxLength: 80,
                  decoration: const InputDecoration(hintText: 'اسمك الأول'),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('أي مادة بدك تجهّز إلها؟', style: AppText.bodyBold),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<String>(
                  initialValue: _subjectId ?? items.first.id,
                  isExpanded: true,
                  items: [for (final subject in items)
                    DropdownMenuItem(value: subject.id, child: Text(subject.name))],
                  onChanged: (value) => setState(() => _subjectId = value),
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
                PrimaryButton(label: 'ابدأ التشخيص', loading: _busy,
                    onPressed: () => _begin(items)),
                const SizedBox(height: AppSpacing.sm),
                Text('8 أسئلة قصيرة عشان نعرف من وين نبلّش.', style: AppText.caption,
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
