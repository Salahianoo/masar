import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Light, dark or follow the phone. Remembered on the device.
final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);

class ThemeModeController extends Notifier<ThemeMode> {
  static const _key = 'masar.themeMode';

  @override
  ThemeMode build() {
    _load();
    return ThemeMode.system;
  }

  Future<void> _load() async {
    try {
      final saved = await SharedPreferencesAsync().getString(_key);
      final mode = ThemeMode.values.where((m) => m.name == saved).firstOrNull;
      if (mode != null) state = mode;
    } catch (_) {
      // no storage (tests, first run): keep following the phone
    }
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    try {
      await SharedPreferencesAsync().setString(_key, mode.name);
    } catch (_) {
      // the choice still applies for this session
    }
  }
}
