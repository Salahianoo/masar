import 'package:masar/domain/entities/content.dart';
import 'package:masar/domain/services/learning_engine.dart';

typedef DiagnosticCandidate = ({Question question, double difficulty});

/// Selects one question for each high-weight concept without accessing storage.
abstract final class DiagnosticUseCase {
  static List<Question> pick(List<Concept> concepts, Iterable<DiagnosticCandidate> questions) {
    final usedExams = <String>{};
    final picked = <Question>[];
    for (final concept in concepts.take(LearningEngine.diagnosticSize)) {
      final candidates = questions.where((item) => item.question.primaryConceptId == concept.id).toList()
        ..sort((a, b) {
          final distance = a.difficulty.abs().compareTo(b.difficulty.abs());
          if (distance != 0) return distance;
          final aUsed = usedExams.contains(a.question.examId) ? 1 : 0;
          final bUsed = usedExams.contains(b.question.examId) ? 1 : 0;
          return aUsed - bUsed;
        });
      if (candidates.isEmpty) continue;
      final best = candidates.first;
      final chosen = candidates.firstWhere(
        (item) => !usedExams.contains(item.question.examId) &&
            (item.difficulty.abs() - best.difficulty.abs()) <= 0.15,
        orElse: () => best,
      );
      usedExams.add(chosen.question.examId);
      picked.add(chosen.question);
    }
    return picked;
  }
}
