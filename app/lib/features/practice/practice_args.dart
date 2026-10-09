/// How a practice session picks its questions (route `/practice/:subjectId`).
enum PracticeMode {
  /// Today's plan, item by item (`mode=plan`).
  plan,

  /// 8 questions on one concept (`conceptId` given, no plan).
  concept,

  /// A past paper in paper order (`mode=exam&examId=...`).
  exam,
}

class PracticeArgs {
  const PracticeArgs({
    required this.subjectId,
    required this.mode,
    this.conceptId,
    this.examId,
  });

  /// Parses the route params: `/practice/:subjectId?mode=plan|exam&conceptId=&examId=`.
  factory PracticeArgs.fromRoute(String subjectId, Map<String, String> query) {
    final examId = query['examId'];
    final conceptId = query['conceptId'];
    final mode = query['mode'] == 'exam' || (examId != null && examId.isNotEmpty)
        ? PracticeMode.exam
        : (conceptId != null && conceptId.isNotEmpty ? PracticeMode.concept : PracticeMode.plan);
    return PracticeArgs(
      subjectId: subjectId,
      mode: mode,
      conceptId: conceptId,
      examId: examId,
    );
  }

  final String subjectId;
  final PracticeMode mode;
  final String? conceptId;
  final String? examId;
}
