import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:masar/presentation/state/providers.dart';
import 'package:masar/domain/entities/entities.dart';
import 'package:masar/presentation/navigation/router.dart';
import 'package:masar/presentation/themes/app_theme.dart';
import 'package:masar/presentation/components/widgets.dart';
import 'package:masar/presentation/screens/practice/widgets/option_card.dart';
import 'package:masar/presentation/screens/practice/widgets/practice_feedback.dart';

class DiagnosticScreen extends ConsumerStatefulWidget {
  const DiagnosticScreen({super.key, required this.subjectId});
  final String subjectId;

  @override
  ConsumerState<DiagnosticScreen> createState() => _DiagnosticScreenState();
}

class _DiagnosticScreenState extends ConsumerState<DiagnosticScreen> {
  List<Question>? _questions;
  Object? _error;
  int _index = 0;
  String? _chosen;
  AnswerResult? _result;
  bool _busy = false;
  final Stopwatch _watch = Stopwatch();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _questions = null; _error = null; });
    try {
      final questions = await ref.read(masarRepositoryProvider).startDiagnostic(widget.subjectId);
      if (!mounted) return;
      setState(() { _questions = questions; _index = 0; _chosen = null; _result = null; });
      _watch..reset()..start();
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  Future<void> _answer(String label) async {
    final question = _questions?[_index];
    if (question == null || _chosen != null || _busy) return;
    final ms = _watch.elapsedMilliseconds;
    _watch.stop();
    setState(() { _chosen = label; _busy = true; });
    try {
      final result = await ref.read(masarRepositoryProvider).submitAnswer(
        questionId: question.id, chosen: label, ms: ms, source: AnswerSource.diagnostic,
      );
      if (mounted) setState(() => _result = result);
    } catch (error) {
      if (mounted) {
        setState(() => _chosen = null);
        _watch.start();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyError(error))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _next() async {
    if (_result == null || _busy) return;
    if (_index + 1 < _questions!.length) {
      setState(() { _index++; _chosen = null; _result = null; });
      _watch..reset()..start();
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(masarRepositoryProvider).completeDiagnostic(widget.subjectId);
      ref.invalidate(enrollmentsProvider);
      ref.invalidate(progressProvider(widget.subjectId));
      if (mounted) context.go(AppRoutes.map(widget.subjectId));
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
    final questions = _questions;
    return Scaffold(
      appBar: AppBar(title: const Text('التشخيص')),
      body: SafeArea(
        child: questions == null
          ? Center(child: _error == null
              ? const CircularProgressIndicator()
              : Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(friendlyError(_error!)),
                  TextButton(onPressed: _load, child: const Text('جرّب كمان مرة')),
                ]))
          : questions.isEmpty
              ? const Center(child: Text('ما في أسئلة تشخيص حالياً'))
              : _questionBody(questions[_index], questions.length),
      ),
    );
  }

  Widget _questionBody(Question question, int count) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      LinearProgressIndicator(value: (_index + 1) / count, minHeight: 6),
      Padding(
        padding: const EdgeInsets.all(AppSpacing.screen),
        child: Text('سؤال ${_index + 1} من $count · ${question.examLabel}', style: AppText.label),
      ),
      Expanded(child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const SizedBox(height: AppSpacing.lg),
          Text(question.text, style: AppText.title),
          const SizedBox(height: AppSpacing.xl),
          for (final option in question.options) ...[
            OptionCard(
              option: option,
              showLabel: question.kind == QuestionKind.mcq,
              state: optionStateFor(
                label: option.label,
                chosen: _chosen,
                correctAnswer: _result?.correctAnswer,
              ),
              onTap: _chosen == null && !_busy ? () => _answer(option.label) : null,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ]),
      )),
      if (_result != null) Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
        child: PracticeFeedback(
          correct: _result!.correct,
          line: _result!.correct ? 'صح عليك 👌' : 'ولا يهمك، هيك بنتعلم',
          readiness: _result!.readiness,
          delta: _result!.readinessDelta,
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(AppSpacing.screen),
        child: PrimaryButton(
          label: _index + 1 == count ? 'شوف خريطتك' : 'التالي',
          loading: _busy,
          onPressed: _result == null ? null : _next,
        ),
      ),
    ],
  );
}
