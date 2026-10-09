import 'package:shared_preferences/shared_preferences.dart';

/// Whether this device has already been through the three intro slides.
/// Kept apart from the student's session, so signing out doesn't replay them.
abstract final class IntroSeen {
  static const _key = 'masar.introSeen';

  static Future<bool> read() async {
    try {
      return await SharedPreferencesAsync().getBool(_key) ?? false;
    } catch (_) {
      return false; // no storage (tests): show the intro
    }
  }

  static Future<void> markSeen() async {
    try {
      await SharedPreferencesAsync().setBool(_key, true);
    } catch (_) {
      // the slides just show again next launch
    }
  }
}
