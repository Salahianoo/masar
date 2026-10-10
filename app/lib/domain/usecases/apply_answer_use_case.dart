import 'package:masar/domain/services/learning_engine.dart';

typedef AnswerConceptState = ({
  double theta, int attempts, int correct, DateTime? lastSeen, List<bool> recent,
});
typedef AppliedAnswer = ({
  double difficulty, Map<String, AnswerConceptState> states,
});

/// Applies one answer to the question and its primary/secondary concepts.
abstract final class ApplyAnswerUseCase {
  static AppliedAnswer apply({
    required List<String> conceptIds,
    required Map<String, AnswerConceptState> states,
    required double difficulty,
    required bool correct,
    required DateTime now,
  }) {
    final primary = states[conceptIds.first]!;
    final nextDifficulty = LearningEngine.updateDifficulty(
      b: difficulty, theta: primary.theta, correct: correct);
    final changed = <String, AnswerConceptState>{};
    for (var index = 0; index < conceptIds.length; index++) {
      final id = conceptIds[index];
      final state = states[id];
      if (state == null) continue;
      changed[id] = (
        theta: LearningEngine.updateTheta(
          theta: state.theta, b: difficulty, attempts: state.attempts,
          correct: correct, secondary: index > 0),
        attempts: state.attempts + 1,
        correct: state.correct + (correct ? 1 : 0),
        lastSeen: now,
        recent: [...state.recent, correct].skip(
          state.recent.length >= 3 ? state.recent.length - 2 : 0).toList(),
      );
    }
    return (difficulty: nextDifficulty, states: changed);
  }
}
