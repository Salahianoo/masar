import 'package:flutter/material.dart';

import 'package:masar/presentation/themes/app_text.dart';
import 'package:masar/presentation/themes/tokens.dart';

export 'package:masar/presentation/themes/app_text.dart';
export 'package:masar/presentation/themes/status_style.dart';
export 'package:masar/presentation/themes/tokens.dart';

abstract final class AppTheme {
  static ThemeData light() => _build(AppPalette.light);
  static ThemeData dark() => _build(AppPalette.dark);

  static ThemeData _build(AppPalette p) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppPalette.navy,
      brightness: p.brightness,
      primary: p.primary,
      onPrimary: p.onPrimary,
      secondary: p.accent,
      surface: p.surface,
      onSurface: p.textPrimary,
      error: p.error,
      outline: p.border,
      outlineVariant: p.border,
    );
    final base = ThemeData(
      useMaterial3: true,
      brightness: p.brightness,
      colorScheme: scheme,
      fontFamily: AppText.fontFamily,
    );
    final roundedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide(color: p.border),
    );
    final cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      side: BorderSide(color: p.border),
    );
    TextStyle text(double size, FontWeight weight, Color color) =>
        TextStyle(fontFamily: AppText.fontFamily, fontSize: size, fontWeight: weight, color: color);

    return base.copyWith(
      scaffoldBackgroundColor: p.background,
      canvasColor: p.background,
      dividerColor: p.border,
      // Material's defaults are Regular (400), which Tajawal renders thin; lift
      // reading text to Medium and titles to Bold, same as AppText.
      textTheme: base.textTheme
          .copyWith(
            bodyLarge: base.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500, height: 1.5),
            bodyMedium: base.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500, height: 1.5),
            titleMedium: base.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            titleSmall: base.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            labelLarge: base.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
            labelMedium: base.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500),
          )
          .apply(bodyColor: p.textPrimary, displayColor: p.textPrimary),
      iconTheme: IconThemeData(color: p.textSecondary),
      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        foregroundColor: p.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text(18, FontWeight.w700, p.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        shape: cardShape,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: p.accent,
        textColor: p.textPrimary,
        titleTextStyle: text(16, FontWeight.w700, p.textPrimary),
        subtitleTextStyle: text(13.5, FontWeight.w500, p.textSecondary),
        minVerticalPadding: AppSpacing.md,
      ),
      dividerTheme: DividerThemeData(color: p.border, thickness: 1, space: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surface,
        hintStyle: text(14, FontWeight.w500, p.textMuted),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: roundedBorder,
        enabledBorder: roundedBorder,
        focusedBorder: roundedBorder.copyWith(
          borderSide: BorderSide(color: p.accent, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: p.onPrimary,
          minimumSize: const Size(64, AppSizes.minTapTarget),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.brightness == Brightness.dark ? p.brand : p.primary,
          minimumSize: const Size(64, AppSizes.minTapTarget),
          side: BorderSide(color: p.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.brightness == Brightness.dark ? p.brand : p.primary,
          minimumSize: const Size(48, AppSizes.minTapTarget),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: p.surface,
          foregroundColor: p.textSecondary,
          selectedBackgroundColor: p.accentSoft,
          selectedForegroundColor: p.textPrimary,
          side: BorderSide(color: p.border),
          minimumSize: const Size(48, AppSizes.minTapTarget),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.surface,
        selectedColor: p.accentSoft,
        checkmarkColor: p.textPrimary,
        side: BorderSide(color: p.border),
        labelStyle: text(14, FontWeight.w500, p.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: p.accent, linearTrackColor: p.track),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: p.accentSoft,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => text(
            13,
            states.contains(WidgetState.selected) ? FontWeight.w800 : FontWeight.w500,
            states.contains(WidgetState.selected) ? p.brand : p.textMuted,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? p.brand : p.textMuted,
          ),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: p.border,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: p.brightness == Brightness.dark ? p.surfaceMuted : AppPalette.navy,
        contentTextStyle: text(16, FontWeight.w500, Colors.white),
      ),
    );
  }
}
