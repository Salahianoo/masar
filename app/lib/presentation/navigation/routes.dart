/// Every path in the app. Use these instead of typing paths by hand.
abstract final class AppRoutes {
  static const splash = '/';
  static const onboarding = '/onboarding';

  // tabs
  static const home = '/home';
  static const khazna = '/khazna';
  static const mentor = '/mentor';
  static const profile = '/profile';

  static String diagnostic(String subjectId) => '/diagnostic/$subjectId';
  static String map(String subjectId) => '/map/$subjectId';
  static String summary(String subjectId) => '/summary/$subjectId';
  static String khaznaExam(String examId) => '/khazna/exam/$examId';
  static String mentorChat(String subjectId, {String? conceptId}) => Uri(
    path: '/mentor/$subjectId',
    queryParameters: {'conceptId': ?conceptId},
  ).toString();

  /// `mode`: "plan" or "exam". `conceptId` alone = concept practice.
  static String practice(
    String subjectId, {
    String? conceptId,
    String? examId,
    String? mode,
  }) =>
      Uri(
        path: '/practice/$subjectId',
        queryParameters: {
          'conceptId': ?conceptId,
          'examId': ?examId,
          'mode': ?mode,
        },
      ).toString();
}
