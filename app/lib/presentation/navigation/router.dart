import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:masar/presentation/screens/diagnostic/diagnostic_screen.dart';
import 'package:masar/presentation/screens/home/home_screen.dart';
import 'package:masar/presentation/screens/intro/intro_screen.dart';
import 'package:masar/presentation/screens/map/map_screen.dart';
import 'package:masar/presentation/screens/khazna/khazna_screen.dart';
import 'package:masar/presentation/screens/onboarding/onboarding_screen.dart';
import 'package:masar/presentation/screens/profile/profile_screen.dart';
import 'package:masar/presentation/screens/profile/rating_explainer_screen.dart';
import 'package:masar/presentation/screens/practice/practice_screen.dart';
import 'package:masar/presentation/screens/subjects/add_subject_screen.dart';
import 'package:masar/presentation/screens/summary/summary_screen.dart';
import 'package:masar/presentation/navigation/app_shell.dart';
import 'package:masar/presentation/navigation/routes.dart';
import 'package:masar/presentation/screens/splash/splash_screen.dart';

export 'package:masar/presentation/navigation/routes.dart';

/// Every screen slides a little and fades in; the one it covers fades back.
/// Reduced motion (an OS setting) turns it into a plain cut.
CustomTransitionPage<void> _animated(GoRouterState state, Widget child) => CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 380),
      reverseTransitionDuration: const Duration(milliseconds: 280),
      transitionsBuilder: (context, animation, secondary, child) {
        if (MediaQuery.disableAnimationsOf(context)) return child;
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic);
        // RTL: a new page comes in from the left, the reading direction's "forward".
        final dx = Directionality.of(context) == TextDirection.rtl ? -0.12 : 0.12;
        return FadeTransition(
          opacity: Tween<double>(begin: 1, end: .6).animate(secondary),
          child: FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween(begin: Offset(dx, 0), end: Offset.zero).animate(curved),
              child: child,
            ),
          ),
        );
      },
    );

/// A soft cross-fade, for screens that aren't a step forward.
CustomTransitionPage<void> _fade(GoRouterState state, Widget child) => CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 220),
      transitionsBuilder: (context, animation, secondary, child) =>
          FadeTransition(opacity: animation, child: child),
    );

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (context, state) => const SplashScreen()),
      GoRoute(path: AppRoutes.intro, pageBuilder: (context, state) => _fade(state, const IntroScreen())),
      GoRoute(path: AppRoutes.onboarding,
          pageBuilder: (context, state) => _animated(state, const OnboardingScreen())),
      GoRoute(path: AppRoutes.howRating,
          pageBuilder: (context, state) => _animated(state, const RatingExplainerScreen())),
      GoRoute(path: AppRoutes.addSubject,
          pageBuilder: (context, state) => _animated(state, const AddSubjectScreen())),
      GoRoute(
        path: '/diagnostic/:subjectId',
        pageBuilder: (context, state) =>
            _animated(state, DiagnosticScreen(subjectId: state.pathParameters['subjectId']!)),
      ),
      GoRoute(
        path: '/map/:subjectId',
        pageBuilder: (context, state) =>
            _animated(state, MapScreen(subjectId: state.pathParameters['subjectId']!)),
      ),

      // Practice shares the same repository as the rest of the app.
      GoRoute(
        path: '/practice/:subjectId',
        pageBuilder: (context, state) => _animated(state, PracticeScreen.fromState(state)),
      ),
      GoRoute(path: '/summary/:subjectId', pageBuilder: (context, state) =>
        _animated(state, SummaryScreen(subjectId: state.pathParameters['subjectId']!))),
      GoRoute(
        path: '/khazna/exam/:examId',
        pageBuilder: (context, state) =>
            _animated(state, KhaznaExamScreen(examId: state.pathParameters['examId']!)),
      ),
      // ── the 3 tabs ──
      StatefulShellRoute(
        pageBuilder: (context, state, navigationShell) => CustomTransitionPage<void>(
          child: navigationShell,
          transitionDuration: const Duration(milliseconds: 380),
          transitionsBuilder: (context, animation, secondary, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
        // The tabs live in a swipeable pager instead of a plain stack.
        navigatorContainerBuilder: (context, navigationShell, children) =>
            AppShell(navigationShell: navigationShell, children: children),
        branches: [
          StatefulShellBranch(preload: true, routes: [
            GoRoute(path: AppRoutes.home, builder: (context, state) => const HomeScreen()),
          ]),
          StatefulShellBranch(preload: true, routes: [
            GoRoute(path: AppRoutes.khazna,
              builder: (context, state) => const KhaznaScreen()),
          ]),
          StatefulShellBranch(preload: true, routes: [
            GoRoute(path: AppRoutes.profile, builder: (context, state) => const ProfileScreen()),
          ]),
        ],
      ),
    ],
  );
});
