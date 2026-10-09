import 'package:masar/core/utils/json_utils.dart';
import 'package:masar/domain/entities/progress.dart';

class MentorNudge {
  final String conceptId;
  final String conceptName;
  final String message;

  const MentorNudge({
    required this.conceptId,
    required this.conceptName,
    required this.message,
  });

  factory MentorNudge.fromJson(Map<String, dynamic> json) => MentorNudge(
        conceptId: json['conceptId'] as String,
        conceptName: json['conceptName'] as String,
        message: json['message'] as String,
      );

  Map<String, dynamic> toJson() =>
      {'conceptId': conceptId, 'conceptName': conceptName, 'message': message};
}

class AnswerResult {
  final bool correct;

  /// The label of the right option (e.g. "ب" or "صح").
  final String correctAnswer;
  final int readiness;
  final int readinessDelta;

  /// The concepts this answer touched, after the update.
  final List<ConceptMastery> updated;
  final MentorNudge? nudge;

  const AnswerResult({
    required this.correct,
    required this.correctAnswer,
    required this.readiness,
    required this.readinessDelta,
    required this.updated,
    this.nudge,
  });

  factory AnswerResult.fromJson(Map<String, dynamic> json) => AnswerResult(
        correct: json['correct'] as bool,
        correctAnswer: json['correctAnswer'] as String,
        readiness: asInt(json['readiness']),
        readinessDelta: asInt(json['readinessDelta']),
        updated: asJsonList(json['updated']).map(ConceptMastery.fromJson).toList(),
        nudge: json['nudge'] == null ? null : MentorNudge.fromJson(asJsonMap(json['nudge'])),
      );

  Map<String, dynamic> toJson() => {
        'correct': correct,
        'correctAnswer': correctAnswer,
        'readiness': readiness,
        'readinessDelta': readinessDelta,
        'updated': updated.map((c) => c.toJson()).toList(),
        'nudge': nudge?.toJson(),
      };
}

class ChatMessage {
  /// "user" or "mentor".
  final String role;
  final String text;

  const ChatMessage({required this.role, required this.text});

  static const userRole = 'user';
  static const mentorRole = 'mentor';

  bool get isUser => role == userRole;

  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      ChatMessage(role: json['role'] as String, text: json['text'] as String);

  Map<String, dynamic> toJson() => {'role': role, 'text': text};
}
