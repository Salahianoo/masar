import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:masar/presentation/state/providers.dart';
import 'package:masar/domain/entities/entities.dart';
import 'package:masar/presentation/navigation/router.dart';
import 'package:masar/presentation/themes/app_theme.dart';
import 'package:masar/presentation/components/widgets.dart';
import 'package:masar/presentation/screens/practice/widgets/option_card.dart';

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

  /// Right answers so far; the running percentage and the final score.
  int _correct = 0;
  int _answered = 0;
  bool _finished = false;
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
      setState(() {
        _questions = questions; _index = 0; _chosen = null; _result = null;
        _correct = 0; _answered = 0; _finished = false;
      });
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
      if (mounted) {
        setState(() {
          _result = result;
          _answered++;
          if (result.correct) _correct++;
        });
      }
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
      if (mounted) setState(() => _finished = true);
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
              : _finished
                  ? _scoreBody(questions.length)
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
        child: _AnswerFeedback(result: _result!, correct: _correct, answered: _answered),
      ),
      Padding(
        padding: const EdgeInsets.all(AppSpacing.screen),
        child: PrimaryButton(
          label: _index + 1 == count ? 'شوف نتيجتك' : 'التالي',
          loading: _busy,
          onPressed: _result == null ? null : _next,
        ),
      ),
    ],
  );

  /// After the last answer: the total, then on to the concept map.
  Widget _scoreBody(int count) {
    final percent = count == 0 ? 0 : (_correct * 100 / count).round();
    final good = percent >= 70;
    final mid = percent >= 40;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screen),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Spacer(),
        Center(child: MentorAvatar(
          pose: good ? MentorPose.happy : mid ? MentorPose.pointing : MentorPose.thinking, size: 150)),
        const SizedBox(height: AppSpacing.xl),
        Text('نتيجة التشخيص', style: AppText.heading, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.sm),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: percent.toDouble()),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) =>
              Text('${value.round()}%', style: AppText.display, textAlign: TextAlign.center),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text('جبت $_correct من $count صح', style: AppText.bodyBold, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.md),
        Text(
          good
              ? 'بداية قوية! خريطتك بتورجيك شو ضايل تثبّته.'
              : mid
                  ? 'منيح كبداية. خريطتك بتورجيك وين تركّز.'
                  : 'ولا يهمك، لهيك عملنا التشخيص. خطتك بتبلّش من الأساسيات.',
          style: AppText.label,
          textAlign: TextAlign.center,
        ),
        const Spacer(),
        PrimaryButton(label: 'شوف خريطتك',
            onPressed: () => context.go(AppRoutes.map(widget.subjectId))),
      ]),
    );
  }
}

/// «صح ✓» or «غلط، الجواب: ب», with the score so far.
class _AnswerFeedback extends StatelessWidget {
  const _AnswerFeedback({required this.result, required this.correct, required this.answered});

  final AnswerResult result;
  final int correct;
  final int answered;

  @override
  Widget build(BuildContext context) {
    final color = (result.correct ? MasteryStatus.strong : MasteryStatus.weak).color;
    final percent = answered == 0 ? 0 : (correct * 100 / answered).round();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: .4)),
      ),
      child: Row(children: [
        Icon(result.correct ? Icons.check_circle_rounded : Icons.cancel_rounded, color: color),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            result.correct ? 'صح' : 'غلط، الجواب: ${result.correctAnswer}',
            style: AppText.bodyBold.copyWith(color: color),
          ),
        ),
        Text('$correct من $answered · $percent%', style: AppText.label),
      ]),
    );
  }
}
