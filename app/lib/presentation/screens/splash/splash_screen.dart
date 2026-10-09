import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:masar/presentation/state/providers.dart';
import 'package:masar/core/di/repository_provider.dart';
import 'package:masar/presentation/navigation/routes.dart';
import 'package:masar/presentation/components/masar_splash_animation.dart';
import 'package:masar/presentation/components/widgets.dart';

/// Existing Firebase account → profile route; new students → Google sign-in.
final startRouteProvider = FutureProvider<String>((ref) async {
  final google = ref.read(googleAccountServiceProvider);
  if (google != null && !google.hasSession) return AppRoutes.signIn;
  final repo = ref.read(masarRepositoryProvider);
  await repo.signIn();
  final profile = await repo.currentProfile();
  if (profile == null || profile.displayName.isEmpty) return AppRoutes.onboarding;
  final enrollments = await repo.enrollments();
  return enrollments.isEmpty ? AppRoutes.onboarding : AppRoutes.home;
});

/// Plays the launch animation while sign-in runs underneath, and leaves once
/// both are done — the animation never makes the launch slower than sign-in,
/// and a slow sign-in shows a loader under the finished icon.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key, this.playSound = true});

  final bool playSound;

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _animationDone = false;
  bool _left = false;

  void _leaveIfReady(AsyncValue<String> start) {
    if (_left || !_animationDone) return;
    final route = start.value;
    if (route == null) return;
    _left = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.go(route);
    });
  }

  @override
  Widget build(BuildContext context) {
    final start = ref.watch(startRouteProvider);
    _leaveIfReady(start);
    return Scaffold(
      body: DecoratedBox(
        // Starts from the native launch screen's flat #24477B, so the hand-off
        // from the OS splash to this one doesn't flash.
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-.4, -.6),
            radius: 1.3,
            colors: [Color(0xFF2E5A97), Color(0xFF24477B), Color(0xFF1B3866)],
            stops: [0, .45, 1],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MasarSplashAnimation(
                  playSound: widget.playSound,
                  onFinished: () {
                    setState(() => _animationDone = true);
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 120,
                  child: !_animationDone
                      ? null
                      : start.when(
                          data: (_) => const SizedBox.shrink(),
                          loading: () => const Center(
                            child: CircularProgressIndicator(color: Colors.white70, strokeWidth: 2),
                          ),
                          error: (_, _) => Theme(
                            data: Theme.of(context).copyWith(
                              textTheme: Theme.of(context).textTheme.apply(
                                    bodyColor: Colors.white,
                                    displayColor: Colors.white,
                                  ),
                            ),
                            child: AsyncStateView<String>(
                              value: start,
                              onRetry: () => ref.invalidate(startRouteProvider),
                              data: (_) => const SizedBox.shrink(),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
