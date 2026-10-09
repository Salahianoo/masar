// TEMPORARY: stand-ins for Amer's core/theme tokens. Delete when core lands.
// Status colors per CONTRACT §7: unknown = gray, weak = red, medium = amber, strong = green.
import 'package:flutter/material.dart';

import 'models.dart';

extension MasteryStatusX on MasteryStatus {
  Color get color => switch (this) {
        MasteryStatus.unknown => const Color(0xFF9E9E9E),
        MasteryStatus.weak => const Color(0xFFE04848),
        MasteryStatus.medium => const Color(0xFFF0A030),
        MasteryStatus.strong => const Color(0xFF5E9B2C),
      };

  String get labelAr => switch (this) {
        MasteryStatus.unknown => 'غير مختبر',
        MasteryStatus.weak => 'ضعيف',
        MasteryStatus.medium => 'متوسط',
        MasteryStatus.strong => 'قوي',
      };
}

abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
}

abstract final class AppRadius {
  static const double md = 12;
  static const double lg = 16;
  static const double pill = 999;
}
