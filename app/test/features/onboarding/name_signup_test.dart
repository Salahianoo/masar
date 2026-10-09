import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:masar/core/di/repository_provider.dart';
import 'package:masar/data/repositories/local_masar_repository.dart';
import 'package:masar/presentation/screens/home/home_screen.dart';
import 'package:masar/presentation/screens/onboarding/onboarding_screen.dart';

void main() {
  testWidgets('the name alone signs up, gives a 5-digit number, and lands on an empty home',
      (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final repo = LocalMasarRepository();
    final router = GoRouter(initialLocation: '/onboarding', routes: [
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      GoRoute(path: '/home', builder: (_, _) => const Scaffold(body: HomeScreen())),
      GoRoute(path: '/subjects/add', builder: (_, _) => const Scaffold(body: Text('add subject'))),
    ]);
    await tester.pumpWidget(ProviderScope(
      overrides: [masarRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp.router(
        routerConfig: router,
        builder: (_, child) => Directionality(textDirection: TextDirection.rtl, child: child!),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'ليان');
    await tester.tap(find.text('ادخل'));
    await tester.pumpAndSettle();

    final profile = await repo.currentProfile();
    expect(profile!.displayName, 'ليان');
    expect(profile.studentId, matches(RegExp(r'^[1-9]\d{4}$')));
    expect(find.textContaining(profile.studentId!), findsOneWidget); // the welcome snackbar

    // Re-saving the name keeps the number.
    await repo.updateProfile('ليان أحمد');
    expect((await repo.currentProfile())!.studentId, profile.studentId);

    expect(find.byType(ChooseSubjectButton), findsOneWidget);
    await tester.tap(find.byType(ChooseSubjectButton));
    await tester.pumpAndSettle();
    expect(find.text('add subject'), findsOneWidget);
  });
}
