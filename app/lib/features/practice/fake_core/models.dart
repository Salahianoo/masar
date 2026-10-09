// TEMPORARY: CONTRACT §6 models, until Amer's core/models lands. Delete then.
// Field names are exactly the contract's; no JSON here (the fake never serializes).

enum QuestionKind { mcq, truefalse }

enum MasteryStatus { unknown, weak, medium, strong }

enum AnswerSource { diagnostic, plan, khazna }

class AppConfig {
  final String mentorName;
  final bool mentorEnabled;
  const AppConfig({required this.mentorName, required this.mentorEnabled});
}

class UserProfile {
  final String uid;
  final String displayName;
  const UserProfile({required this.uid, required this.displayName});
}

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
}

class QuestionOption {
  final String label;
  final String text;
  const QuestionOption({required this.label, required this.text});
}

class Question {
  final String id;
  final String subjectId;
  final String examId;
  final String examLabel;
  final QuestionKind kind;
  final String text;
  final List<QuestionOption> options;
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
}

class Enrollment {
  final String subjectId;
  final DateTime examDate;
  final bool diagnosticDone;
  final int readiness;
  const Enrollment({
    required this.subjectId,
    required this.examDate,
    required this.diagnosticDone,
    required this.readiness,
  });
  int get daysLeft {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final exam = DateTime(examDate.year, examDate.month, examDate.day);
    final d = exam.difference(today).inDays;
    return d < 0 ? 0 : d;
  }
}

class ConceptMastery {
  final String conceptId;
  final String name;
  final double weight;
  final int mastery;
  final int attempts;
  final MasteryStatus status;
  const ConceptMastery({
    required this.conceptId,
    required this.name,
    required this.weight,
    required this.mastery,
    required this.attempts,
    required this.status,
  });
}

class SubjectProgress {
  final String subjectId;
  final int readiness;
  final int projectedReadiness;
  final List<ConceptMastery> concepts;
  const SubjectProgress({
    required this.subjectId,
    required this.readiness,
    required this.projectedReadiness,
    required this.concepts,
  });
}

class PlanItem {
  final String conceptId;
  final String conceptName;
  final int count;
  final int done;
  final bool isReview;
  final MasteryStatus status;
  const PlanItem({
    required this.conceptId,
    required this.conceptName,
    required this.count,
    required this.done,
    required this.isReview,
    required this.status,
  });
}

class TodayPlan {
  final String subjectId;
  final int daysLeft;
  final int minutes;
  final List<PlanItem> items;
  final bool completed;
  const TodayPlan({
    required this.subjectId,
    required this.daysLeft,
    required this.minutes,
    required this.items,
    required this.completed,
  });
}

class MentorNudge {
  final String conceptId;
  final String conceptName;
  final String message;
  const MentorNudge({
    required this.conceptId,
    required this.conceptName,
    required this.message,
  });
}

class AnswerResult {
  final bool correct;
  final String correctAnswer;
  final int readiness;
  final int readinessDelta;
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
}

class ChatMessage {
  final String role; // "user" | "mentor"
  final String text;
  const ChatMessage({required this.role, required this.text});
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
}

class ReadinessPoint {
  final DateTime day;
  final int readiness;
  const ReadinessPoint({required this.day, required this.readiness});
}
