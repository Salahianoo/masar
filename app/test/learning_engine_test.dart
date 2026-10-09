import 'package:flutter_test/flutter_test.dart';
import 'package:masar/domain/services/learning_engine.dart';
import 'package:masar/data/datasources/local/local_data.g.dart';
import 'package:masar/data/repositories/local_masar_repository.dart';
import 'package:masar/data/datasources/local/session_store.dart';
import 'package:masar/data/datasources/remote/rafeeq_client.dart';
import 'package:masar/domain/entities/entities.dart';

void main() {
  group('LearningEngine (CONTRACT §7)', () {
    test('starting theta -1 gives mastery 27', () {
      expect(LearningEngine.mastery(LearningEngine.initialTheta), 27);
      expect(LearningEngine.mastery(0), 50);
    });

    test('status thresholds', () {
      expect(LearningEngine.status(attempts: 0, mastery: 90), MasteryStatus.unknown);
      expect(LearningEngine.status(attempts: 1, mastery: 39), MasteryStatus.weak);
      expect(LearningEngine.status(attempts: 1, mastery: 40), MasteryStatus.medium);
      expect(LearningEngine.status(attempts: 1, mastery: 69), MasteryStatus.medium);
      expect(LearningEngine.status(attempts: 1, mastery: 70), MasteryStatus.strong);
    });

    test('theta update: correct goes up, wrong goes down, secondary is half', () {
      const theta = -1.0, b = 0.0;
      final up = LearningEngine.updateTheta(theta: theta, b: b, attempts: 0, correct: true);
      final down = LearningEngine.updateTheta(theta: theta, b: b, attempts: 0, correct: false);
      final half = LearningEngine.updateTheta(
          theta: theta, b: b, attempts: 0, correct: true, secondary: true);
      final p = LearningEngine.pCorrect(theta, b);
      expect(up, closeTo(theta + 0.8 * (1 - p), 1e-9));
      expect(down, closeTo(theta + 0.8 * (0 - p), 1e-9));
      expect(half - theta, closeTo((up - theta) / 2, 1e-9));
    });

    test('student step shrinks with attempts, floor 0.25', () {
      expect(LearningEngine.studentStep(0), 0.8);
      expect(LearningEngine.studentStep(100), 0.25);
    });

    test('readiness counts unknown concepts as 0', () {
      final r = LearningEngine.readiness([
        (weight: 0.5, mastery: 80, attempts: 3),
        (weight: 0.5, mastery: 27, attempts: 0),
      ]);
      expect(r, 40);
    });

    test('projected readiness caps at 90', () {
      expect(LearningEngine.projectedReadiness(34, 2), 48);
      expect(LearningEngine.projectedReadiness(34, 30), 90);
    });

    test('budget split is proportional with a minimum of 2', () {
      final counts = LearningEngine.splitBudget([0.18, 0.16, 0.01], 15);
      expect(counts.reduce((a, b) => a + b), 15);
      expect(counts[2], 2);
      expect(counts[0], greaterThanOrEqualTo(counts[1]));
    });
  });

  group('LocalMasarRepository (the five real papers)', () {
    late LocalMasarRepository repo;
    late _FakeRafeeq rafeeq;
    const subject = 'first-aid';

    setUp(() async {
      rafeeq = _FakeRafeeq();
      repo = LocalMasarRepository(rafeeq: rafeeq);
      await repo.signIn();
      await repo.updateProfile('سارة');
      await repo.enroll(subject, DateTime.now().add(const Duration(days: 7)));
    });

    test('five subjects; weights sum to 1; every question has a concept and an answer option', () {
      expect(localSubjects.map((s) => s.id),
          ['computer-ethics', 'environment', 'first-aid', 'databases', 'military-science']);
      for (final s in localSubjects) {
        final sum = localConcepts.where((c) => c.subjectId == s.id).fold(0.0, (t, c) => t + c.weight);
        expect(sum, closeTo(1.0, 1e-3), reason: s.id);
      }
      final all = buildLocalQuestions();
      expect(all.length, 276);
      expect(all.where((q) => q.flagged).length, 6);
      final conceptIds = localConcepts.map((c) => c.id).toSet();
      for (final q in all) {
        expect(q.question.options.map((o) => o.label), contains(q.answer), reason: q.question.id);
        expect(conceptIds, containsAll(q.question.conceptIds), reason: q.question.id);
      }
      for (final e in localExams) {
        final n = all.where((q) => q.question.examId == e.id && !q.flagged).length;
        expect(n, e.questionCount, reason: e.id);
      }
    });

    test('flagged questions are never served', () async {
      final flagged = buildLocalQuestions().where((q) => q.flagged).map((q) => q.question.id).toSet();
      final served = <String>{
        for (final s in localSubjects) ...(await repo.startDiagnostic(s.id)).map((q) => q.id),
        for (final e in localExams) ...(await repo.examQuestions(e.id)).map((q) => q.id),
      };
      expect(served.intersection(flagged), isEmpty);
      expect(() => repo.submitAnswer(
              questionId: flagged.first, chosen: 'أ', ms: 1, source: AnswerSource.plan),
          throwsA(isA<LocalRepositoryException>()));
    });

    test('diagnostic: 8 questions, one per concept', () async {
      final qs = await repo.startDiagnostic(subject);
      expect(qs.length, 8);
      expect(qs.map((q) => q.primaryConceptId).toSet().length, 8);
    });

    test('readiness is 0 before any answer and matches the formula after', () async {
      final start = await repo.progress(subject).first;
      expect(start.readiness, 0);
      expect(start.concepts.every((c) => c.status == MasteryStatus.unknown), isTrue);

      final answers = {for (final q in buildLocalQuestions()) q.question.id: q.answer};
      for (final q in await repo.startDiagnostic(subject)) {
        await repo.submitAnswer(
            questionId: q.id, chosen: answers[q.id]!, ms: 3000, source: AnswerSource.diagnostic);
      }
      final p = await repo.completeDiagnostic(subject);
      final expected = p.concepts.fold(0.0, (s, c) => s + c.weight * c.mastery).round();
      expect(p.readiness, expected);
      expect(p.readiness, greaterThan(0));
      expect(p.projectedReadiness, LearningEngine.projectedReadiness(p.readiness, 7));
    });

    test('correct answer raises readiness; two wrong in a row bring a nudge', () async {
      final bank = buildLocalQuestions()
          .where((q) => !q.flagged && q.question.primaryConceptId == 'wounds-bleeding');
      final right = bank.first;
      final r1 = await repo.submitAnswer(
          questionId: right.question.id, chosen: right.answer, ms: 1, source: AnswerSource.plan);
      expect(r1.correct, isTrue);
      expect(r1.readinessDelta, greaterThan(0));
      expect(r1.nudge, isNull);

      AnswerResult? last;
      for (final q in bank.skip(1).take(2)) {
        last = await repo.submitAnswer(
            questionId: q.question.id, chosen: 'غلط', ms: 1, source: AnswerSource.plan);
      }
      expect(last!.correct, isFalse);
      expect(last.nudge?.conceptId, 'wounds-bleeding');
    });

    test('plan: top 3 by priority, 15 questions, done counts go up', () async {
      final plan = await repo.todayPlan(subject);
      expect(plan.items.length, 3);
      expect(plan.totalCount, 15);
      final top = localConcepts.where((c) => c.subjectId == subject).reduce((a, b) => a.weight >= b.weight ? a : b);
      expect(plan.items.first.conceptId, top.id); // highest weight, all unknown

      final q = await repo.nextQuestion(subject);
      expect(q!.conceptIds, contains(top.id));
      await repo.submitAnswer(questionId: q.id, chosen: q.options.first.label, ms: 1, source: AnswerSource.plan);
      final after = await repo.todayPlan(subject);
      expect(after.items.first.done, 1);
    });

    test('progress() emits after every submitAnswer', () async {
      final emitted = <int>[];
      final sub = repo.progress(subject).listen((p) => emitted.add(p.readiness));
      await Future<void>.delayed(Duration.zero);
      final q = buildLocalQuestions().firstWhere((q) => !q.flagged && q.question.subjectId == subject);
      await repo.submitAnswer(questionId: q.question.id, chosen: q.answer, ms: 1, source: AnswerSource.plan);
      await Future<void>.delayed(Duration.zero);
      expect(emitted.length, 2);
      expect(emitted.last, greaterThan(emitted.first));
      await sub.cancel();
    });

    test('askMentor sends رفيق the persona, the inferred concept and real answers', () async {
      final reply = await repo.askMentor(
        subjectId: subject,
        messages: const [ChatMessage(role: 'user', text: 'ما فهمت شو الفرق بين النزيف الداخلي والخارجي')],
      );
      expect(reply, 'رد رفيق');
      final system = rafeeq.lastSystem!;
      expect(system, contains('إنت رفيق'));
      expect(system, contains('ثقافة صحية و اسعافات أولية'));
      expect(system, contains('المفهوم: الجروح والنزيف'));
      expect(system, contains('الجواب الصحيح:'));
      expect(system, isNot(contains('{grounding}')));
      expect(rafeeq.lastHistory!.single.role, 'user');

      await repo.askMentor(subjectId: subject, messages: const [ChatMessage(role: 'user', text: 'مرحبا')]);
      expect(rafeeq.lastSystem, contains('مفاهيم المادة:'));
    });

    test('askMentor explains when the PC connection is not configured', () async {
      final offline = LocalMasarRepository(rafeeq: RafeeqClient(url: '', token: ''));
      await offline.signIn();
      expect(
        () => offline.askMentor(subjectId: subject, messages: const [ChatMessage(role: 'user', text: 'مرحبا')]),
        throwsA(isA<LocalRepositoryException>().having((e) => e.message, 'message', contains('مش موصول بالكمبيوتر'))),
      );
    });

    test('session survives a restart: name, subjects, mastery, history, plan', () async {
      final store = MemorySessionStore();
      final first = LocalMasarRepository(rafeeq: rafeeq, store: store);
      await first.signIn();
      await first.updateProfile('سارة');
      await first.enroll(subject, DateTime.now().add(const Duration(days: 7)));
      await first.enroll('databases', DateTime.now().add(const Duration(days: 10)));
      final answers = {for (final q in buildLocalQuestions()) q.question.id: q.answer};
      for (final q in await first.startDiagnostic(subject)) {
        await first.submitAnswer(questionId: q.id, chosen: answers[q.id]!, ms: 1, source: AnswerSource.diagnostic);
      }
      final before = await first.completeDiagnostic(subject);
      final plan = await first.todayPlan(subject);

      final second = LocalMasarRepository(rafeeq: rafeeq, store: store); // the app relaunched
      await second.signIn();
      expect((await second.currentProfile())?.displayName, 'سارة');
      expect((await second.enrollments()).map((e) => e.subjectId), [subject, 'databases']);
      expect((await second.enrollments()).first.diagnosticDone, isTrue);
      final after = await second.progress(subject).first;
      expect(after.readiness, before.readiness);
      expect(after.concepts.map((c) => c.mastery), before.concepts.map((c) => c.mastery));
      expect((await second.readinessHistory(subject)).last.readiness, before.readiness);
      expect((await second.todayPlan(subject)).items.map((i) => i.conceptId), plan.items.map((i) => i.conceptId));
    });

    test('signOut forgets the student on this device', () async {
      final store = MemorySessionStore();
      final repo = LocalMasarRepository(rafeeq: rafeeq, store: store);
      await repo.signIn();
      await repo.updateProfile('سارة');
      await repo.enroll(subject, DateTime.now().add(const Duration(days: 7)));
      await repo.signOut();
      expect(await store.load(), isNull);

      final relaunched = LocalMasarRepository(rafeeq: rafeeq, store: store);
      await relaunched.signIn();
      expect(await relaunched.currentProfile(), isNull);
      expect(await relaunched.enrollments(), isEmpty);
    });

    test('a second subject gets its own diagnostic and progress', () async {
      await repo.enroll('databases', DateTime.now().add(const Duration(days: 10)));
      final qs = await repo.startDiagnostic('databases');
      expect(qs, isNotEmpty);
      expect(qs.every((q) => q.subjectId == 'databases'), isTrue);
      final p = await repo.progress('databases').first;
      expect(p.concepts.length, 4);
      expect((await repo.progress(subject).first).concepts.length, 8);
    });

    test('examQuestions keeps paper order', () async {
      final qs = await repo.examQuestions('aid-mid');
      expect(qs.length, localExams.firstWhere((e) => e.id == 'aid-mid').questionCount);
      expect(qs.first.id, 'aid-mid-0-0');
    });
  });
}

class _FakeRafeeq extends RafeeqClient {
  _FakeRafeeq() : super(url: 'http://test', token: 'test');
  String? lastSystem;
  List<({String role, String text})>? lastHistory;

  @override
  Future<String> chat({required String system, required List<({String role, String text})> history}) async {
    lastSystem = system;
    lastHistory = history;
    return 'رد رفيق';
  }
}
