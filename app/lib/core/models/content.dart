import 'enums.dart';
import 'json_utils.dart';

class Subject {
  final String id;
  final String name;
  final int questionCount;
  final int conceptCount;

  const Subject({
    required this.id,
    required this.name,
    required this.questionCount,
    required this.conceptCount,
  });

  factory Subject.fromJson(Map<String, dynamic> json) => Subject(
        id: json['id'] as String,
        name: json['name'] as String,
        questionCount: asInt(json['questionCount']),
        conceptCount: asInt(json['conceptCount']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'questionCount': questionCount,
        'conceptCount': conceptCount,
      };
}

class Concept {
  final String id;
  final String subjectId;
  final String name;
  final double weight;
  final String explanation;
  final int order;

  const Concept({
    required this.id,
    required this.subjectId,
    required this.name,
    required this.weight,
    required this.explanation,
    required this.order,
  });

  factory Concept.fromJson(Map<String, dynamic> json) => Concept(
        id: json['id'] as String,
        subjectId: json['subjectId'] as String,
        name: json['name'] as String,
        weight: asDouble(json['weight']),
        explanation: json['explanation'] as String? ?? '',
        order: asInt(json['order']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'subjectId': subjectId,
        'name': name,
        'weight': weight,
        'explanation': explanation,
        'order': order,
      };
}

class QuestionOption {
  final String label;
  final String text;

  const QuestionOption({required this.label, required this.text});

  factory QuestionOption.fromJson(Map<String, dynamic> json) => QuestionOption(
        label: json['label'] as String,
        text: json['text'] as String? ?? json['label'] as String,
      );

  Map<String, dynamic> toJson() => {'label': label, 'text': text};
}

class Question {
  final String id;
  final String subjectId;
  final String examId;
  final String examLabel;
  final QuestionKind kind;
  final String text;
  final List<QuestionOption> options;

  /// 1–2 concept ids, the first is the primary concept.
  final List<String> conceptIds;

  const Question({
    required this.id,
    required this.subjectId,
    required this.examId,
    required this.examLabel,
    required this.kind,
    required this.text,
    required this.options,
    required this.conceptIds,
  });

  String get primaryConceptId => conceptIds.first;

  factory Question.fromJson(Map<String, dynamic> json) => Question(
        id: json['id'] as String,
        subjectId: json['subjectId'] as String,
        examId: json['examId'] as String,
        examLabel: json['examLabel'] as String,
        kind: QuestionKind.values.byName(json['kind'] as String),
        text: json['text'] as String,
        options: asJsonList(json['options']).map(QuestionOption.fromJson).toList(),
        conceptIds: List<String>.from(json['conceptIds'] as List),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'subjectId': subjectId,
        'examId': examId,
        'examLabel': examLabel,
        'kind': kind.name,
        'text': text,
        'options': options.map((o) => o.toJson()).toList(),
        'conceptIds': conceptIds,
      };
}

class Exam {
  final String id;
  final String subjectId;
  final String label;
  final String? pdfUrl;
  final int questionCount;

  const Exam({
    required this.id,
    required this.subjectId,
    required this.label,
    required this.pdfUrl,
    required this.questionCount,
  });

  factory Exam.fromJson(Map<String, dynamic> json) => Exam(
        id: json['id'] as String,
        subjectId: json['subjectId'] as String,
        label: json['label'] as String,
        pdfUrl: json['pdfUrl'] as String?,
        questionCount: asInt(json['questionCount']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'subjectId': subjectId,
        'label': label,
        'pdfUrl': pdfUrl,
        'questionCount': questionCount,
      };
}
