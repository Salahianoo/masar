import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:masar/presentation/state/providers.dart' show todayPlanProvider;
import 'package:masar/presentation/screens/practice/practice_core.dart';
import 'package:masar/presentation/screens/practice/practice_args.dart';
import 'package:masar/presentation/screens/practice/practice_session.dart';
import 'package:masar/presentation/screens/practice/widgets/option_card.dart';
import 'package:masar/presentation/screens/practice/widgets/practice_feedback.dart';

const _anim = Duration(milliseconds: 300);

/// `/practice/:subjectId?mode=plan|exam&conceptId=&examId=`
class PracticeScreen extends ConsumerStatefulWidget {
  const PracticeScreen({super.key, required this.args});

  /// For the router: `builder: (context, state) => PracticeScreen.fromState(state)`.
  factory PracticeScreen.fromState(GoRouterState state) => PracticeScreen(
        args: PracticeArgs.fromRoute(
          state.pathParameters['subjectId']!,
          state.uri.queryParameters,
        ),
      );

  final PracticeArgs args;

  @override
  ConsumerState<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends ConsumerState<PracticeScreen> {
  late PracticeSession _session;
  AsyncValue<void> _load = const AsyncLoading();

  Question? _question;
  int _number = 0; // 1-based number of the question on screen
  String? _chosen;
  AnswerResult? _result;
  String _feedbackLine = '';
  Future<Question?>? _prefetch;
  bool _advancing = false;
  bool _finished = false;
  final _stopwatch = Stopwatch();
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    setState(() => _load = const AsyncLoading());
    _session = PracticeSession(repo: ref.read(masarRepositoryProvider), args: widget.args);
    try {
      await _session.start();
      final q = await _session.next();
      if (!mounted) return;
      setState(() {
        _load = const AsyncData(null);
        _show(q);
      });
    } catch (e, st) {
      if (mounted) setState(() => _load = AsyncError(e, st));
    }
  }

  /// Puts [q] on screen and starts timing it. Call inside setState.
  void _show(Question? q) {
    _question = q;
    if (q != null) _number++;
    _chosen = null;
    _result = null;
    _prefetch = null;
    _stopwatch
      ..reset()
      ..start();
  }

  Future<void> _onOptionTap(String label) async {
    final q = _question;
    if (q == null || _chosen != null) return;
    final ms = _stopwatch.elapsedMilliseconds;
    _stopwatch.stop();
    setState(() => _chosen = label);
    try {
      final r = await _session.answer(q, label, ms);
      if (!mounted) return;
      setState(() {
        _result = r;
        _feedbackLine = pickFeedbackLine(correct: r.correct, random: _random);
        // The answer has updated theta, so the next question can be fetched now.
        _prefetch = _session.next()..ignore();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _chosen = null);
      _stopwatch.start();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ما قدرنا نحفظ جوابك، جرّب كمان مرة')),
      );
    }
  }

  Future<void> _onNext() async {
    final result = _result;
    if (result == null || _advancing) return;
    setState(() => _advancing = true);
    try {
      final q = await _prefetch;
      if (!mounted) return;
      if (q == null) {
        _finish();
        return;
      }
      setState(() => _show(q));
    } catch (_) {
      if (!mounted) return;
      // Retry the fetch on the next tap.
      _prefetch = _session.next()..ignore();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ما قدرنا نجيب السؤال الجاي، جرّب كمان مرة')),
      );
    } finally {
      if (mounted) setState(() => _advancing = false);
    }
  }

  void _finish() {
    _finished = true;
    ref.invalidate(todayPlanProvider(widget.args.subjectId));
    ref.read(lastPracticeResultProvider.notifier).set(_session.toResult());
    context.go('/summary/${widget.args.subjectId}');
  }

  Future<void> _confirmLeave() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('بدك تطلع؟'),
        content: const Text('اللي جاوبته محفوظ، بس الجلسة رح توقف هون.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('بكمل'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('آه، اطلع'),
          ),
        ],
      ),
    );
    if (leave == true && mounted) _leave();
  }

  void _leave() {
    _finished = true;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  bool get _canLeaveFreely => _finished || _session.answered == 0;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _load is! AsyncData || _canLeaveFreely,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: Scaffold(
        body: SafeArea(
          child: AsyncStateView<void>(
            value: _load,
            onRetry: _start,
            isEmpty: (_) => _question == null,
            emptyMessage: widget.args.mode == PracticeMode.plan
                ? 'خطة اليوم خالصة! ارجع بكرة، أو تمرّن على مفهوم من الخريطة'
                : 'ما في أسئلة هون لسا',
            data: (_) => _buildSession(context),
          ),
        ),
      ),
    );
  }

  Widget _buildSession(BuildContext context) {
    final q = _question!;
    final result = _result;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ReadinessBar(readiness: _session.readiness),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(AppSpacing.lg, AppSpacing.sm, AppSpacing.xs, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  [
                    if (_session.conceptNameOf(q).isNotEmpty) _session.conceptNameOf(q),
                    '$_number من ${_session.total}',
                  ].join(' · '),
                  style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (q.examLabel.isNotEmpty) ...[
                Icon(Icons.description_outlined, size: 16, color: cs.onSurfaceVariant),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'من ${q.examLabel}',
                  style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
              IconButton(
                tooltip: 'طلوع',
                icon: const Icon(Icons.close),
                onPressed: () => _canLeaveFreely ? _leave() : _confirmLeave(),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: AnimatedSwitcher(
              duration: _anim,
              child: Column(
                key: ValueKey(q.id),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    q.text,
                    key: const Key('practice.question'),
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  for (final o in q.options) ...[
                    OptionCard(
                      option: o,
                      showLabel: q.kind == QuestionKind.mcq,
                      state: optionStateFor(
                        label: o.label,
                        chosen: _chosen,
                        correctAnswer: result?.correctAnswer,
                      ),
                      onTap: _chosen == null ? () => _onOptionTap(o.label) : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: _anim,
          child: result == null
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
                  child: PracticeFeedback(
                    correct: result.correct,
                    line: _feedbackLine,
                    readiness: result.readiness,
                    delta: result.readinessDelta,
                  ),
                ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
          child: PrimaryButton(
            label: 'التالي',
            onPressed: result == null || _advancing ? null : _onNext,
          ),
        ),
      ],
    );
  }
}

/// Thin bar at the very top that animates to the new readiness.
class _ReadinessBar extends StatelessWidget {
  const _ReadinessBar({required this.readiness});
  final int readiness;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      label: 'الجاهزية $readiness%',
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: readiness / 100),
        duration: _anim,
        curve: Curves.easeOut,
        builder: (context, value, _) => LinearProgressIndicator(
          value: value,
          minHeight: 4,
          backgroundColor: cs.surfaceContainerHighest,
          color: cs.primary,
        ),
      ),
    );
  }
}
