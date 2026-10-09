import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../practice/practice_session.dart';

class SummaryScreen extends ConsumerWidget {
  const SummaryScreen({super.key, required this.subjectId});
  final String subjectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(lastPracticeResultProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('ملخص الجلسة')),
      body: SafeArea(child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screen),
        child: result == null || result.subjectId != subjectId
          ? Center(child: PrimaryButton(label: 'ارجع لخطتك',
              onPressed: () => context.go(AppRoutes.home)))
          : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Center(child: MentorAvatar(pose: MentorPose.happy, size: 96)),
              const SizedBox(height: AppSpacing.lg),
              Text('هيك خلّصت جلستك!', style: AppText.title, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.xl),
              _Stat(label: 'الإجابات الصحيحة', value: '${result.correct} من ${result.answered}'),
              _Stat(label: 'جاهزيتك', value: '${result.endReadiness}%'),
              _Stat(label: 'التغيّر', value:
                  '${result.endReadiness - result.startReadiness >= 0 ? '+' : ''}'
                  '${result.endReadiness - result.startReadiness}%'),
              const SizedBox(height: AppSpacing.lg),
              Text('المفاهيم اللي تمرّنت عليها', style: AppText.heading),
              const SizedBox(height: AppSpacing.sm),
              Expanded(child: ListView(children: [
                for (final concept in result.updated)
                  ConceptBar.fromMastery(concept),
              ])),
              PrimaryButton(label: 'ارجع لخطتك',
                onPressed: () => context.go(AppRoutes.home)),
            ]),
      )),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
    child: Row(children: [
      Expanded(child: Text(label, style: AppText.label)),
      Text(value, style: AppText.bodyBold),
    ]),
  );
}
