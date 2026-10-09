import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'data/providers.dart';
import 'routes.dart';
import 'widgets/widgets.dart';

/// Anonymous sign-in, then: no profile or no enrollment → onboarding, else home.
final startRouteProvider = FutureProvider<String>((ref) async {
  final repo = ref.read(masarRepositoryProvider);
  await repo.signIn();
  final profile = await repo.currentProfile();
  if (profile == null || profile.displayName.isEmpty) return AppRoutes.onboarding;
  final enrollments = await repo.enrollments();
  return enrollments.isEmpty ? AppRoutes.onboarding : AppRoutes.home;
});

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final start = ref.watch(startRouteProvider);
    return Scaffold(
      body: SafeArea(
        child: AsyncStateView<String>(
          value: start,
          onRetry: () => ref.invalidate(startRouteProvider),
          builder: (context, route) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) context.go(route);
            });
            return const LoadingView();
          },
        ),
      ),
    );
  }
}
