import 'package:flutter_test/flutter_test.dart';
import 'package:masar/core/data/learning_engine.dart';
import 'package:masar/core/data/mock_data.dart';
import 'package:masar/core/data/mock_masar_repository.dart';
import 'package:masar/core/models/models.dart';

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

  group('MockMasarRepository', () {
    late MockMasarRepository repo;

    setUp(() async {
      repo = MockMasarRepository(simulateLatency: false);
      await repo.signIn();
      await repo.updateProfile('سارة');
      await repo.enroll(mockSubjectId, DateTime.now().add(const Duration(days: 7)));
    });

    test('concept weights sum to 1 and the bank has 40 questions', () {
      final sum = mockConcepts.fold(0.0, (s, c) => s + c.weight);
      expect(sum, closeTo(1.0, 1e-9));
      expect(buildMockQuestions().length, 40);
      for (final e in mockExams) {
        final n = buildMockQuestions().where((q) => q.question.examId == e.id).length;
        expect(n, e.questionCount, reason: e.id);
      }
    });

    test('diagnostic: 8 questions, one per concept, several exams', () async {
      final qs = await repo.startDiagnostic(mockSubjectId);
      expect(qs.length, 8);
      expect(qs.map((q) => q.primaryConceptId).toSet().length, 8);
      expect(qs.map((q) => q.examId).toSet().length, greaterThan(1));
    });

    test('readiness is 0 before any answer and matches the formula after', () async {
      final start = await repo.progress(mockSubjectId).first;
      expect(start.readiness, 0);
      expect(start.concepts.every((c) => c.status == MasteryStatus.unknown), isTrue);

      final answers = {for (final q in buildMockQuestions()) q.question.id: q.answer};
      for (final q in await repo.startDiagnostic(mockSubjectId)) {
        await repo.submitAnswer(
            questionId: q.id, chosen: answers[q.id]!, ms: 3000, source: AnswerSource.diagnostic);
      }
      final p = await repo.completeDiagnostic(mockSubjectId);
      final expected =
          p.concepts.fold(0.0, (s, c) => s + c.weight * c.mastery).round();
      expect(p.readiness, expected);
      expect(p.readiness, greaterThan(0));
      expect(p.projectedReadiness, LearningEngine.projectedReadiness(p.readiness, 7));
    });

    test('correct answer raises readiness; two wrong in a row bring a nudge', () async {
      final bank = buildMockQuestions().where((q) => q.question.primaryConceptId == 'bleeding');
      final right = bank.first;
      final r1 = await repo.submitAnswer(
          questionId: right.question.id, chosen: right.answer, ms: 1, source: AnswerSource.plan);
      expect(r1.correct, isTrue);
      expect(r1.readinessDelta, greaterThan(0));
      expect(r1.nudge, isNull);

      final wrong = bank.skip(1).take(2).toList();
      AnswerResult? last;
      for (final q in wrong) {
        last = await repo.submitAnswer(
            questionId: q.question.id, chosen: 'غلط', ms: 1, source: AnswerSource.plan);
      }
      expect(last!.correct, isFalse);
      expect(last.nudge?.conceptId, 'bleeding');
      expect(last.nudge?.message, 'شكلك ملخبط شوي بـالنزيف. بدك أشرحلك بدقيقة؟');
    });

    test('plan: top 3 by priority, 15 questions, done counts go up', () async {
      final plan = await repo.todayPlan(mockSubjectId);
      expect(plan.items.length, 3);
      expect(plan.totalCount, 15);
      expect(plan.minutes, 20);
      expect(plan.items.first.conceptId, 'bleeding'); // highest weight, all unknown

      final q = await repo.nextQuestion(mockSubjectId);
      expect(q!.conceptIds, contains('bleeding'));
      await repo.submitAnswer(questionId: q.id, chosen: 'أ', ms: 1, source: AnswerSource.plan);
      final after = await repo.todayPlan(mockSubjectId);
      expect(after.items.first.done, 1);
    });

    test('progress() emits after every submitAnswer', () async {
      final emitted = <int>[];
      final sub = repo.progress(mockSubjectId).listen((p) => emitted.add(p.readiness));
      await Future<void>.delayed(Duration.zero);
      final q = buildMockQuestions().first;
      await repo.submitAnswer(questionId: q.question.id, chosen: q.answer, ms: 1, source: AnswerSource.plan);
      await Future<void>.delayed(Duration.zero);
      expect(emitted.length, 2);
      expect(emitted.last, greaterThan(emitted.first));
      await sub.cancel();
    });

    test('askMentor without conceptId infers the concept from the message', () async {
      final reply = await repo.askMentor(
        subjectId: mockSubjectId,
        messages: const [ChatMessage(role: 'user', text: 'ما فهمت شو الفرق بين النزيف الشرياني والوريدي')],
      );
      expect(reply, contains('النزيف'));
      final overview = await repo.askMentor(
        subjectId: mockSubjectId,
        messages: const [ChatMessage(role: 'user', text: 'مرحبا')],
      );
      expect(overview, contains(mockSubject.name));
    });

    test('examQuestions keeps paper order', () async {
      final qs = await repo.examQuestions('first-aid-final-2024');
      expect(qs.length, 13);
      expect(qs.first.id, 'fa-bleeding-1');
    });
  });
}
