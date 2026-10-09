import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Where the local repository keeps the student's session between launches:
/// name, enrolled subjects, mastery per concept, readiness history, today's
/// plan. One JSON snapshot, written after every change.
abstract class SessionStore {
  Future<Map<String, dynamic>?> load();
  Future<void> save(Map<String, dynamic> snapshot);
  Future<void> clear();
}

/// The app's store: SharedPreferences on the device.
class SharedPrefsSessionStore implements SessionStore {
  SharedPrefsSessionStore({SharedPreferencesAsync? prefs}) : _prefs = prefs ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _prefs;

  /// Bump the version when the snapshot's shape changes incompatibly; an old
  /// snapshot is then ignored instead of crashing the launch.
  static const key = 'masar.session.v1';

  @override
  Future<Map<String, dynamic>?> load() async {
    final raw = await _prefs.getString(key);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> save(Map<String, dynamic> snapshot) => _prefs.setString(key, jsonEncode(snapshot));

  @override
  Future<void> clear() => _prefs.remove(key);
}

/// Keeps the snapshot in memory only: for tests, and to show a restart.
class MemorySessionStore implements SessionStore {
  Map<String, dynamic>? _snapshot;

  @override
  Future<Map<String, dynamic>?> load() async =>
      _snapshot == null ? null : jsonDecode(jsonEncode(_snapshot)) as Map<String, dynamic>;

  @override
  Future<void> save(Map<String, dynamic> snapshot) async => _snapshot = jsonDecode(jsonEncode(snapshot));

  @override
  Future<void> clear() async => _snapshot = null;
}
