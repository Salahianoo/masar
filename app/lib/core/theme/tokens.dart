import 'package:flutter/material.dart';

// Every brand value lives here. The brand isn't final: change a token, not a screen.

abstract final class AppColors {
  // Brand
  static const primary = Color(0xFF1E5AA8);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primarySoft = Color(0xFFE8F0FB); // selected option fill

  // Surfaces
  static const background = Color(0xFFFFFFFF);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFF2EFEA); // cards like the readiness box
  static const border = Color(0xFFE4E1DB);
  static const track = Color(0xFFEFECE6); // progress bar background

  // Text
  static const textPrimary = Color(0xFF1C1B1A);
  static const textSecondary = Color(0xFF6E6B66);
  static const textMuted = Color(0xFF9A968F);

  // Mastery status (CONTRACT §7): unknown gray, weak red, medium amber, strong green
  static const statusUnknown = Color(0xFFB9B5AE);
  static const statusWeak = Color(0xFFE04848);
  static const statusMedium = Color(0xFFF0A12C);
  static const statusStrong = Color(0xFF5E9B2A);

  // Feedback
  static const success = statusStrong;
  static const successSoft = Color(0xFFEEF6E4);
  static const error = Color(0xFFC62828);
  static const errorSoft = Color(0xFFFCEBEB);
  static const warning = Color(0xFFB3261E); // «بيجي بـ 18% من الامتحانات»

  // Mentor placeholder (until the 3D images land in assets/mentor/)
  static const mentor = Color(0xFF6B5BD6);
  static const mentorSoft = Color(0xFFECE9FB);
}

abstract final class AppSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const xxl = 32.0;

  /// Side padding of every screen.
  static const screen = 20.0;
}

abstract final class AppRadii {
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
