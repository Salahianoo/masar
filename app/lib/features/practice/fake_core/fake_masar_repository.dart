// TEMPORARY: a small in-memory MasarRepository implementing CONTRACT §7, so the
// practice flow can be built before Amer's MockMasarRepository lands. Delete then.
import 'dart:async';
import 'dart:math';

import 'masar_repository.dart';
import 'models.dart';

class FakeMasarRepository implements MasarRepository {
  FakeMasarRepository({this.latency = const Duration(milliseconds: 400)}) {
    for (final c in _concepts) {
      final m = _startMastery[c.id]!;
      _mastery[c.id] = _ConceptState(
        theta: log(m / (100 - m)),
        attempts: 1,
        lastSeen: DateTime.now().subtract(const Duration(days: 3)),
      );
    }
  }

  final Duration latency;

  static const subjectId = 'first-aid';
  static const _subject = Subject(
    id: subjectId,
    name: 'ثقافة صحية و اسعافات أولية',
    questionCount: 28,
    conceptCount: 5,
  );

  static const _concepts = [
    Concept(
      id: 'bleeding',
      subjectId: subjectId,
      name: 'النزيف',
      weight: 0.30,
      order: 1,
      explanation: '**النزيف** نوعين رئيسيين:\n\n'
          '- **شرياني:** دم أحمر فاتح بيطلع بدفعات مع نبض القلب. هاد الأخطر.\n'
          '- **وريدي:** دم أغمق بيسيل بهدوء.\n\n'
          'أول إشي دايماً: **ضغط مباشر** على الجرح بقطعة نظيفة، وارفع الطرف فوق مستوى القلب. '
          'إذا الضمادة تشبّعت، **حط فوقها** وما تشيلها.',
    ),
    Concept(
      id: 'fractures',
      subjectId: subjectId,
      name: 'الكسور',
      weight: 0.25,
      order: 2,
      explanation: 'مع أي **كسر**: لا تحاول ترجّع العظمة. **ثبّت الطرف** على وضعه بجبيرة '
          'بتمسك المفصل اللي فوق واللي تحت. الكسر **المفتوح** هو اللي العظم فيه طالع من الجلد.',
    ),
    Concept(
      id: 'burns',
      subjectId: subjectId,
      name: 'الحروق',
      weight: 0.20,
      order: 3,
      explanation: '**الحرق:** برّد المكان بماء جاري فاتر 10 لـ 20 دقيقة. لا ثلج، لا معجون، '
          'ولا تفقع الفقاعات. شيل الخواتم قبل ما يصير تورّم.',
    ),
    Concept(
      id: 'cpr',
      subjectId: subjectId,
      name: 'الإنعاش القلبي',
      weight: 0.15,
      order: 4,
      explanation: '**الإنعاش القلبي للبالغ:** تأكد إن المكان آمن، بعدين **30 ضغطة : 2 نفس**، '
          'بمعدل 100 لـ 120 بالدقيقة، وعمق 5 لـ 6 سم بنص الصدر.',
    ),
    Concept(
      id: 'stress',
      subjectId: subjectId,
      name: 'الضغط النفسي',
      weight: 0.10,
      order: 5,
      explanation: '**الضغط النفسي** حالة بتسبب **عدم توازن داخلي** بالجسم، ومرتبط بهرمون '
          '**الكورتيزول**. مش دايماً سلبي، والتنفس العميق وتنظيم الوقت بيساعدوا.',
    ),
  ];

  // Starting mastery as if the diagnostic is done (matches the mockup's map).
  static const _startMastery = {
    'bleeding': 15,
    'fractures': 85,
    'burns': 50,
    'cpr': 20,
    'stress': 50,
  };

  static const _examLabels = {
    'first-aid-final-2024': 'نهائي 2024',
    'first-aid-mid-2024': 'نصفي 2024',
    'first-aid-final-2023': 'نهائي 2023',
  };

  static final _bank = _buildBank();
  static final _answers = <String, String>{};
  static final _baseDifficulty = <String, double>{};

  // Per instance, so tests don't leak question difficulty into each other.
  late final _difficulty = _bank.isEmpty ? <String, double>{} : Map.of(_baseDifficulty);

  final _mastery = <String, _ConceptState>{};
  final _answeredAt = <String, DateTime>{};
  final _progressCtrl = StreamController<SubjectProgress>.broadcast();
  TodayPlan? _plan;
  final _examDate = DateTime.now().add(const Duration(days: 7));

  /// Test helper: the answer key (the real repo never exposes it).
  String answerFor(String questionId) => _answers[questionId]!;

  /// Test helper: every question in the bank.
  List<Question> get bank => _bank;

  Future<void> _wait() => Future.delayed(latency);

  // ---- §7 math -------------------------------------------------------------

  int _masteryOf(String conceptId) {
    final s = _mastery[conceptId]!;
    return (100 / (1 + exp(-s.theta))).round();
  }

  MasteryStatus _statusOf(String conceptId) {
    final s = _mastery[conceptId]!;
    if (s.attempts == 0) return MasteryStatus.unknown;
    final m = _masteryOf(conceptId);
    if (m < 40) return MasteryStatus.weak;
    if (m < 70) return MasteryStatus.medium;
    return MasteryStatus.strong;
  }

  int _readiness() {
    var sum = 0.0;
    for (final c in _concepts) {
      if (_mastery[c.id]!.attempts == 0) continue;
      sum += c.weight * _masteryOf(c.id);
    }
    return sum.round();
  }

  int get _daysLeft => Enrollment(
        subjectId: subjectId,
        examDate: _examDate,
        diagnosticDone: true,
        readiness: 0,
      ).daysLeft;

  ConceptMastery _cm(Concept c) => ConceptMastery(
        conceptId: c.id,
        name: c.name,
        weight: c.weight,
        mastery: _masteryOf(c.id),
        attempts: _mastery[c.id]!.attempts,
        status: _statusOf(c.id),
      );

  SubjectProgress _progress() {
    final r = _readiness();
    final list = _concepts.map(_cm).toList()
      ..sort((a, b) => b.weight.compareTo(a.weight));
    return SubjectProgress(
      subjectId: subjectId,
      readiness: r,
      projectedReadiness: min(90, r + 7 * _daysLeft),
      concepts: list,
    );
  }

  TodayPlan _buildPlan() {
    double priority(Concept c) => _mastery[c.id]!.attempts == 0
        ? c.weight
        : c.weight * (1 - _masteryOf(c.id) / 100);
    final budget = _daysLeft > 14 ? 12 : 15;
    final top = [..._concepts]..sort((a, b) => priority(b).compareTo(priority(a)));
    final picked = top.take(3).toList();
    final total = picked.fold(0.0, (s, c) => s + priority(c));
    final items = <PlanItem>[
      for (final c in picked)
        PlanItem(
          conceptId: c.id,
          conceptName: c.name,
          count: max(2, (budget * priority(c) / total).round()),
          done: 0,
          isReview: false,
          status: _statusOf(c.id),
        ),
    ];
    final now = DateTime.now();
    final reviews = _concepts.where((c) =>
        _statusOf(c.id) == MasteryStatus.strong &&
        now.difference(_mastery[c.id]!.lastSeen).inDays >= 2);
    for (final c in reviews.take(2)) {
      items.add(PlanItem(
        conceptId: c.id,
        conceptName: c.name,
        count: 1,
        done: 0,
        isReview: true,
        status: _statusOf(c.id),
      ));
    }
    final questions = items.fold(0, (s, i) => s + i.count);
    return TodayPlan(
      subjectId: subjectId,
      daysLeft: _daysLeft,
      minutes: (questions * 1.3).round(),
      items: items,
      completed: false,
    );
  }

  // ---- MasarRepository -----------------------------------------------------

  @override
  Future<void> signIn() async {}

  @override
  Future<UserProfile?> currentProfile() async =>
      const UserProfile(uid: 'fake', displayName: 'سارة');

  @override
  Future<void> updateProfile(String displayName) async {}

  @override
  Future<AppConfig> config() async {
    await _wait();
    return const AppConfig(mentorName: 'المرشد', mentorEnabled: true);
  }

  @override
  Future<List<Subject>> subjects() async {
    await _wait();
    return const [_subject];
  }

  @override
  Future<List<Concept>> concepts(String subjectId) async {
    await _wait();
    return _concepts;
  }

  @override
  Future<void> enroll(String subjectId, DateTime examDate) async {}

  @override
  Future<List<Enrollment>> enrollments() async {
    await _wait();
    return [
      Enrollment(
        subjectId: subjectId,
        examDate: _examDate,
        diagnosticDone: true,
        readiness: _readiness(),
      ),
    ];
  }

  @override
  Stream<SubjectProgress> progress(String subjectId) async* {
    yield _progress();
    yield* _progressCtrl.stream;
  }

  @override
  Future<List<Question>> startDiagnostic(String subjectId) async =>
      throw UnimplementedError();

  @override
  Future<SubjectProgress> completeDiagnostic(String subjectId) async =>
      throw UnimplementedError();

  @override
  Future<TodayPlan> todayPlan(String subjectId) async {
    await _wait();
    return _plan ??= _buildPlan();
  }

  @override
  Future<Question?> nextQuestion(String subjectId, {String? conceptId}) async {
    await _wait();
    final now = DateTime.now();
    final cid = conceptId ??
        (_progress().concepts.toList()..sort((a, b) => a.mastery.compareTo(b.mastery)))
            .first
            .conceptId;
    final target = _mastery[cid]!.theta - 0.85;
    final candidates = _bank.where((q) {
      if (q.conceptIds.first != cid) return false;
      final at = _answeredAt[q.id];
      return at == null || now.difference(at).inDays >= 3;
    }).toList()
      ..sort((a, b) => (_difficulty[a.id]! - target)
          .abs()
          .compareTo((_difficulty[b.id]! - target).abs()));
    return candidates.isEmpty ? null : candidates.first;
  }

  @override
  Future<AnswerResult> submitAnswer({
    required String questionId,
    required String chosen,
    required int ms,
    required AnswerSource source,
  }) async {
    await _wait();
    final q = _bank.firstWhere((q) => q.id == questionId);
    final correct = _answers[questionId] == chosen;
    final before = _readiness();
    final r = correct ? 1 : 0;
    final b = _difficulty[q.id]!;
    for (var i = 0; i < q.conceptIds.length; i++) {
      final s = _mastery[q.conceptIds[i]]!;
      final p = 1 / (1 + exp(-(s.theta - b)));
      final k = max(0.25, 0.8 / (1 + 0.15 * s.attempts));
      s.theta += (i == 0 ? 1 : 0.5) * k * (r - p);
      s.attempts++;
      s.lastSeen = DateTime.now();
      s.recent = [...s.recent, correct];
      if (s.recent.length > 3) s.recent = s.recent.sublist(s.recent.length - 3);
    }
    final pPrimary = 1 / (1 + exp(-(_mastery[q.conceptIds.first]!.theta - b)));
    _difficulty[q.id] = b - 0.05 * (r - pPrimary);
    _answeredAt[q.id] = DateTime.now();

    if (source == AnswerSource.plan && _plan != null) {
      final items = [..._plan!.items];
      final i = items.indexWhere(
          (it) => it.conceptId == q.conceptIds.first && it.done < it.count);
      if (i >= 0) {
        final it = items[i];
        items[i] = PlanItem(
          conceptId: it.conceptId,
          conceptName: it.conceptName,
          count: it.count,
          done: it.done + 1,
          isReview: it.isReview,
          status: _statusOf(it.conceptId),
        );
      }
      _plan = TodayPlan(
        subjectId: _plan!.subjectId,
        daysLeft: _plan!.daysLeft,
        minutes: _plan!.minutes,
        items: items,
        completed: items.every((it) => it.done >= it.count),
      );
    }

    final after = _readiness();
    _progressCtrl.add(_progress());

    final primary = _concepts.firstWhere((c) => c.id == q.conceptIds.first);
    final recent = _mastery[primary.id]!.recent;
    final nudge = recent.length >= 2 && !recent[recent.length - 1] && !recent[recent.length - 2]
        ? MentorNudge(
            conceptId: primary.id,
            conceptName: primary.name,
            message: 'شكلك ملخبط شوي بـ${primary.name}. بدك أشرحلك بدقيقة؟',
          )
        : null;

    return AnswerResult(
      correct: correct,
      correctAnswer: _answers[questionId]!,
      readiness: after,
      readinessDelta: after - before,
      updated: [
        for (final id in q.conceptIds) _cm(_concepts.firstWhere((c) => c.id == id)),
      ],
      nudge: nudge,
    );
  }

  @override
  Future<List<Exam>> exams(String subjectId) async {
    await _wait();
    return [
      for (final e in _examLabels.entries)
        Exam(
          id: e.key,
          subjectId: subjectId,
          label: e.value,
          pdfUrl: null,
          questionCount: _bank.where((q) => q.examId == e.key).length,
        ),
    ];
  }

  @override
  Future<List<Question>> examQuestions(String examId) async {
    await _wait();
    return _bank.where((q) => q.examId == examId).toList();
  }

  @override
  Future<String> askMentor({
    required String subjectId,
    String? conceptId,
    required List<ChatMessage> messages,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1500));
    final c = _concepts.where((c) => c.id == conceptId).firstOrNull;
    return c == null
        ? 'سؤال حلو! احكيلي أي مفهوم بالمادة محيرك وبشرحلك ياه خطوة خطوة.'
        : 'ببساطة: ${c.explanation}';
  }

  @override
  Future<List<ReadinessPoint>> readinessHistory(String subjectId) async => [];

  // ---- Data ----------------------------------------------------------------

  static List<Question> _buildBank() {
    const ab = ['أ', 'ب', 'ج', 'د'];
    final exams = _examLabels.keys.toList();
    final out = <Question>[];
    var n = 0;
    // (conceptIds, text, options or null for true/false, answer label, difficulty)
    final raw = <(List<String>, String, List<String>?, String, double)>[
      (['bleeding'], 'أول إجراء عند النزيف الشرياني هو:',
          ['رفع الطرف للأعلى', 'الضغط المباشر على الجرح', 'وضع كمادة باردة', 'إعطاء المصاب ماء'], 'ب', -0.4),
      (['bleeding'], 'لون الدم في النزيف الشرياني:',
          ['أحمر قاتم ويسيل بهدوء', 'أحمر فاتح ويندفع بدفعات', 'أصفر شفاف', 'أسود'], 'ب', -0.2),
      (['bleeding'], 'يُستخدم الرباط الضاغط (التورنيكه) كأول خيار لأي نزيف بسيط.', null, 'خطأ', 0.0),
      (['bleeding'], 'عند نزيف الأنف، التصرف الصحيح هو:',
          ['إمالة الرأس للخلف', 'إمالة الرأس للأمام والضغط على الأنف', 'الاستلقاء على الظهر', 'سد الأنف بقطن مبلل'], 'ب', 0.2),
      (['bleeding'], 'النزيف الوريدي يتميز بأن الدم:',
          ['يندفع بقوة مع النبض', 'يسيل بهدوء ولونه أغمق', 'يخرج على شكل نقاط صغيرة', 'لا يتوقف أبداً'], 'ب', -0.1),
      (['bleeding'], 'إذا تشبّعت الضمادة بالدم، نشيلها ونحط ضمادة جديدة مكانها.', null, 'خطأ', 0.3),
      (['bleeding'], 'من علامات الصدمة الناتجة عن النزيف:',
          ['احمرار الوجه', 'شحوب وتعرّق بارد ونبض سريع', 'ارتفاع الحرارة', 'بطء التنفس فقط'], 'ب', 0.4),
      (['bleeding', 'fractures'], 'رفع الطرف المصاب فوق مستوى القلب بيقلل النزيف، إلا إذا في كسر مشتبه فيه.', null, 'صح', 0.5),
      (['fractures'], 'أول إشي بنعمله مع كسر مشتبه فيه:',
          ['نرجّع العظمة لمكانها', 'نثبّت الطرف على وضعه', 'نطلب من المصاب يمشي', 'ندلّك مكان الإصابة'], 'ب', -0.3),
      (['fractures'], 'الكسر المفتوح هو:',
          ['كسر بدون جرح', 'كسر يخترق فيه العظم الجلد', 'كسر بالأصابع فقط', 'شرخ بسيط'], 'ب', -0.1),
      (['fractures'], 'الجبيرة لازم تثبّت المفصل اللي فوق والمفصل اللي تحت الكسر.', null, 'صح', 0.1),
      (['fractures'], 'من علامات الكسر:',
          ['ألم وتورّم وتشوّه بالشكل', 'حكة بالجلد', 'عطش شديد', 'سعال'], 'أ', 0.2),
      (['fractures'], 'بنربط الجبيرة بقوة حتى لو صارت الأصابع زرقاء.', null, 'خطأ', 0.3),
      (['burns'], 'أول إجراء للحرق البسيط:',
          ['وضع معجون أسنان', 'تبريد المكان بماء جاري فاتر 10–20 دقيقة', 'وضع ثلج مباشرة', 'فقع الفقاعات'], 'ب', -0.3),
      (['burns'], 'بنفقع الفقاعات حتى يطلع السائل ويرتاح المصاب.', null, 'خطأ', -0.1),
      (['burns'], 'حروق الدرجة الثانية بتتميز بـ:',
          ['احمرار فقط', 'فقاعات وألم شديد', 'تفحّم بدون ألم', 'ما في إشي ظاهر'], 'ب', 0.1),
      (['burns'], 'إذا اشتعلت النار بملابس شخص، لازم:',
          ['يركض', 'يوقف، ينبطح ويتدحرج', 'يرش ماء على وجهه فقط', 'يخلع ملابسه وهو بيركض'], 'ب', 0.2),
      (['burns'], 'بنشيل الخواتم والأساور من الطرف المحروق قبل ما يتورّم.', null, 'صح', 0.3),
      (['cpr'], 'نسبة الضغطات إلى الأنفاس للبالغ:', ['15:2', '30:2', '5:1', '10:1'], 'ب', -0.3),
      (['cpr'], 'معدل الضغطات بالدقيقة:', ['60–80', '100–120', '140–160', '40–50'], 'ب', -0.1),
      (['cpr'], 'بنبلش الإنعاش القلبي قبل ما نتأكد إن المكان آمن.', null, 'خطأ', 0.0),
      (['cpr'], 'عمق الضغط على صدر البالغ تقريباً:', ['1 سم', '5–6 سم', '10 سم', '2 سم'], 'ب', 0.2),
      (['cpr'], 'مكان الضغط الصحيح:',
          ['أعلى البطن', 'منتصف الصدر على النصف السفلي لعظمة القص', 'الجهة اليسرى من الصدر', 'الرقبة'], 'ب', 0.4),
      (['stress'], 'يعرف الضغط النفسي على أنه:',
          ['حالة تؤدي إلى عدم توازن خارجي', 'حالة تؤدي إلى عدم توازن داخلي', 'حالة تؤدي إلى توازن داخلي', 'إفراز هرمونات جديدة'], 'ب', -0.2),
      (['stress'], 'من الهرمونات المرتبطة بالضغط النفسي:', ['الأنسولين', 'الكورتيزول', 'الميلاتونين', 'هرمون النمو'], 'ب', 0.0),
      (['stress'], 'الضغط النفسي دايماً سلبي وما إله أي فايدة.', null, 'خطأ', 0.1),
      (['stress'], 'من طرق التعامل الصحي مع الضغط:',
          ['السهر الطويل', 'التنفس العميق وتنظيم الوقت', 'الإكثار من الكافيين', 'العزلة التامة'], 'ب', 0.2),
      (['stress'], 'قلة النوم بتزيد أعراض الضغط النفسي.', null, 'صح', 0.3),
    ];
    for (final (ids, text, opts, answer, diff) in raw) {
      n++;
      final id = 'q$n';
      final examId = exams[n % exams.length];
      out.add(Question(
        id: id,
        subjectId: subjectId,
        examId: examId,
        examLabel: _examLabels[examId]!,
        kind: opts == null ? QuestionKind.truefalse : QuestionKind.mcq,
        text: text,
        options: opts == null
            ? const [
                QuestionOption(label: 'صح', text: 'صح'),
                QuestionOption(label: 'خطأ', text: 'خطأ'),
              ]
            : [
                for (var i = 0; i < opts.length; i++)
                  QuestionOption(label: ab[i], text: opts[i]),
              ],
        conceptIds: ids,
      ));
      _answers[id] = answer;
      _baseDifficulty[id] = diff;
    }
    return out;
  }
}

class _ConceptState {
  _ConceptState({required this.theta, required this.attempts, required this.lastSeen});
  double theta;
  int attempts;
  DateTime lastSeen;
  List<bool> recent = [];
}
