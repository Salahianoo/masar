// Compatibility barrel for the practice feature while its imports are consolidated.
// All screens now share the app's repository, models, theme and widgets.
export 'package:masar/domain/repositories/masar_repository.dart';
export 'package:masar/core/di/repository_provider.dart';
export 'package:masar/domain/entities/entities.dart';
export 'package:masar/presentation/themes/tokens.dart' show AppSpacing, AppRadius;
export 'package:masar/presentation/themes/status_style.dart';
export 'package:masar/presentation/components/widgets.dart'
    show AsyncStateView, MentorAvatar, MentorPose, PrimaryButton;
