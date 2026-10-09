import 'package:flutter/material.dart';

import '../models/enums.dart';
import 'tokens.dart';

extension MasteryStatusStyle on MasteryStatus {
  Color get color => switch (this) {
        MasteryStatus.unknown => AppColors.statusUnknown,
        MasteryStatus.weak => AppColors.statusWeak,
        MasteryStatus.medium => AppColors.statusMedium,
        MasteryStatus.strong => AppColors.statusStrong,
      };

  String get labelAr => switch (this) {
        MasteryStatus.unknown => 'غير مختبر',
        MasteryStatus.weak => 'ضعيف',
        MasteryStatus.medium => 'متوسط',
        MasteryStatus.strong => 'قوي',
      };
}
