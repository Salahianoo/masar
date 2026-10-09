import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';

// TODO(amer): step 3 builds the 8-question diagnostic here.
class DiagnosticScreen extends StatelessWidget {
  const DiagnosticScreen({super.key, required this.subjectId});

  final String subjectId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screen),
          child: Column(
            children: [
              Expanded(
                child: PlaceholderScreen(
                  title: 'التشخيص',
                  details: 'subjectId=$subjectId',
                  showAppBar: false,
                ),
              ),
              PrimaryButton(label: 'للرئيسية', onPressed: () => context.go(AppRoutes.home)),
            ],
          ),
        ),
      ),
    );
  }
}
