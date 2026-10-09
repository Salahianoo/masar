/// An error whose [message] is Arabic and safe to show the student as-is.
/// Every data source throws (a subclass of) this for anything the user can
/// act on, so the UI never needs to know which data source it came from.
class AppException implements Exception {
  final String message;
  const AppException(this.message);

  @override
  String toString() => message;
}
