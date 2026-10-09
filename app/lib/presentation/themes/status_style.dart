import 'package:flutter/material.dart';

import 'package:masar/domain/entities/enums.dart';
import 'package:masar/presentation/themes/tokens.dart';

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
