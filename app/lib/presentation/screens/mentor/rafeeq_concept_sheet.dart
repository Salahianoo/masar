import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:masar/domain/entities/entities.dart';
import 'package:masar/presentation/components/widgets.dart';
import 'package:masar/presentation/state/providers.dart';
import 'package:masar/presentation/themes/app_theme.dart';

/// Lists the subject's concepts; resolves with the one the student taps.
Future<Concept?> showRafeeqConceptSheet(BuildContext context, {required String subjectId}) {
  return showModalBottomSheet<Concept>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.75),
      child: _ConceptSheet(subjectId: subjectId),
    ),
  );
}

class _ConceptSheet extends ConsumerWidget {
  const _ConceptSheet({required this.subjectId});

  final String subjectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final concepts = ref.watch(conceptsProvider(subjectId));
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen, 0, AppSpacing.screen, AppSpacing.md),
            child: Text('شو بدك أشرحلك؟', style: AppText.heading),
          ),
          Flexible(
            child: AsyncStateView<List<Concept>>(
              value: concepts,
              onRetry: () => ref.invalidate(conceptsProvider(subjectId)),
              isEmpty: (list) => list.isEmpty,
              emptyMessage: 'ما في مواضيع لهاي المادة لسا',
              data: (list) => ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screen, 0, AppSpacing.screen, AppSpacing.lg),
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, i) {
                  final c = list[i];
                  return Semantics(
                    button: true,
                    label: 'اشرحلي ${c.name}',
                    excludeSemantics: true,
                    child: Material(
                      color: AppColors.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        side: BorderSide(color: AppColors.border),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(c),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: AppSizes.minTapTarget),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                            child: Row(
                              children: [
                                Icon(Icons.lightbulb_outline,
                                    color: AppColors.accent, size: 20),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(child: Text(c.name, style: AppText.body)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
