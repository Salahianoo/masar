import 'package:masar/core/utils/json_utils.dart';
import 'package:masar/domain/entities/progress.dart';

class AnswerResult {
  final bool correct;

  /// The label of the right option (e.g. "ب" or "صح").
  final String correctAnswer;
  final int readiness;
  final int readinessDelta;

  /// The concepts this answer touched, after the update.
  final List<ConceptMastery> updated;

  const AnswerResult({
    required this.correct,
    required this.correctAnswer,
    required this.readiness,
    required this.readinessDelta,
    required this.updated,
  });

  factory AnswerResult.fromJson(Map<String, dynamic> json) => AnswerResult(
        correct: json['correct'] as bool,
        correctAnswer: json['correctAnswer'] as String,
        readiness: asInt(json['readiness']),
        readinessDelta: asInt(json['readinessDelta']),
        updated: asJsonList(json['updated']).map(ConceptMastery.fromJson).toList(),
      );

  Map<String, dynamic> toJson() => {
        'correct': correct,
        'correctAnswer': correctAnswer,
        'readiness': readiness,
        'readinessDelta': readinessDelta,
        'updated': updated.map((c) => c.toJson()).toList(),
      };
}
