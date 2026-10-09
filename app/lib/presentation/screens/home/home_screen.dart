import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:masar/presentation/state/providers.dart';
import 'package:masar/domain/entities/entities.dart';
import 'package:masar/presentation/navigation/router.dart';
import 'package:masar/presentation/themes/app_theme.dart';
import 'package:masar/presentation/components/widgets.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String? _selectedSubjectId;
  PageController? _pages;
  int _knownCount = 0;

  @override
  void dispose() {
    _pages?.dispose();
    super.dispose();
  }

  /// One controller for the subject deck. When a subject is added, the deck
  /// glides to it, since a new subject is the one the student wants next.
  PageController _deckFor(List<Enrollment> items, int selectedIndex) {
    var created = false;
    final pages = _pages ??= () {
      created = true;
      return PageController(viewportFraction: .84, initialPage: selectedIndex);
    }();
    if (created) {
      // Settle exactly on the selected card once the deck has its size.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (pages.hasClients) pages.jumpToPage(selectedIndex);
      });
    }
    if (_knownCount != 0 && items.length > _knownCount) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (pages.hasClients) {
          pages.animateToPage(
            items.length - 1,
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }
    _knownCount = items.length;
    return pages;
  }

  @override
  Widget build(BuildContext context) {
    final enrollments = ref.watch(enrollmentsProvider);
    final name = ref.watch(profileProvider).value?.displayName ?? '';
    return SafeArea(
      child: AsyncStateView<List<Enrollment>>(
        value: enrollments,
        onRetry: () => ref.invalidate(enrollmentsProvider),
        data: (items) {
          if (items.isEmpty) return _noSubjectYet(name);
          // Default to the newest subject, so a subject just added is the one shown.
          final selected =
              items
                  .where((e) => e.subjectId == _selectedSubjectId)
                  .firstOrNull ??
              items.last;
          return _subjectHome(selected, items, name);
        },
      ),
    );
  }

  /// Straight after sign-up: no subject yet, one clear way forward.
  Widget _noSubjectYet(String name) => ListView(
    padding: const EdgeInsets.all(AppSpacing.screen),
    children: [
      Row(
        children: [
          const MentorAvatar(pose: MentorPose.wave, size: 52),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'أهلاً${name.isEmpty ? '' : ' يا $name'}',
              style: AppText.title,
            ),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.xxl),
      const Center(child: MentorAvatar(pose: MentorPose.pointing, size: 160)),
      const SizedBox(height: AppSpacing.lg),
      Text(
        'خلّينا نبلّش بمادة',
        style: AppText.heading,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: AppSpacing.sm),
      Text(
        'اختار المادة اللي عندك امتحانها، وبنعرف من وين نبلّش بأسئلة تشخيص قصيرة.',
        style: AppText.label,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: AppSpacing.xl),
      ChooseSubjectButton(onPressed: () => context.push(AppRoutes.addSubject)),
    ],
  );

  Widget _subjectHome(
    Enrollment selected,
    List<Enrollment> enrollments,
    String name,
  ) {
    final subjectId = selected.subjectId;
    final plan = selected.diagnosticDone
        ? ref.watch(todayPlanProvider(subjectId))
        : null;
    final subjects = ref.watch(subjectsProvider).value ?? [];
    final subjectNames = {for (final s in subjects) s.id: s.name};
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screen),
      children: [
        Row(
          children: [
            const MentorAvatar(pose: MentorPose.wave, size: 52),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'صباح الخير${name.isEmpty ? '' : ' يا $name'}',
                style: AppText.title,
              ),
            ),
            IconButton(
              onPressed: () => context.go(AppRoutes.profile),
              icon: const Icon(Icons.person_outline),
              tooltip: 'ملفي',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        // Swipe between your subjects; the last card adds another.
        _SubjectDeck(
          controller: _deckFor(enrollments, enrollments.indexOf(selected)),
          enrollments: enrollments,
          subjectNames: subjectNames,
          onSubject: (e) => setState(() => _selectedSubjectId = e.subjectId),
          onAdd: () => context.push(AppRoutes.addSubject),
        ),
        const SizedBox(height: AppSpacing.xl),
        if (!selected.diagnosticDone) ...[
          Text('باقي التشخيص عشان نبني خطتك', style: AppText.heading),
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(
            label: 'ابدأ أسئلة التشخيص',
            onPressed: () => context.go(AppRoutes.diagnostic(subjectId)),
          ),
        ] else ...[
          Row(
            children: [
              Expanded(child: Text('خطة اليوم', style: AppText.heading)),
              TextButton(
                onPressed: () => context.push(AppRoutes.map(subjectId)),
                child: const Text('خريطتك'),
              ),
            ],
          ),
          AsyncStateView<TodayPlan>(
            value: plan!,
            onRetry: () => ref.invalidate(todayPlanProvider(subjectId)),
            data: (today) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${today.minutes} دقيقة · ${today.totalDone} من ${today.totalCount} سؤال',
                  style: AppText.label,
                ),
                const SizedBox(height: AppSpacing.md),
                for (final item in today.items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: ListTile(
                        title: Text(item.conceptName),
                        subtitle: Text(
                          item.isReview
                              ? 'مراجعة'
                              : '${item.done} من ${item.count} أسئلة',
                        ),
                        trailing: Text(
                          '${item.done}/${item.count}',
                          style: AppText.label,
                        ),
                        onTap: () => context.push(
                          AppRoutes.practice(
                            subjectId,
                            conceptId: item.conceptId,
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.md),
                PrimaryButton(
                  label: today.completed ? 'تدرّب زيادة' : 'يلا نبلّش',
                  onPressed: () async {
                    await context.push(
                      AppRoutes.practice(subjectId, mode: 'plan'),
                    );
                    if (mounted) ref.invalidate(todayPlanProvider(subjectId));
                  },
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

/// The big navy call to action on an empty home. Navy in both themes: it's the
/// brand color, and the one thing on the screen to press.
class ChooseSubjectButton extends StatelessWidget {
  const ChooseSubjectButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppPalette.navy,
      elevation: 3,
      shadowColor: AppPalette.navy.withValues(alpha: .4),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.lg + 2,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppPalette.teal,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(Icons.menu_book_rounded, color: Colors.white),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'اختار المادة اللي بدك تختبرها',
                      style: AppText.bodyBold.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'مواد جاهزة بأسئلة امتحانات حقيقية',
                      style: AppText.caption.copyWith(
                        color: Colors.white.withValues(alpha: .8),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The student's subjects as a deck of cards: swipe to move between them. The
/// card in front is full size; its neighbours shrink and fade a little.
class _SubjectDeck extends StatelessWidget {
  const _SubjectDeck({
    required this.controller,
    required this.enrollments,
    required this.subjectNames,
    required this.onSubject,
    required this.onAdd,
  });

  final PageController controller;
  final List<Enrollment> enrollments;
  final Map<String, String> subjectNames;
  final ValueChanged<Enrollment> onSubject;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final count = enrollments.length + 1; // + «أضف مادة»
    return Column(
      children: [
        // Breaks out of the list's side padding so the neighbours peek in from
        // the screen edges instead of being cut at the margin.
        SizedBox(
          height: 196,
          child: OverflowBox(
            maxWidth: MediaQuery.sizeOf(context).width,
            minWidth: MediaQuery.sizeOf(context).width,
            child: PageView.builder(
              controller: controller,
              itemCount: count,
              clipBehavior: Clip.none,
              onPageChanged: (i) {
                HapticFeedback.selectionClick();
                if (i < enrollments.length) onSubject(enrollments[i]);
              },
              itemBuilder: (context, i) => AnimatedBuilder(
                animation: controller,
                builder: (context, child) {
                  var delta = 0.0;
                  if (controller.hasClients &&
                      controller.position.haveDimensions) {
                    delta = ((controller.page ?? 0) - i).abs().clamp(0.0, 1.0);
                  } else {
                    delta = i == controller.initialPage ? 0 : 1;
                  }
                  return Opacity(
                    opacity: 1 - .35 * delta,
                    child: Transform.scale(
                      scale: 1 - .08 * delta,
                      child: child,
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs + 2,
                  ),
                  child: i < enrollments.length
                      ? _SubjectCard(
                          enrollment: enrollments[i],
                          name:
                              subjectNames[enrollments[i].subjectId] ?? 'مادتك',
                        )
                      : _AddSubjectCard(onTap: onAdd),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final page =
                controller.hasClients && controller.position.haveDimensions
                ? controller.page ?? 0
                : controller.initialPage.toDouble();
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < count; i++)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: 8 + 16 * (1 - (page - i).abs().clamp(0.0, 1.0)),
                    height: 8,
                    decoration: BoxDecoration(
                      color: Color.lerp(
                        AppColors.border,
                        AppColors.accent,
                        1 - (page - i).abs().clamp(0.0, 1.0),
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// One subject: its name, days to the exam, and readiness as a ring.
class _SubjectCard extends ConsumerWidget {
  const _SubjectCard({required this.enrollment, required this.name});

  final Enrollment enrollment;
  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressProvider(enrollment.subjectId)).value;
    final readiness = progress?.readiness ?? enrollment.readiness;
    final days = enrollment.daysLeft;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [
            const Color(0xFF2E5A97),
            AppPalette.navy,
            Color.lerp(AppPalette.navy, Colors.black, .3)!,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppPalette.navy.withValues(alpha: .3),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.heading.copyWith(
                    color: Colors.white,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.event_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        days <= 0
                            ? 'الامتحان اليوم'
                            : days == 1
                            ? 'باقي يوم'
                            : 'باقي $days أيام',
                        style: AppText.caption.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  !enrollment.diagnosticDone
                      ? 'ابدأ التشخيص عشان نعرف وين واقف'
                      : 'بتوصل ${progress?.projectedReadiness ?? readiness}% إذا مشيت على الخطة',
                  style: AppText.caption.copyWith(
                    color: Colors.white.withValues(alpha: .8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          _ReadinessRing(value: enrollment.diagnosticDone ? readiness : null),
        ],
      ),
    );
  }
}

/// Readiness as a teal ring that fills up; «؟» before the diagnostic.
class _ReadinessRing extends StatelessWidget {
  const _ReadinessRing({required this.value});

  final int? value;

  @override
  Widget build(BuildContext context) {
    final v = value;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: (v ?? 0) / 100),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) => SizedBox(
        width: 96,
        height: 96,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.expand(
              child: CircularProgressIndicator(
                value: t,
                strokeWidth: 8,
                strokeCap: StrokeCap.round,
                backgroundColor: Colors.white.withValues(alpha: .15),
                color: AppPalette.teal,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  v == null ? '؟' : '${(t * 100).round()}%',
                  style: AppText.title.copyWith(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
                Text(
                  'جاهزيتك',
                  style: AppText.caption.copyWith(
                    color: Colors.white.withValues(alpha: .75),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AddSubjectCard extends StatelessWidget {
  const _AddSubjectCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.accentSoft,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        onTap: onTap,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('أضف مادة', style: AppText.bodyBold),
              Text('جهّز حالك لامتحان ثاني', style: AppText.caption),
            ],
          ),
        ),
      ),
    );
  }
}
