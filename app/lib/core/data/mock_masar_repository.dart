import 'dart:async';
import 'dart:math' as math;

import '../models/models.dart';
import 'learning_engine.dart';
import 'masar_repository.dart';
import 'mock_data.dart';

/// In-memory fake that behaves like the real backend (CONTRACT §7 math).
/// State lives for the app session only; a hot restart starts fresh.
class MockMasarRepository implements MasarRepository {
  MockMasarRepository({
    DateTime Function()? clock,
    this.simulateLatency = true,
    math.Random? random,
  })  : _clock = clock ?? DateTime.now,
        _random = random ?? math.Random();

  final DateTime Function() _clock;
  final bool simulateLatency;
  final math.Random _random;

  final List<MockQuestion> _questions = buildMockQuestions();
  late final Map<String, MockQuestion> _byId = {for (final q in _questions) q.question.id: q};
  late final Map<String, Concept> _conceptById = {for (final c in mockConcepts) c.id: c};

  bool _signedIn = false;
  UserProfile? _profile;
  final Map<String, Enrollment> _enrollments = {};
  final Map<String, Map<String, _ConceptState>> _mastery = {}; // subjectId → conceptId → state
  final Map<String, Map<String, int>> _history = {}; // subjectId → dayKey → readiness
  final Map<String, TodayPlan> _plans = {}; // "{subjectId}_{dayKey}"
  final List<_Attempt> _attempts = [];
  final Map<String, StreamController<SubjectProgress>> _progressControllers = {};

  // ── helpers ──────────────────────────────────────────────────────────────

  Future<void> _latency([int minMs = 300, int maxMs = 600]) async {
    if (!simulateLatency) return;
    await Future<void>.delayed(
      Duration(milliseconds: minMs + _random.nextInt(maxMs - minMs + 1)),
    );
  }

  void _requireSignIn() {
    if (!_signedIn) throw const MockRepositoryException('سجّل دخول أول');
  }

  String get _today => dateToIso(_clock());

  List<Concept> _conceptsOf(String subjectId) =>
      mockConcepts.where((c) => c.subjectId == subjectId).toList()
        ..sort((a, b) => b.weight.compareTo(a.weight));

  Map<String, _ConceptState> _stateOf(String subjectId) => _mastery.putIfAbsent(
        subjectId,
        () => {for (final c in _conceptsOf(subjectId)) c.id: _ConceptState()},
      );

  int _daysLeft(String subjectId) => _enrollments[subjectId]?.daysLeft ?? 0;

  ConceptMastery _masteryOf(Concept c, _ConceptState s) {
    final m = LearningEngine.mastery(s.theta);
    return ConceptMastery(
      conceptId: c.id,
      name: c.name,
      weight: c.weight,
      mastery: m,
      attempts: s.attempts,
      status: LearningEngine.status(attempts: s.attempts, mastery: m),
    );
  }

  SubjectProgress _progressOf(String subjectId) {
    final states = _stateOf(subjectId);
    final concepts = [for (final c in _conceptsOf(subjectId)) _masteryOf(c, states[c.id]!)];
    final readiness = LearningEngine.readiness(
      concepts.map((c) => (weight: c.weight, mastery: c.mastery, attempts: c.attempts)),
    );
    return SubjectProgress(
      subjectId: subjectId,
      readiness: readiness,
      projectedReadiness: LearningEngine.projectedReadiness(readiness, _daysLeft(subjectId)),
      concepts: concepts,
    );
  }

  StreamController<SubjectProgress> _controller(String subjectId) => _progressControllers
      .putIfAbsent(subjectId, () => StreamController<SubjectProgress>.broadcast());

  void _emit(String subjectId) => _controller(subjectId).add(_progressOf(subjectId));

  void _checkSubject(String subjectId) {
    if (subjectId != mockSubjectId) {
      throw const MockRepositoryException('هاي المادة مش موجودة');
    }
  }

  // ── auth + profile ───────────────────────────────────────────────────────

  @override
  Future<void> signIn() async {
    await _latency();
    _signedIn = true;
  }

  @override
  Future<UserProfile?> currentProfile() async {
    await _latency();
    _requireSignIn();
    return _profile;
  }

  @override
  Future<void> updateProfile(String displayName) async {
    await _latency();
    _requireSignIn();
    final name = displayName.trim();
    if (name.isEmpty) throw const MockRepositoryException('اكتب اسمك');
    _profile = UserProfile(uid: 'mock-user', displayName: name);
  }

  @override
  Future<AppConfig> config() async {
    await _latency();
    return mockConfig;
  }

  // ── content ──────────────────────────────────────────────────────────────

  @override
  Future<List<Subject>> subjects() async {
    await _latency();
    return const [mockSubject];
  }

  @override
  Future<List<Concept>> concepts(String subjectId) async {
    await _latency();
    _checkSubject(subjectId);
    return mockConcepts.where((c) => c.subjectId == subjectId).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  @override
  Future<List<Exam>> exams(String subjectId) async {
    await _latency();
    _checkSubject(subjectId);
    return mockExams.where((e) => e.subjectId == subjectId).toList();
  }

  @override
  Future<List<Question>> examQuestions(String examId) async {
    await _latency();
    if (!mockExams.any((e) => e.id == examId)) {
      throw const MockRepositoryException('هاد الامتحان مش موجود');
    }
    return [for (final q in _questions) if (q.question.examId == examId) q.question];
  }

  // ── enrollment ───────────────────────────────────────────────────────────

  @override
  Future<void> enroll(String subjectId, DateTime examDate) async {
    await _latency();
    _requireSignIn();
    _checkSubject(subjectId);
    final existing = _enrollments[subjectId];
    _enrollments[subjectId] = existing?.copyWith(examDate: examDate) ??
        Enrollment(subjectId: subjectId, examDate: examDate, diagnosticDone: false, readiness: 0);
    _stateOf(subjectId);
    _emit(subjectId); // projectedReadiness depends on daysLeft
  }

  @override
  Future<List<Enrollment>> enrollments() async {
    await _latency();
    _requireSignIn();
    return _enrollments.values.toList();
  }

  @override
  Stream<SubjectProgress> progress(String subjectId) async* {
    _checkSubject(subjectId);
    final controller = _controller(subjectId);
    yield _progressOf(subjectId);
    yield* controller.stream;
  }

  // ── diagnostic ───────────────────────────────────────────────────────────

  @override
  Future<List<Question>> startDiagnostic(String subjectId) async {
    await _latency();
    _requireSignIn();
    _checkSubject(subjectId);
    final usedExams = <String>{};
    final picked = <Question>[];
    for (final c in _conceptsOf(subjectId).take(LearningEngine.diagnosticSize)) {
      final candidates = _questions.where((q) => q.question.primaryConceptId == c.id).toList()
        ..sort((a, b) {
          // closest to difficulty 0, then prefer an exam not used yet
          final d = a.difficulty.abs().compareTo(b.difficulty.abs());
          if (d != 0) return d;
          final aUsed = usedExams.contains(a.question.examId) ? 1 : 0;
          final bUsed = usedExams.contains(b.question.examId) ? 1 : 0;
          return aUsed - bUsed;
        });
      if (candidates.isEmpty) continue;
      // among near-ties (within 0.15), prefer a different exam
      final best = candidates.first;
      final alt = candidates.firstWhere(
        (q) =>
            !usedExams.contains(q.question.examId) &&
            (q.difficulty.abs() - best.difficulty.abs()) <= 0.15,
        orElse: () => best,
      );
      usedExams.add(alt.question.examId);
      picked.add(alt.question);
    }
    return picked;
  }

  @override
  Future<SubjectProgress> completeDiagnostic(String subjectId) async {
    await _latency();
    _requireSignIn();
    final e = _enrollments[subjectId];
    if (e == null) throw const MockRepositoryException('سجّل بالمادة أول');
    final p = _progressOf(subjectId);
    _enrollments[subjectId] = e.copyWith(diagnosticDone: true, readiness: p.readiness);
    _history.putIfAbsent(subjectId, () => {})[_today] = p.readiness;
    _emit(subjectId);
    return p;
  }

  // ── plan ─────────────────────────────────────────────────────────────────

  @override
  Future<TodayPlan> todayPlan(String subjectId) async {
    await _latency();
    _requireSignIn();
    _checkSubject(subjectId);
    final key = '${subjectId}_$_today';
    return _plans[key] ??= _buildPlan(subjectId);
  }

  TodayPlan _buildPlan(String subjectId) {
    final states = _stateOf(subjectId);
    final concepts = _conceptsOf(subjectId);
    final daysLeft = _daysLeft(subjectId);

    final ranked = concepts.map((c) {
      final s = states[c.id]!;
      final m = LearningEngine.mastery(s.theta);
      return (
        concept: c,
        state: s,
        mastery: m,
        priority: LearningEngine.priority(weight: c.weight, mastery: m, attempts: s.attempts),
      );
    }).toList()
      ..sort((a, b) => b.priority.compareTo(a.priority));

    final top = ranked.take(LearningEngine.planConcepts).toList();
    final counts = LearningEngine.splitBudget(
      top.map((t) => t.priority).toList(),
      LearningEngine.dailyBudget(daysLeft),
    );
    final items = <PlanItem>[
      for (var i = 0; i < top.length; i++)
        PlanItem(
          conceptId: top[i].concept.id,
          conceptName: top[i].concept.name,
          count: counts[i],
          done: 0,
          isReview: false,
          status: LearningEngine.status(attempts: top[i].state.attempts, mastery: top[i].mastery),
        ),
    ];

    // up to 2 review questions from strong concepts not seen for ≥ 2 days, stalest first
    final now = _clock();
    final topIds = top.map((t) => t.concept.id).toSet();
    final review = ranked
        .where((r) =>
            !topIds.contains(r.concept.id) &&
            LearningEngine.status(attempts: r.state.attempts, mastery: r.mastery) ==
                MasteryStatus.strong &&
            r.state.lastSeen != null &&
            now.difference(r.state.lastSeen!).inDays >= LearningEngine.reviewAfterDays)
        .toList()
      ..sort((a, b) => a.state.lastSeen!.compareTo(b.state.lastSeen!));
    final reviewPicks = review.take(LearningEngine.reviewQuestions).toList();
    for (final r in reviewPicks) {
      items.add(PlanItem(
        conceptId: r.concept.id,
        conceptName: r.concept.name,
        // 2 questions split across the picked concepts (2 if only one qualifies)
        count: LearningEngine.reviewQuestions ~/ reviewPicks.length,
        done: 0,
        isReview: true,
        status: MasteryStatus.strong,
      ));
    }

    final total = items.fold(0, (sum, i) => sum + i.count);
    return TodayPlan(
      subjectId: subjectId,
      daysLeft: daysLeft,
      minutes: LearningEngine.planMinutes(total),
      items: items,
      completed: false,
    );
  }

  // ── practice ─────────────────────────────────────────────────────────────

  @override
  Future<Question?> nextQuestion(String subjectId, {String? conceptId}) async {
    await _latency();
    _requireSignIn();
    _checkSubject(subjectId);
    final states = _stateOf(subjectId);
    final target = conceptId ?? _defaultConcept(subjectId);
    final state = states[target];
    if (state == null) throw const MockRepositoryException('هاد المفهوم مش موجود');

    final candidates = _questions.where((q) => q.question.conceptIds.contains(target)).toList();
    final cutoff = _clock().subtract(const Duration(days: LearningEngine.skipRecentDays));
    final lastAnswered = <String, DateTime>{
      for (final a in _attempts) a.questionId: a.at,
    };
    final fresh = candidates
        .where((q) => !(lastAnswered[q.question.id]?.isAfter(cutoff) ?? false))
        .toList();

    final goal = LearningEngine.targetDifficulty(state.theta);
    if (fresh.isNotEmpty) {
      fresh.sort((a, b) => (a.difficulty - goal).abs().compareTo((b.difficulty - goal).abs()));
      return fresh.first.question;
    }
    // The mock only has ~5 questions per concept, so it runs out long before real
    // data would. Fall back to the least recently answered one instead of null.
    if (candidates.isEmpty) return null;
    candidates.sort((a, b) => lastAnswered[a.question.id]!.compareTo(lastAnswered[b.question.id]!));
    return candidates.first.question;
  }

  /// No concept given: the first unfinished plan item, else the top priority concept.
  String _defaultConcept(String subjectId) {
    final plan = _plans['${subjectId}_$_today'];
    final open = plan?.items.where((i) => !i.isDone);
    if (open != null && open.isNotEmpty) return open.first.conceptId;
    final states = _stateOf(subjectId);
    final concepts = _conceptsOf(subjectId)
      ..sort((a, b) {
        double p(Concept c) {
          final s = states[c.id]!;
          return LearningEngine.priority(
              weight: c.weight, mastery: LearningEngine.mastery(s.theta), attempts: s.attempts);
        }
        return p(b).compareTo(p(a));
      });
    return concepts.first.id;
  }

  @override
  Future<AnswerResult> submitAnswer({
    required String questionId,
    required String chosen,
    required int ms,
    required AnswerSource source,
  }) async {
    await _latency();
    _requireSignIn();
    final mq = _byId[questionId];
    if (mq == null) throw const MockRepositoryException('السؤال مش موجود');
    final q = mq.question;
    final subjectId = q.subjectId;
    final states = _stateOf(subjectId);
    final before = _progressOf(subjectId).readiness;
    final correct = chosen == mq.answer;
    final now = _clock();

    // question difficulty learns from the primary concept's theta before the update
    final primary = states[q.primaryConceptId]!;
    final newB = LearningEngine.updateDifficulty(b: mq.difficulty, theta: primary.theta, correct: correct);

    for (var i = 0; i < q.conceptIds.length; i++) {
      final s = states[q.conceptIds[i]];
      if (s == null) continue;
      s.theta = LearningEngine.updateTheta(
        theta: s.theta,
        b: mq.difficulty,
        attempts: s.attempts,
        correct: correct,
        secondary: i > 0,
      );
      s.attempts++;
      if (correct) s.correct++;
      s.lastSeen = now;
      s.recent.add(correct);
      if (s.recent.length > 3) s.recent.removeAt(0);
    }
    mq.difficulty = newB;

    _attempts.add(_Attempt(questionId: questionId, at: now));

    if (source == AnswerSource.plan) _countPlanAnswer(subjectId, q.primaryConceptId);

    final after = _progressOf(subjectId);
    final e = _enrollments[subjectId];
    if (e != null) _enrollments[subjectId] = e.copyWith(readiness: after.readiness);
    _history.putIfAbsent(subjectId, () => {})[_today] = after.readiness;
    _emit(subjectId);

    final recent = primary.recent;
    final confused =
        recent.length >= 2 && !recent[recent.length - 1] && !recent[recent.length - 2];
    final concept = _conceptById[q.primaryConceptId]!;

    return AnswerResult(
      correct: correct,
      correctAnswer: mq.answer,
      readiness: after.readiness,
      readinessDelta: after.readiness - before,
      updated: [
        for (final id in q.conceptIds)
          if (_conceptById[id] != null) _masteryOf(_conceptById[id]!, states[id]!),
      ],
      nudge: confused
          ? MentorNudge(
              conceptId: concept.id,
              conceptName: concept.name,
              message: LearningEngine.nudgeMessage(concept.name),
            )
          : null,
    );
  }

  void _countPlanAnswer(String subjectId, String conceptId) {
    final key = '${subjectId}_$_today';
    final plan = _plans[key];
    if (plan == null) return;
    final idx = plan.items.indexWhere((i) => i.conceptId == conceptId && !i.isDone);
    if (idx < 0) return;
    final states = _stateOf(subjectId);
    final s = states[conceptId]!;
    final items = [...plan.items];
    items[idx] = items[idx].copyWith(
      done: items[idx].done + 1,
      status: LearningEngine.status(attempts: s.attempts, mastery: LearningEngine.mastery(s.theta)),
    );
    _plans[key] = plan.copyWith(items: items, completed: items.every((i) => i.isDone));
  }

  // ── mentor + history ─────────────────────────────────────────────────────

  @override
  Future<String> askMentor({
    required String subjectId,
    String? conceptId,
    required List<ChatMessage> messages,
  }) async {
    await _latency(1400, 1600);
    _requireSignIn();
    final concept = conceptId == null ? null : _conceptById[conceptId];
    final question = messages.lastWhere((m) => m.isUser, orElse: () => const ChatMessage(role: 'user', text: '')).text;
    if (concept == null) {
      return 'سؤال حلو! أنا هون عشان أساعدك بمادة «${mockSubject.name}». '
          'احكيلي أي مفهوم محيّرك (مثلاً النزيف أو الكسور) وبشرحلك ياه خطوة خطوة.';
    }
    final firstPoint = concept.explanation.split('\n').firstWhere((l) => l.trim().isNotEmpty);
    return 'خليني أبسّطلك **${concept.name}** 👇\n\n$firstPoint\n\n'
        '${question.isEmpty ? '' : 'وبالنسبة لسؤالك «$question»: '}'
        'ركّز على الفكرة الأساسية، وجرّب سؤال من امتحان سابق عشان تتأكد إنك فهمتها.';
  }

  @override
  Future<List<ReadinessPoint>> readinessHistory(String subjectId) async {
    await _latency();
    _requireSignIn();
    _checkSubject(subjectId);
    final h = _history[subjectId] ?? const {};
    final keys = h.keys.toList()..sort();
    return [for (final k in keys) ReadinessPoint(day: DateTime.parse(k), readiness: h[k]!)];
  }
}

class _ConceptState {
  double theta = LearningEngine.initialTheta;
  int attempts = 0;
  int correct = 0;
  DateTime? lastSeen;
  final List<bool> recent = []; // last 3, newest last
}

class _Attempt {
  final String questionId;
  final DateTime at;
  const _Attempt({required this.questionId, required this.at});
}

/// Mirrors a callable HttpsError: [message] is Arabic and safe to show.
class MockRepositoryException implements Exception {
  final String message;
  const MockRepositoryException(this.message);
  @override
  String toString() => message;
}
