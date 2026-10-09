import 'package:flutter/material.dart';

// Every brand value lives here. Change a token, not a screen.
// Brand: navy #24477B, teal #44BFB7 (design/README.md).

/// One full set of colors. The app has a light and a dark one.
class AppPalette {
  const AppPalette({
    required this.brightness,
    required this.primary,
    required this.onPrimary,
    required this.primarySoft,
    required this.brand,
    required this.accent,
    required this.accentSoft,
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.border,
    required this.track,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.statusUnknown,
    required this.statusWeak,
    required this.statusMedium,
    required this.statusStrong,
    required this.successSoft,
    required this.error,
    required this.errorSoft,
    required this.warning,
  });

  final Brightness brightness;

  /// Buttons, selected states, links.
  final Color primary;
  final Color onPrimary;

  /// Selected option fill, the user's chat bubble.
  final Color primarySoft;

  /// Navy for brand headings; a light navy on dark backgrounds.
  final Color brand;

  /// Teal: icons, highlights, رفيق.
  final Color accent;
  final Color accentSoft;

  final Color background;
  final Color surface;

  /// Cards like the readiness box.
  final Color surfaceMuted;
  final Color border;

  /// Progress bar background.
  final Color track;

  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  // Mastery status (CONTRACT §7): unknown gray, weak red, medium amber, strong green
  final Color statusUnknown;
  final Color statusWeak;
  final Color statusMedium;
  final Color statusStrong;

  final Color successSoft;
  final Color error;
  final Color errorSoft;

  /// «بيجي بـ 18% من الامتحانات»
  final Color warning;

  static const navy = Color(0xFF24477B);
  static const teal = Color(0xFF44BFB7);

  static const light = AppPalette(
    brightness: Brightness.light,
    primary: navy,
    onPrimary: Color(0xFFFFFFFF),
    primarySoft: Color(0xFFE6EDF7),
    brand: navy,
    accent: teal,
    accentSoft: Color(0xFFE2F5F3),
    background: Color(0xFFF6F8FB),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFEEF2F7),
    border: Color(0xFFDDE3EC),
    track: Color(0xFFE6EBF2),
    textPrimary: Color(0xFF15223A),
    textSecondary: Color(0xFF586579),
    textMuted: Color(0xFF8A94A4),
    statusUnknown: Color(0xFFB3BAC5),
    statusWeak: Color(0xFFE04848),
    statusMedium: Color(0xFFF0A12C),
    statusStrong: Color(0xFF4E9A3A),
    successSoft: Color(0xFFE9F5E4),
    error: Color(0xFFC62828),
    errorSoft: Color(0xFFFCEBEB),
    warning: Color(0xFFB3261E),
  );

  static const dark = AppPalette(
    brightness: Brightness.dark,
    primary: Color(0xFF3F72BD),
    onPrimary: Color(0xFFFFFFFF),
    primarySoft: Color(0xFF1D3150),
    brand: Color(0xFF9DBDEB),
    accent: teal,
    accentSoft: Color(0xFF123A3B),
    background: Color(0xFF0C1320),
    surface: Color(0xFF152034),
    surfaceMuted: Color(0xFF1B2940),
    border: Color(0xFF2A3A52),
    track: Color(0xFF243450),
    textPrimary: Color(0xFFE8EEF7),
    textSecondary: Color(0xFFA7B3C6),
    textMuted: Color(0xFF76839A),
    statusUnknown: Color(0xFF66738A),
    statusWeak: Color(0xFFF06A6A),
    statusMedium: Color(0xFFF4B04A),
    statusStrong: Color(0xFF7CBF52),
    successSoft: Color(0xFF1C3322),
    error: Color(0xFFFF7070),
    errorSoft: Color(0xFF3A1E24),
    warning: Color(0xFFFF8A80),
  );
}

/// The active palette's colors. [AppPalette] switches with light/dark mode
/// (main.dart calls [use]), so read these at build time, never in a `const`.
abstract final class AppColors {
  static AppPalette _p = AppPalette.light;

  static AppPalette get palette => _p;

  /// Returns true when the palette actually changed.
  static bool use(Brightness brightness) {
    final next = brightness == Brightness.dark ? AppPalette.dark : AppPalette.light;
    if (identical(next, _p)) return false;
    _p = next;
    return true;
  }

  static Color get primary => _p.primary;
  static Color get onPrimary => _p.onPrimary;
  static Color get primarySoft => _p.primarySoft;
  static Color get brand => _p.brand;
  static Color get accent => _p.accent;
  static Color get accentSoft => _p.accentSoft;

  static Color get background => _p.background;
  static Color get surface => _p.surface;
  static Color get surfaceMuted => _p.surfaceMuted;
  static Color get border => _p.border;
  static Color get track => _p.track;

  static Color get textPrimary => _p.textPrimary;
  static Color get textSecondary => _p.textSecondary;
  static Color get textMuted => _p.textMuted;

  static Color get statusUnknown => _p.statusUnknown;
  static Color get statusWeak => _p.statusWeak;
  static Color get statusMedium => _p.statusMedium;
  static Color get statusStrong => _p.statusStrong;

  static Color get success => _p.statusStrong;
  static Color get successSoft => _p.successSoft;
  static Color get error => _p.error;
  static Color get errorSoft => _p.errorSoft;
  static Color get warning => _p.warning;

  /// رفيق's colors.
  static Color get mentor => _p.accent;
  static Color get mentorSoft => _p.accentSoft;
}

abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;

  /// Side padding of every screen.
  static const screen = 20.0;
}

abstract final class AppRadius {
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const pill = 999.0;
}

abstract final class AppSizes {
  static const buttonHeight = 56.0;
  static const minTapTarget = 48.0;
  static const barHeight = 8.0;
  static const optionMinHeight = 56.0;
  static const mentorAvatar = 48.0;
}

abstract final class AppDurations {
  static const fast = Duration(milliseconds: 200);
  static const medium = Duration(milliseconds: 300);
  static const slow = Duration(milliseconds: 800);
}
