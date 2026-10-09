import '../models/models.dart';

/// CONTRACT §6, verbatim. Implemented by LocalMasarRepository and (Salah's)
/// FirebaseMasarRepository.
abstract class MasarRepository {
  Future<void> signIn();                                  // anonymous auth
  Future<UserProfile?> currentProfile();
  Future<void> updateProfile(String displayName);
  Future<AppConfig> config();
  Future<List<Subject>> subjects();
  Future<List<Concept>> concepts(String subjectId);
  Future<void> enroll(String subjectId, DateTime examDate);
  Future<List<Enrollment>> enrollments();
  Stream<SubjectProgress> progress(String subjectId);    // live, from users/{uid}/mastery
  Future<List<Question>> startDiagnostic(String subjectId);
  Future<SubjectProgress> completeDiagnostic(String subjectId);
  Future<TodayPlan> todayPlan(String subjectId);
  Future<Question?> nextQuestion(String subjectId, {String? conceptId});
  Future<AnswerResult> submitAnswer({required String questionId, required String chosen,
                                     required int ms, required AnswerSource source});
  Future<List<Exam>> exams(String subjectId);
  Future<List<Question>> examQuestions(String examId);   // ordered by question order in the paper
  Future<String> askMentor({required String subjectId, String? conceptId,
                            required List<ChatMessage> messages});
  Future<List<ReadinessPoint>> readinessHistory(String subjectId);
}
