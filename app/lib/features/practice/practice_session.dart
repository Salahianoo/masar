import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'practice_core.dart';
import 'practice_args.dart';

/// Questions in concept mode (no plan).
const conceptModeQuestionCount = 8;

/// Supplies the questions of one practice session and records its answers.
/// Pure logic, no widgets: the screen drives it.
class PracticeSession {
  PracticeSession({required this.repo, required this.args});

  final MasarRepository repo;
  final PracticeArgs args;

  final Map<String, String> conceptNames = {};
  final List<ConceptMastery> initialConcepts = [];
  final Map<String, ConceptMastery> updated = {};

  /// Questions this session is expected to have; shrinks if the bank runs dry.
  int total = 0;

  int _paperIndex = 0;
  int answered = 0;
  int correctCount = 0;
  int startReadiness = 0;
  int readiness = 0;

  // plan / concept mode: (conceptId, remaining) slots, walked in order.
  final List<_Slot> _slots = [];
  // exam mode: the paper, in order.
  final List<Question> _paper = [];

  AnswerSource get source =>
      args.mode == PracticeMode.exam ? AnswerSource.khazna : AnswerSource.plan;

  Future<void> start() async {
    final results = await Future.wait([
      repo.concepts(args.subjectId),
      repo.enrollments(),
    ]);
    for (final c in results[0] as List<Concept>) {
      conceptNames[c.id] = c.name;
    }
    final enrollment = (results[1] as List<Enrollment>)
        .where((e) => e.subjectId == args.subjectId)
        .firstOrNull;
    startReadiness = readiness = enrollment?.readiness ?? 0;
    try {
      final p = await repo.progress(args.subjectId).first.timeout(const Duration(seconds: 5));
      initialConcepts.addAll(p.concepts);
      startReadiness = readiness = p.readiness;
    } on TimeoutException {
      // Summary falls back to the readiness from the enrollment.
    }

    switch (args.mode) {
      case PracticeMode.plan:
        final plan = await repo.todayPlan(args.subjectId);
        for (final item in plan.items) {
          final remaining = item.count - item.done;
          if (remaining > 0) _slots.add(_Slot(item.conceptId, remaining));
        }
      case PracticeMode.concept:
        _slots.add(_Slot(args.conceptId!, conceptModeQuestionCount));
      case PracticeMode.exam:
        _paper.addAll(await repo.examQuestions(args.examId!));
    }
    total = args.mode == PracticeMode.exam
        ? _paper.length
        : _slots.fold(0, (s, slot) => s + slot.remaining);
  }

  /// The next question, or null when the session is over.
  Future<Question?> next() async {
    if (args.mode == PracticeMode.exam) {
      return _paperIndex < _paper.length ? _paper[_paperIndex++] : null;
    }
    while (_slots.isNotEmpty) {
      final slot = _slots.first;
      final q = await repo.nextQuestion(args.subjectId, conceptId: slot.conceptId);
      if (q == null) {
        // No fresh questions left on this concept: skip the rest of the item.
        total -= slot.remaining;
        _slots.removeAt(0);
        continue;
      }
      if (--slot.remaining == 0) _slots.removeAt(0);
      return q;
    }
    return null;
  }

  Future<AnswerResult> answer(Question q, String chosen, int ms) async {
    final r = await repo.submitAnswer(
      questionId: q.id,
      chosen: chosen,
      ms: ms,
      source: source,
    );
    answered++;
    if (r.correct) correctCount++;
    readiness = r.readiness;
    for (final c in r.updated) {
      updated[c.conceptId] = c;
    }
    return r;
  }

  String conceptNameOf(Question q) =>
      q.conceptIds.isEmpty ? '' : conceptNames[q.conceptIds.first] ?? '';

  PracticeSessionResult toResult() => PracticeSessionResult(
        subjectId: args.subjectId,
        mode: args.mode,
        startReadiness: startReadiness,
        endReadiness: readiness,
        correct: correctCount,
        answered: answered,
        initialConcepts: List.unmodifiable(initialConcepts),
        updated: List.unmodifiable(updated.values),
      );
}

class _Slot {
  _Slot(this.conceptId, this.remaining);
  final String conceptId;
  int remaining;
}

/// What the session summary (`/summary/:subjectId`) shows.
class PracticeSessionResult {
  const PracticeSessionResult({
    required this.subjectId,
    required this.mode,
    required this.startReadiness,
    required this.endReadiness,
    required this.correct,
    required this.answered,
    required this.initialConcepts,
    required this.updated,
  });

  final String subjectId;
  final PracticeMode mode;
  final int startReadiness;
  final int endReadiness;
  final int correct;
  final int answered;
  final List<ConceptMastery> initialConcepts;
  final List<ConceptMastery> updated;
}

/// The last finished session, handed to the summary screen without router `extra`.
final lastPracticeResultProvider =
    NotifierProvider<LastPracticeResult, PracticeSessionResult?>(LastPracticeResult.new);

class LastPracticeResult extends Notifier<PracticeSessionResult?> {
  @override
  PracticeSessionResult? build() => null;

  void set(PracticeSessionResult result) => state = result;
}
