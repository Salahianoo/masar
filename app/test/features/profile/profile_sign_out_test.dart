import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:masar/core/di/repository_provider.dart';
import 'package:masar/data/repositories/local_masar_repository.dart';
import 'package:masar/domain/repositories/google_account_service.dart';
import 'package:masar/presentation/screens/profile/profile_screen.dart';

class ConnectedGoogleAccount implements GoogleAccountService {
  @override
  bool get hasSession => true;
  @override
  bool get isGoogleConnected => true;
  @override
  Future<String?> signInWithGoogle() async => 'طالب مسار';
}

void main() {
  testWidgets('sign-out confirmation clears progress and returns to Google login', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 740 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final repo = LocalMasarRepository();
    await repo.signIn();
    await repo.updateProfile('طالب مسار');
    await repo.enroll('first-aid', DateTime.now().add(const Duration(days: 7)));
    final router = GoRouter(initialLocation: '/profile', routes: [
      GoRoute(path: '/profile', builder: (_, _) => const Scaffold(body: ProfileScreen())),
      GoRoute(path: '/sign-in', builder: (_, _) => const Scaffold(body: Text('Google login'))),
      GoRoute(path: '/subjects/add', builder: (_, _) => const Text('add subject')),
    ]);
    await tester.pumpWidget(ProviderScope(overrides: [
      masarRepositoryProvider.overrideWithValue(repo),
      googleAccountServiceProvider.overrideWithValue(ConnectedGoogleAccount()),
    ], child: MaterialApp.router(routerConfig: router,
      builder: (_, child) => Directionality(textDirection: TextDirection.rtl, child: child!))));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('تسجيل خروج'));
    await tester.tap(find.text('تسجيل خروج'));
    await tester.pumpAndSettle();
    expect(find.text('تقدّمك محفوظ بحساب Google. بتقدر ترجعله لما تسجّل دخول من جديد.'),
        findsOneWidget);
    await tester.tap(find.text('اطلع'));
    await tester.pumpAndSettle();
    expect(find.text('Google login'), findsOneWidget);

    await repo.signIn();
    expect(await repo.currentProfile(), isNull);
    expect(await repo.enrollments(), isEmpty);
  });
}
