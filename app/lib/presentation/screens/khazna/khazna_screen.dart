import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import 'package:masar/presentation/state/providers.dart';
import 'package:masar/domain/entities/entities.dart';
import 'package:masar/presentation/navigation/router.dart';
import 'package:masar/presentation/themes/app_theme.dart';
import 'package:masar/presentation/components/widgets.dart';

class KhaznaScreen extends ConsumerStatefulWidget {
  const KhaznaScreen({super.key});

  @override
  ConsumerState<KhaznaScreen> createState() => _KhaznaScreenState();
}

class _KhaznaScreenState extends ConsumerState<KhaznaScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final enrollments = ref.watch(enrollmentsProvider);
    return SafeArea(child: AsyncStateView<List<Enrollment>>(
      value: enrollments,
      onRetry: () => ref.invalidate(enrollmentsProvider),
      data: (items) => ListView(padding: const EdgeInsets.all(AppSpacing.screen), children: [
        Text('خزنة', style: AppText.title),
        const SizedBox(height: AppSpacing.sm),
        Text('امتحانات سابقة من موادك، وحلّها بيحدّث خريطتك.', style: AppText.label),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          decoration: const InputDecoration(prefixIcon: Icon(Icons.search),
            hintText: 'ابحث عن امتحان'),
          onChanged: (value) => setState(() => _query = value.trim()),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (items.isEmpty) const Text('سجّل مادة أولاً عشان تشوف امتحاناتها'),
        for (final enrollment in items)
          _ExamSection(subjectId: enrollment.subjectId, query: _query),
      ]),
    ));
  }
}

class _ExamSection extends ConsumerWidget {
  const _ExamSection({required this.subjectId, required this.query});
  final String subjectId;
  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exams = ref.watch(examsProvider(subjectId));
    final subjectName = ref.watch(subjectsProvider).value
        ?.where((subject) => subject.id == subjectId).firstOrNull?.name ?? subjectId;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(subjectName, style: AppText.heading),
      const SizedBox(height: AppSpacing.sm),
      AsyncStateView<List<Exam>>(
        value: exams,
        onRetry: () => ref.invalidate(examsProvider(subjectId)),
        isEmpty: (list) => list.isEmpty,
        emptyMessage: 'ما في امتحانات مضافة لهالمادة بعد',
        data: (list) => Column(children: [
          for (final exam in list.where((exam) => query.isEmpty ||
              exam.label.contains(query) || subjectName.contains(query)))
            Card(child: ListTile(
              leading: const Icon(Icons.description_outlined),
              title: Text(exam.label),
              subtitle: Text('${exam.questionCount} سؤال'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(AppRoutes.khaznaExam(exam.id)),
            )),
        ]),
      ),
      const SizedBox(height: AppSpacing.lg),
    ]);
  }
}

class KhaznaExamScreen extends ConsumerStatefulWidget {
  const KhaznaExamScreen({super.key, required this.examId});
  final String examId;

  @override
  ConsumerState<KhaznaExamScreen> createState() => _KhaznaExamScreenState();
}

class _KhaznaExamScreenState extends ConsumerState<KhaznaExamScreen> {
  late final Future<Exam?> _exam = _findExam();

  Future<Exam?> _findExam() async {
    final repo = ref.read(masarRepositoryProvider);
    for (final enrollment in await repo.enrollments()) {
      for (final exam in await repo.exams(enrollment.subjectId)) {
        if (exam.id == widget.examId) return exam;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Exam?>(
    future: _exam,
    builder: (context, snapshot) {
      final exam = snapshot.data;
      return Scaffold(
        appBar: AppBar(title: Text(exam?.label ?? 'امتحان سابق')),
        body: snapshot.connectionState != ConnectionState.done
          ? const Center(child: CircularProgressIndicator())
          : snapshot.hasError
              ? Center(child: Text(friendlyError(snapshot.error!)))
          : exam == null
              ? const Center(child: Text('الامتحان مش موجود'))
              : Column(children: [
                  Expanded(child: exam.pdfUrl == null || exam.pdfUrl!.isEmpty
                    ? const Center(child: Text('نسخة PDF مش مضافة بعد'))
                    : exam.pdfUrl!.startsWith('asset:')
                        ? SfPdfViewer.asset(exam.pdfUrl!.substring('asset:'.length))
                        : SfPdfViewer.network(exam.pdfUrl!)),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.screen),
                    child: PrimaryButton(label: 'حلّه كاختبار',
                      onPressed: () => context.push(AppRoutes.practice(
                        exam.subjectId, mode: 'exam', examId: exam.id))),
                  ),
                ]),
      );
    },
  );
}
