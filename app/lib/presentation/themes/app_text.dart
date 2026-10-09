import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:masar/presentation/themes/tokens.dart';

/// Text styles. One font family token so the brand font can be swapped in one line.
abstract final class AppText {
  static TextStyle _base(double size, FontWeight weight, Color color, {double height = 1.4}) =>
      GoogleFonts.ibmPlexSansArabic(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
      );

  /// The family name for ThemeData, so Material widgets use the brand font too.
  static String? get fontFamily => GoogleFonts.ibmPlexSansArabic().fontFamily;

  /// The big readiness number.
  static TextStyle get display => _base(44, FontWeight.w700, AppColors.textPrimary, height: 1.1);
  static TextStyle get title => _base(22, FontWeight.w700, AppColors.textPrimary);
  static TextStyle get heading => _base(18, FontWeight.w700, AppColors.textPrimary);
  static TextStyle get body => _base(16, FontWeight.w500, AppColors.textPrimary);
  static TextStyle get bodyBold => _base(16, FontWeight.w700, AppColors.textPrimary);
  static TextStyle get label => _base(14, FontWeight.w500, AppColors.textSecondary);
  static TextStyle get caption => _base(13, FontWeight.w400, AppColors.textSecondary);
  static TextStyle get button => _base(17, FontWeight.w700, AppColors.onPrimary);
}
