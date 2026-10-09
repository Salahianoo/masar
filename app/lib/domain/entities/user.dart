import 'package:masar/core/utils/json_utils.dart';

class AppConfig {
  final String mentorName;
  final bool mentorEnabled;

  const AppConfig({required this.mentorName, required this.mentorEnabled});

  factory AppConfig.fromJson(Map<String, dynamic> json) => AppConfig(
        mentorName: json['mentorName'] as String? ?? '',
        mentorEnabled: json['mentorEnabled'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() =>
      {'mentorName': mentorName, 'mentorEnabled': mentorEnabled};
}

class UserProfile {
  final String uid;
  final String displayName;

  const UserProfile({required this.uid, required this.displayName});

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        uid: json['uid'] as String,
        displayName: json['displayName'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {'uid': uid, 'displayName': displayName};

  UserProfile copyWith({String? displayName}) =>
      UserProfile(uid: uid, displayName: displayName ?? this.displayName);
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

  /// Whole days from today to the exam day, never negative.
  int get daysLeft => daysUntil(examDate);

  /// Calendar-day difference on the device's local date.
  static int daysUntil(DateTime examDate, [DateTime? now]) {
    final n = now ?? DateTime.now();
    final today = DateTime.utc(n.year, n.month, n.day);
    final exam = DateTime.utc(examDate.year, examDate.month, examDate.day);
    final days = exam.difference(today).inDays;
    return days < 0 ? 0 : days;
  }

  factory Enrollment.fromJson(Map<String, dynamic> json) => Enrollment(
        subjectId: json['subjectId'] as String,
        examDate: asDate(json['examDate']),
        diagnosticDone: json['diagnosticDone'] as bool? ?? false,
        readiness: asInt(json['readiness']),
      );

  Map<String, dynamic> toJson() => {
        'subjectId': subjectId,
        'examDate': dateToIso(examDate),
        'diagnosticDone': diagnosticDone,
        'readiness': readiness,
      };

  Enrollment copyWith({DateTime? examDate, bool? diagnosticDone, int? readiness}) =>
      Enrollment(
        subjectId: subjectId,
        examDate: examDate ?? this.examDate,
        diagnosticDone: diagnosticDone ?? this.diagnosticDone,
        readiness: readiness ?? this.readiness,
      );
}
