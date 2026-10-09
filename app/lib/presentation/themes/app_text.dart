import 'package:flutter/material.dart';

import 'package:masar/presentation/themes/tokens.dart';

/// Text styles, all in Tajawal (bundled in assets/fonts, so it never waits on
/// the network). Each weight has one job, so the hierarchy reads at a glance:
///
/// - Black 900: the big numbers (readiness, scores). One per screen.
/// - ExtraBold 800: screen titles, greetings, buttons.
/// - Bold 700: section headings and emphasis inside text.
/// - Medium 500: everything you read. Tajawal's Regular is thin on phone
///   screens, so running text sits one step heavier.
/// - Regular 400: small secondary captions only.
///
/// Arabic in Tajawal has tall ascenders and deep descenders, so headings get a
/// little more line height than Latin would need and body text more still.
abstract final class AppText {
  static const family = 'Tajawal';

  static TextStyle _base(double size, FontWeight weight, Color color,
          {double height = 1.45, double spacing = 0}) =>
      TextStyle(
        fontFamily: family,
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: spacing,
      );

  /// The family name for ThemeData, so Material widgets use the brand font too.
  static String get fontFamily => family;

  /// The big readiness number.
  static TextStyle get display =>
      _base(46, FontWeight.w900, AppColors.textPrimary, height: 1.05, spacing: -.5);
  static TextStyle get title => _base(23, FontWeight.w800, AppColors.textPrimary, height: 1.3);
  static TextStyle get heading => _base(19, FontWeight.w700, AppColors.textPrimary, height: 1.35);
  static TextStyle get body => _base(16, FontWeight.w500, AppColors.textPrimary, height: 1.6);
  static TextStyle get bodyBold => _base(16, FontWeight.w700, AppColors.textPrimary, height: 1.5);
  static TextStyle get label => _base(14, FontWeight.w500, AppColors.textSecondary);
  static TextStyle get caption => _base(13.5, FontWeight.w400, AppColors.textSecondary);
  static TextStyle get button => _base(17, FontWeight.w800, AppColors.onPrimary, height: 1.2);
}
