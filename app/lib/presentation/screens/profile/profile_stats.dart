import 'package:masar/domain/entities/entities.dart';

/// The numbers on the profile, computed from what the screen already has.
class ProfileStats {
  const ProfileStats({
    required this.subjectCount,
    required this.averageReadiness,
    required this.answers,
    required this.statusCounts,
    required this.nearestExamDays,
  });

  final int subjectCount;

  /// Mean readiness over subjects whose diagnostic is done; null when none is.
  final int? averageReadiness;

  /// Concept attempts across all subjects.
  final int answers;

  /// How many concepts sit in each status, across all subjects.
  final Map<MasteryStatus, int> statusCounts;

  /// Days to the closest exam; null without subjects.
  final int? nearestExamDays;

  int get conceptCount => statusCounts.values.fold(0, (a, b) => a + b);
  int get strongCount => statusCounts[MasteryStatus.strong] ?? 0;

  factory ProfileStats.from(
    List<Enrollment> enrollments,
    Map<String, SubjectProgress> progress,
  ) {
    final done = enrollments.where((e) => e.diagnosticDone).toList();
    final readiness = [for (final e in done) progress[e.subjectId]?.readiness ?? e.readiness];
    final counts = {for (final s in MasteryStatus.values) s: 0};
    var answers = 0;
    for (final p in progress.values) {
      for (final c in p.concepts) {
        counts[c.status] = counts[c.status]! + 1;
        answers += c.attempts;
      }
    }
    final days = [for (final e in enrollments) e.daysLeft]..sort();
    return ProfileStats(
      subjectCount: enrollments.length,
      averageReadiness: readiness.isEmpty
          ? null
          : (readiness.reduce((a, b) => a + b) / readiness.length).round(),
      answers: answers,
      statusCounts: counts,
      nearestExamDays: days.isEmpty ? null : days.first,
    );
  }
}
