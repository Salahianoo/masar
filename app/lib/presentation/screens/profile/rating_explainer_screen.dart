import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:masar/domain/services/learning_engine.dart';
import 'package:masar/presentation/themes/app_theme.dart';

/// «كيف بنقيس مستواك؟»: the Elo idea behind mastery, told as a chess match
/// between the student and the question, with a small simulator that runs the
/// app's real [LearningEngine] maths so every number on screen is genuine.
class RatingExplainerScreen extends StatelessWidget {
  const RatingExplainerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('كيف بنقيس مستواك؟')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, AppSpacing.xxl),
          children: const [
            _Hero(),
            SizedBox(height: AppSpacing.xl),
            _Match(),
            SizedBox(height: AppSpacing.xl),
            _Simulator(),
            SizedBox(height: AppSpacing.xl),
            _Rules(),
            SizedBox(height: AppSpacing.xl),
            _FromMasteryToReadiness(),
            SizedBox(height: AppSpacing.lg),
            _Formulas(),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [const Color(0xFF2E5A97), AppPalette.navy, Color.lerp(AppPalette.navy, Colors.black, .3)!],
        ),
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('زي تصنيف أبطال الشطرنج',
                style: AppText.title.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'الاتحاد الدولي للشطرنج بيقيس قوة كل لاعب بطريقة اسمها Elo. '
              'مسار بيستخدم نفس الفكرة: كل مفهوم إلك فيه تصنيف، وكل سؤال إله تصنيف صعوبة.',
              style: AppText.label.copyWith(color: Colors.white.withValues(alpha: .85), height: 1.6),
            ),
          ]),
        ),
        const SizedBox(width: AppSpacing.md),
        Container(
          width: 72,
          height: 72,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: .1),
            border: Border.all(color: AppPalette.teal, width: 2),
          ),
          child: const Text('♞', style: TextStyle(fontSize: 40, color: Colors.white, height: 1)),
        ),
      ]),
    );
  }
}

/// You versus the question: two players, two ratings.
class _Match extends StatelessWidget {
  const _Match();

  @override
  Widget build(BuildContext context) {
    Widget player(IconData icon, String name, String what, Color color) => Expanded(
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(children: [
              Icon(icon, color: color, size: 30),
              const SizedBox(height: AppSpacing.xs),
              Text(name, style: AppText.bodyBold),
              Text(what, style: AppText.caption, textAlign: TextAlign.center),
            ]),
          ),
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('كل جواب مباراة', style: AppText.heading),
      const SizedBox(height: AppSpacing.xs),
      Text('قبل ما تجاوب، منعرف قديش احتمال تفوز، يعني تجاوب صح، حسب الفرق بين تصنيفك وصعوبة السؤال.',
          style: AppText.label),
      const SizedBox(height: AppSpacing.md),
      Row(children: [
        player(Icons.person_rounded, 'أنت', 'تصنيفك بالمفهوم', AppColors.accent),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Text('ضد', style: AppText.title.copyWith(color: AppColors.textMuted)),
        ),
        player(Icons.quiz_rounded, 'السؤال', 'تصنيف صعوبته', AppColors.primary),
      ]),
    ]);
  }
}

/// Pick a question's difficulty, answer it right or wrong, and watch the
/// rating move by exactly what the app would do.
class _Simulator extends StatefulWidget {
  const _Simulator();

  @override
  State<_Simulator> createState() => _SimulatorState();
}

class _SimulatorState extends State<_Simulator> {
  double _theta = LearningEngine.initialTheta;
  int _attempts = 0;
  double _difficulty = 0;
  int? _lastDelta;
  final List<bool> _history = [];

  static const _levels = [(-1.5, 'سهل'), (0.0, 'متوسط'), (1.5, 'صعب')];

  void _answer(bool correct) {
    HapticFeedback.selectionClick();
    final before = LearningEngine.mastery(_theta);
    setState(() {
      _theta = LearningEngine.updateTheta(
          theta: _theta, b: _difficulty, attempts: _attempts, correct: correct);
      _attempts++;
      _history.add(correct);
      _lastDelta = LearningEngine.mastery(_theta) - before;
    });
  }

  void _reset() => setState(() {
        _theta = LearningEngine.initialTheta;
        _attempts = 0;
        _lastDelta = null;
        _history.clear();
      });

  @override
  Widget build(BuildContext context) {
    final mastery = LearningEngine.mastery(_theta);
    final chance = (LearningEngine.pCorrect(_theta, _difficulty) * 100).round();
    final step = LearningEngine.studentStep(_attempts);
    final color = mastery < 40
        ? AppColors.statusWeak
        : mastery < 70
            ? AppColors.statusMedium
            : AppColors.statusStrong;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.accent.withValues(alpha: .5), width: 1.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(child: Text('جرّب بنفسك', style: AppText.heading)),
          TextButton.icon(
            onPressed: _attempts == 0 ? null : _reset,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('من جديد'),
          ),
        ]),
        const SizedBox(height: AppSpacing.md),
        Row(children: [
          // the student's mastery, as a ring
          TweenAnimationBuilder<double>(
            tween: Tween(end: mastery / 100),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (context, t, _) => SizedBox.square(
              dimension: 108,
              child: Stack(alignment: Alignment.center, children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: t,
                    strokeWidth: 9,
                    strokeCap: StrokeCap.round,
                    backgroundColor: AppColors.track,
                    color: color,
                  ),
                ),
                Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('${(t * 100).round()}%',
                      style: AppText.title.copyWith(fontSize: 26, fontWeight: FontWeight.w900, height: 1.1)),
                  Text('إتقانك', style: AppText.caption.copyWith(fontSize: 11.5)),
                ]),
              ]),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _Stat(label: 'احتمال تجاوب صح', value: '$chance%'),
              const SizedBox(height: AppSpacing.sm),
              _Stat(label: 'قديش بتتحرك كل جواب', value: '×${step.toStringAsFixed(2)}'),
              const SizedBox(height: AppSpacing.sm),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _lastDelta == null
                    ? Text('جاوب عشان تشوف التغيير', key: const ValueKey('none'), style: AppText.caption)
                    : Text(
                        '\u2066${_lastDelta! >= 0 ? '+' : ''}$_lastDelta%\u2069 بآخر جواب',
                        key: ValueKey(_attempts),
                        style: AppText.bodyBold.copyWith(
                            color: _lastDelta! >= 0 ? AppColors.statusStrong : AppColors.statusWeak),
                      ),
              ),
            ]),
          ),
        ]),
        const SizedBox(height: AppSpacing.lg),
        Text('صعوبة السؤال', style: AppText.bodyBold),
        const SizedBox(height: AppSpacing.sm),
        SegmentedButton<double>(
          showSelectedIcon: false,
          segments: [for (final (b, name) in _levels) ButtonSegment(value: b, label: Text(name))],
          selected: {_difficulty},
          onSelectionChanged: (s) => setState(() => _difficulty = s.first),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(children: [
          Expanded(
            child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: AppColors.statusStrong, minimumSize: const Size(0, 48)),
              onPressed: () => _answer(true),
              icon: const Icon(Icons.check_rounded),
              label: const Text('جاوبت صح'),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: AppColors.statusWeak, minimumSize: const Size(0, 48)),
              onPressed: () => _answer(false),
              icon: const Icon(Icons.close_rounded),
              label: const Text('جاوبت غلط'),
            ),
          ),
        ]),
        if (_history.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Wrap(spacing: 4, runSpacing: 4, children: [
            for (final ok in _history)
              Icon(ok ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  size: 18, color: ok ? AppColors.statusStrong : AppColors.statusWeak),
          ]),
        ],
        const SizedBox(height: AppSpacing.sm),
        Text('لاحظ: صح على سؤال صعب بيرفعك أكثر من صح على سؤال سهل، والغلط على السهل بينزّلك أكثر.',
            style: AppText.caption),
      ]),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: Text(label, style: AppText.label)),
      Text(value,
          textDirection: TextDirection.ltr,
          style: AppText.bodyBold.copyWith(fontWeight: FontWeight.w800, fontFeatures: const [FontFeature.tabularFigures()])),
    ]);
  }
}

class _Rules extends StatelessWidget {
  const _Rules();

  @override
  Widget build(BuildContext context) {
    Widget rule(IconData icon, String title, String body) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(AppRadius.md)),
              child: Icon(icon, color: AppColors.accent, size: 22),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: AppText.bodyBold),
                Text(body, style: AppText.label.copyWith(height: 1.55)),
              ]),
            ),
          ]),
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('ثلاث قواعد', style: AppText.heading),
      const SizedBox(height: AppSpacing.md),
      rule(Icons.bolt_rounded, 'المفاجأة بتحرّك أكثر',
          'إذا جاوبت صح سؤال كان احتمالك فيه قليل، تصنيفك بيطلع كثير. وإذا غلطت بسؤال سهل، بينزل كثير.'),
      rule(Icons.speed_rounded, 'بالبداية بنتعرّف عليك بسرعة',
          'أول كم سؤال بتحرّك تصنيفك خطوات كبيرة عشان نعرف مستواك بسرعة، ومع التمرين الخطوة بتصغر وبيثبت.'),
      rule(Icons.groups_rounded, 'السؤال كمان بيتعلّم',
          'إذا طلاب كثير غلطوا بسؤال، صعوبته بتطلع لحالها. هيك التقييم بيصير أدق كل ما زاد الطلاب.'),
    ]);
  }
}

class _FromMasteryToReadiness extends StatelessWidget {
  const _FromMasteryToReadiness();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('من الإتقان للجاهزية', style: AppText.heading),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '• التشخيص: ${LearningEngine.diagnosticSize} أسئلة، سؤال لكل مفهوم من أهم المفاهيم بالمادة، '
          'ومن امتحانات مختلفة. كل جواب مباراة، وبالآخر بتطلع خريطتك.\n'
          '• كل مفهوم إله وزن حسب قديش بيتكرر بالامتحانات الحقيقية.\n'
          '• جاهزيتك = مجموع (وزن المفهوم × إتقانك فيه)، فالمفهوم اللي بيجي كثير بيأثر أكثر.\n'
          '• بعدها كل سؤال بنختاره بحيث يكون احتمالك تجاوبه صح حوالي 70%: مش سهل لدرجة الملل ولا صعب لدرجة الإحباط.',
          style: AppText.body.copyWith(height: 1.75),
        ),
      ]),
    );
  }
}

class _Formulas extends StatelessWidget {
  const _Formulas();

  @override
  Widget build(BuildContext context) {
    const mono = TextStyle(fontFamily: 'Menlo', fontSize: 12.5, height: 1.8);
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Text('المعادلات للمهتمين', style: AppText.bodyBold),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(AppRadius.md)),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Text(
                'P = 1 / (1 + e^-(θ − d))        chance of a right answer\n'
                'θ ← θ + K · (result − P)        your rating\n'
                'K = max(0.25, 0.8 / (1 + 0.15·n))\n'
                'd ← d − 0.05 · (result − P)     the question\'s difficulty\n'
                'mastery = 100 / (1 + e^-θ)       start: θ = −1 → 27%',
                style: mono.copyWith(color: AppColors.textPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
