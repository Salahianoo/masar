import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:masar/domain/entities/entities.dart';
import 'package:masar/presentation/screens/profile/profile_stats.dart';
import 'package:masar/presentation/state/providers.dart';
import 'package:masar/presentation/state/theme_mode_provider.dart';
import 'package:masar/presentation/themes/app_theme.dart';

/// A section heading on the profile.
class ProfileSectionTitle extends StatelessWidget {
  const ProfileSectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.md),
        child: Text(text, style: AppText.heading),
      );
}

/// The student's card: initial, name, subject count, edit name.
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.name,
    required this.subjectCount,
    required this.onEditName,
  });

  final String name;
  final int subjectCount;
  final VoidCallback onEditName;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '؟' : name.trim().characters.first;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [AppPalette.navy, Color.lerp(AppPalette.navy, Colors.black, .35)!],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppPalette.teal,
              border: Border.all(color: Colors.white.withValues(alpha: .7), width: 2),
            ),
            child: Text(initial,
                style: AppText.title.copyWith(color: Colors.white, fontSize: 28)),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppText.title.copyWith(color: Colors.white),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subjectCount == 0
                      ? 'طالب مسار'
                      : 'طالب مسار · ${_subjectsLabel(subjectCount)}',
                  style: AppText.label.copyWith(color: Colors.white.withValues(alpha: .8)),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'غيّر اسمك',
            onPressed: onEditName,
            icon: const Icon(Icons.edit_outlined, color: Colors.white),
          ),
        ],
      ),
    );
  }

  static String _subjectsLabel(int n) => switch (n) {
        1 => 'مادة وحدة',
        2 => 'مادتين',
        <= 10 => '$n مواد',
        _ => '$n مادة',
      };
}

/// The four headline numbers, two per row.
class ProfileStatGrid extends StatelessWidget {
  const ProfileStatGrid({super.key, required this.stats});

  final ProfileStats stats;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _StatTile(
        icon: Icons.speed_rounded,
        value: stats.averageReadiness == null ? '—' : '${stats.averageReadiness}%',
        label: 'متوسط جاهزيتك',
      ),
      _StatTile(
        icon: Icons.verified_outlined,
        value: '${stats.strongCount}/${stats.conceptCount}',
        label: 'مفاهيم قوية',
      ),
      _StatTile(
        icon: Icons.check_circle_outline,
        value: '${stats.answers}',
        label: 'إجابات لحد هلق',
      ),
      _StatTile(
        icon: Icons.event_outlined,
        value: stats.nearestExamDays == null
            ? '—'
            : stats.nearestExamDays == 0
                ? 'اليوم'
                : '${stats.nearestExamDays} يوم',
        label: 'لأقرب امتحان',
        numeric: false,
      ),
    ];
    return Column(
      children: [
        for (var row = 0; row < tiles.length; row += 2) ...[
          if (row > 0) const SizedBox(height: AppSpacing.md),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: tiles[row]),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: tiles[row + 1]),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
    this.numeric = true,
  });

  final IconData icon;
  final String value;
  final String label;

  /// Pure figures ("25%", "3/8") read left to right; words ("9 يوم") stay RTL.
  final bool numeric;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.accent, size: 22),
            const SizedBox(height: AppSpacing.sm),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(value,
                  style: AppText.title.copyWith(color: AppColors.brand),
                  textDirection: numeric ? TextDirection.ltr : null),
            ),
            Text(label, style: AppText.caption),
          ],
        ),
      ),
    );
  }
}

/// Where the student's concepts sit: one stacked bar in status colors, with a
/// labelled legend (status is never told by color alone).
class MasteryBreakdown extends StatelessWidget {
  const MasteryBreakdown({super.key, required this.counts});

  final Map<MasteryStatus, int> counts;

  static const _order = [
    MasteryStatus.strong,
    MasteryStatus.medium,
    MasteryStatus.weak,
    MasteryStatus.unknown,
  ];

  @override
  Widget build(BuildContext context) {
    final total = counts.values.fold(0, (a, b) => a + b);
    if (total == 0) {
      return Text('خلّص التشخيص وبتبين هون خريطة مفاهيمك.', style: AppText.label);
    }
    final present = [for (final s in _order) if ((counts[s] ?? 0) > 0) s];
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            label: [for (final s in present) '${s.labelAr} ${counts[s]}'].join('، '),
            excludeSemantics: true,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: SizedBox(
                height: 14,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < present.length; i++) ...[
                      // a 2px surface gap between segments
                      if (i > 0) SizedBox(width: 2, child: ColoredBox(color: AppColors.surface)),
                      Expanded(
                        flex: counts[present[i]]!,
                        child: ColoredBox(color: present[i].color),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.sm,
            children: [
              for (final s in _order)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(color: s.color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text('${s.labelAr} ${counts[s] ?? 0}', style: AppText.caption),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One enrolled subject: readiness, exam date (editable) and its readiness over time.
class SubjectProgressCard extends ConsumerWidget {
  const SubjectProgressCard({
    super.key,
    required this.enrollment,
    required this.subjectName,
    required this.onOpen,
    required this.onEditDate,
  });

  final Enrollment enrollment;
  final String subjectName;
  final VoidCallback onOpen;
  final VoidCallback onEditDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readiness = ref.watch(progressProvider(enrollment.subjectId)).value?.readiness ??
        enrollment.readiness;
    final history = ref.watch(readinessHistoryProvider(enrollment.subjectId));
    final d = enrollment.examDate;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onOpen,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: Text(subjectName, style: AppText.bodyBold,
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: AppColors.accentSoft,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      enrollment.diagnosticDone ? '$readiness%' : 'لسا ما شخّصت',
                      style: AppText.label.copyWith(color: AppColors.textPrimary),
                    ),
                  ),
                  Icon(Icons.chevron_right, color: AppColors.textMuted),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text('جاهزيتك مع الوقت', style: AppText.caption),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
            child: SizedBox(
              height: 96,
              child: switch (history.value) {
                final points? when points.length >= 2 => ReadinessLine(points: points),
                _ => Center(
                    child: Text('الرسم بيبين بعد يومين تمرين', style: AppText.caption),
                  ),
              },
            ),
          ),
          Divider(height: 1, color: AppColors.border),
          InkWell(
            onTap: onEditDate,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppRadius.lg)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: AppSizes.minTapTarget),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Row(
                  children: [
                    Icon(Icons.event_outlined, size: 18, color: AppColors.accent),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'الامتحان ${d.day}/${d.month}/${d.year} · باقي ${enrollment.daysLeft} يوم',
                        style: AppText.label,
                      ),
                    ),
                    Text('غيّر', style: AppText.label.copyWith(color: AppColors.brand)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Readiness per active day: one teal line, 0–100, tap a point for its value.
class ReadinessLine extends StatelessWidget {
  const ReadinessLine({super.key, required this.points});

  final List<ReadinessPoint> points;

  @override
  Widget build(BuildContext context) {
    final spots = [
      for (var i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), points[i].readiness.toDouble()),
    ];
    return Directionality(
      // time runs left to right on a chart, even in an RTL app
      textDirection: TextDirection.ltr,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 100,
          gridData: FlGridData(
            drawVerticalLine: false,
            horizontalInterval: 50,
            getDrawingHorizontalLine: (_) => FlLine(color: AppColors.border, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: const FlTitlesData(show: false),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => AppColors.surfaceMuted,
              getTooltipItems: (touched) => [
                for (final t in touched)
                  LineTooltipItem(
                    '${points[t.x.toInt()].day.day}/${points[t.x.toInt()].day.month}\n'
                    '${t.y.toInt()}%',
                    AppText.caption.copyWith(color: AppColors.textPrimary),
                  ),
              ],
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              preventCurveOverShooting: true,
              color: AppColors.accent,
              barWidth: 2,
              dotData: FlDotData(
                checkToShowDot: (spot, _) => spot.x == spots.last.x,
                getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                  radius: 4,
                  color: AppColors.accent,
                  strokeWidth: 2,
                  strokeColor: AppColors.surface,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.accent.withValues(alpha: .12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Light, dark, or follow the phone.
class AppearanceSetting extends ConsumerWidget {
  const AppearanceSetting({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<ThemeMode>(
        showSelectedIcon: false,
        segments: const [
          ButtonSegment(
            value: ThemeMode.light,
            icon: Icon(Icons.light_mode_outlined),
            label: Text('فاتح'),
          ),
          ButtonSegment(
            value: ThemeMode.dark,
            icon: Icon(Icons.dark_mode_outlined),
            label: Text('داكن'),
          ),
          ButtonSegment(
            value: ThemeMode.system,
            icon: Icon(Icons.brightness_auto_outlined),
            label: Text('تلقائي'),
          ),
        ],
        selected: {mode},
        onSelectionChanged: (s) => ref.read(themeModeProvider.notifier).set(s.first),
      ),
    );
  }
}

/// A settings row: icon, title, optional subtitle, tappable.
class ProfileTile extends StatelessWidget {
  const ProfileTile({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.onTap,
    this.color,
  });

  final Widget leading;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  /// Title color, e.g. the error color for «تسجيل خروج».
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        leading: leading,
        title: Text(title, style: AppText.body.copyWith(color: color)),
        subtitle: subtitle == null ? null : Text(subtitle!, style: AppText.caption),
        trailing: onTap == null ? null : Icon(Icons.chevron_right, color: AppColors.textMuted),
      ),
    );
  }
}
