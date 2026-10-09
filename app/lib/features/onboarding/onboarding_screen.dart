import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/mock_data.dart';
import '../../core/data/providers.dart';
import '../../core/router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';

// TODO(amer): step 2 replaces this with the real welcome → name → subjects flow.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  bool _busy = false;

  /// MOCK only: a test student enrolled in the sample subject, exam in 7 days.
  Future<void> _quickStart() async {
    setState(() => _busy = true);
    try {
      final repo = ref.read(masarRepositoryProvider);
      await repo.updateProfile('طالب تجريبي');
      await repo.enroll(mockSubjectId, DateTime.now().add(const Duration(days: 7)));
      ref.invalidate(profileProvider);
      ref.invalidate(enrollmentsProvider);
      if (mounted) context.go(AppRoutes.diagnostic(mockSubjectId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyError(e))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screen),
          child: Column(
            children: [
              const Expanded(child: PlaceholderScreen(title: 'التسجيل', showAppBar: false)),
              if (kUseMock)
                PrimaryButton(label: 'بداية سريعة (تجربة)', loading: _busy, onPressed: _quickStart),
            ],
          ),
        ),
      ),
    );
  }
}
