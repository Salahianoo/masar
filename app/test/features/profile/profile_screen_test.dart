import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:masar/data/repositories/local_masar_repository.dart';
import 'package:masar/domain/entities/entities.dart';
import 'package:masar/presentation/screens/profile/profile_screen.dart';
import 'package:masar/presentation/screens/profile/profile_stats.dart';
import 'package:masar/presentation/screens/profile/profile_widgets.dart';
import 'package:masar/presentation/state/providers.dart';
import 'package:masar/presentation/state/theme_mode_provider.dart';
import 'package:masar/presentation/themes/app_theme.dart';

late LocalMasarRepository repo;

/// The profile inside a themed app that follows [themeModeProvider], like main.dart.
class _App extends ConsumerWidget {
  const _App(this.router);
  final GoRouter router;

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ref.watch(themeModeProvider),
        themeAnimationDuration: Duration.zero,
        routerConfig: router,
        builder: (context, child) {
          AppColors.use(Theme.of(context).brightness);
          return Directionality(textDirection: TextDirection.rtl, child: child!);
        },
      );
}

Future<void> pumpProfile(WidgetTester tester) async {
  tester.view.physicalSize = const Size(360 * 3, 780 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    initialLocation: '/profile',
    routes: [
      GoRoute(path: '/profile', builder: (_, _) => const Scaffold(body: ProfileScreen())),
      GoRoute(path: '/map/:id', builder: (_, s) => Text('map ${s.pathParameters['id']}')),
    ],
  );
  await tester.pumpWidget(ProviderScope(
    overrides: [masarRepositoryProvider.overrideWithValue(repo)],
    child: _App(router),
  ));
  await tester.pumpAndSettle();
}

/// The profile is a lazy list: scroll until [finder] is built and on screen.
Future<void> reveal(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(finder, 200, scrollable: find.byType(Scrollable).first);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() async {
    AppColors.use(Brightness.light);
    repo = LocalMasarRepository();
    await repo.signIn();
    await repo.updateProfile('سارة');
    await repo.enroll('first-aid', DateTime.now().add(const Duration(days: 7)));
    for (final q in await repo.startDiagnostic('first-aid')) {
      await repo.submitAnswer(
          questionId: q.id, chosen: q.options.first.label, ms: 1, source: AnswerSource.diagnostic);
    }
    await repo.completeDiagnostic('first-aid');
  });

  test('ProfileStats sums concepts and averages finished subjects', () async {
    final enrollments = await repo.enrollments();
    final progress = await repo.progress('first-aid').first;
    final stats = ProfileStats.from(enrollments, {'first-aid': progress});
    expect(stats.subjectCount, 1);
    expect(stats.averageReadiness, progress.readiness);
    expect(stats.conceptCount, progress.concepts.length);
    expect(stats.answers, progress.concepts.fold(0, (s, c) => s + c.attempts));
    expect(stats.nearestExamDays, 7);
    expect(ProfileStats.from(const [], const {}).averageReadiness, isNull);
  });

  testWidgets('shows the student, the stats, the subject and the settings', (tester) async {
    await pumpProfile(tester);

    expect(find.text('سارة'), findsOneWidget);
    expect(find.text('إحصائياتي'), findsOneWidget);
    expect(find.text('متوسط جاهزيتك'), findsOneWidget);
    expect(find.text('7 يوم'), findsOneWidget);
    expect(find.byType(MasteryBreakdown), findsOneWidget);
    await reveal(tester, find.byType(SubjectProgressCard));
    expect(find.textContaining('باقي 7 يوم'), findsOneWidget);
    await reveal(tester, find.byType(AppearanceSetting));
    expect(find.text('داكن'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('switching to dark repaints with the dark palette', (tester) async {
    await pumpProfile(tester);
    expect(Theme.of(tester.element(find.byType(ProfileScreen))).brightness, Brightness.light);

    await reveal(tester, find.text('داكن'));
    await tester.tap(find.text('داكن'));
    await tester.pumpAndSettle();

    expect(Theme.of(tester.element(find.byType(ProfileScreen))).brightness, Brightness.dark);
    expect(AppColors.palette, same(AppPalette.dark));
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('فاتح'));
    await tester.pumpAndSettle();
    expect(AppColors.palette, same(AppPalette.light));
  });

  testWidgets('editing the name updates the header', (tester) async {
    await pumpProfile(tester);
    await tester.tap(find.byTooltip('غيّر اسمك'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'سارة أحمد');
    await tester.tap(find.text('احفظ'));
    await tester.pumpAndSettle();
    expect(find.text('سارة أحمد'), findsOneWidget);
  });
}
