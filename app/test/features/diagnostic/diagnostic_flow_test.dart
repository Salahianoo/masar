import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:masar/core/di/repository_provider.dart';
import 'package:masar/data/repositories/local_masar_repository.dart';
import 'package:masar/presentation/screens/diagnostic/diagnostic_screen.dart';
import 'package:masar/presentation/screens/practice/widgets/option_card.dart';

void main() {
  testWidgets('diagnostic saves a choice without revealing correctness or readiness', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 740 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final repo = LocalMasarRepository();
    await repo.signIn();
    await repo.updateProfile('طالب تجريبي');
    await repo.enroll('first-aid', DateTime.now().add(const Duration(days: 7)));
    final router = GoRouter(initialLocation: '/diagnostic/first-aid', routes: [
      GoRoute(path: '/diagnostic/:subjectId', builder: (_, _) =>
          const DiagnosticScreen(subjectId: 'first-aid')),
      GoRoute(path: '/map/:subjectId', builder: (_, _) => const Text('map')),
    ]);
    await tester.pumpWidget(ProviderScope(
      overrides: [masarRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp.router(routerConfig: router,
        builder: (_, child) => Directionality(textDirection: TextDirection.rtl, child: child!)),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(OptionCard).first);
    await tester.pumpAndSettle();

    expect(tester.widgetList<OptionCard>(find.byType(OptionCard)).map((card) => card.state),
        isNot(contains(OptionState.correct)));
    expect(tester.widgetList<OptionCard>(find.byType(OptionCard)).map((card) => card.state),
        isNot(contains(OptionState.wrong)));
    expect(find.textContaining('الجاهزية'), findsNothing);
    expect(find.text('تم حفظ إجابتك. كمّل التشخيص عشان تشوف خريطتك.'), findsOneWidget);
  });
}
