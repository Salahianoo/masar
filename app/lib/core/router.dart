import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/diagnostic/diagnostic_screen.dart';
import '../features/home/home_screen.dart';
import '../features/map/map_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/profile/profile_screen.dart';
import 'app_shell.dart';
import 'routes.dart';
import 'splash_screen.dart';
import 'widgets/placeholder_screen.dart';

export 'routes.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (context, state) => const SplashScreen()),
      GoRoute(path: AppRoutes.onboarding, builder: (context, state) => const OnboardingScreen()),
      GoRoute(
        path: '/diagnostic/:subjectId',
        builder: (context, state) =>
            DiagnosticScreen(subjectId: state.pathParameters['subjectId']!),
      ),
      GoRoute(
        path: '/map/:subjectId',
        builder: (context, state) => MapScreen(subjectId: state.pathParameters['subjectId']!),
      ),

      // ── Osama's screens: placeholders until he swaps them in ──
      GoRoute(
        path: '/practice/:subjectId',
        builder: (context, state) => PlaceholderScreen(
          title: 'التمرين',
          details: 'subjectId=${state.pathParameters['subjectId']} '
              '${state.uri.queryParameters}',
        ),
      ),
      GoRoute(
        path: '/summary/:subjectId',
        builder: (context, state) => PlaceholderScreen(
          title: 'ملخص الجلسة',
          details: 'subjectId=${state.pathParameters['subjectId']}',
        ),
      ),
      GoRoute(
        path: '/khazna/exam/:examId',
        builder: (context, state) => PlaceholderScreen(
          title: 'امتحان سابق',
          details: 'examId=${state.pathParameters['examId']}',
        ),
      ),

      // ── the 4 tabs ──
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.home, builder: (context, state) => const HomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.khazna,
              builder: (context, state) =>
                  const PlaceholderScreen(title: 'خزنة', showAppBar: false),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.mentor,
              builder: (context, state) =>
                  const PlaceholderScreen(title: 'المرشد', showAppBar: false),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.profile, builder: (context, state) => const ProfileScreen()),
          ]),
        ],
      ),
    ],
  );
});
