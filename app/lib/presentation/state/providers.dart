import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:masar/domain/entities/entities.dart';
import 'package:masar/core/di/repository_provider.dart';

export 'package:masar/core/di/repository_provider.dart';

// Shared read providers. After a write (enroll, updateProfile, an answer…)
// call `ref.invalidate(...)` on the ones that changed. `progressProvider` is live.

final configProvider = FutureProvider<AppConfig>(
  (ref) => ref.watch(masarRepositoryProvider).config(),
);

final profileProvider = FutureProvider<UserProfile?>(
  (ref) => ref.watch(masarRepositoryProvider).currentProfile(),
);

final subjectsProvider = FutureProvider<List<Subject>>(
  (ref) => ref.watch(masarRepositoryProvider).subjects(),
);

final enrollmentsProvider = FutureProvider<List<Enrollment>>(
  (ref) => ref.watch(masarRepositoryProvider).enrollments(),
);

final conceptsProvider = FutureProvider.family<List<Concept>, String>(
  (ref, subjectId) => ref.watch(masarRepositoryProvider).concepts(subjectId),
);

final progressProvider = StreamProvider.family<SubjectProgress, String>(
  (ref, subjectId) => ref.watch(masarRepositoryProvider).progress(subjectId),
);

final todayPlanProvider = FutureProvider.family<TodayPlan, String>(
  (ref, subjectId) => ref.watch(masarRepositoryProvider).todayPlan(subjectId),
);

final examsProvider = FutureProvider.family<List<Exam>, String>(
  (ref, subjectId) => ref.watch(masarRepositoryProvider).exams(subjectId),
);

final readinessHistoryProvider = FutureProvider.family<List<ReadinessPoint>, String>(
  (ref, subjectId) => ref.watch(masarRepositoryProvider).readinessHistory(subjectId),
);
