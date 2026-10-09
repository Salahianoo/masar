import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:masar/core/data/mock_data.dart';
import 'package:masar/core/data/mock_masar_repository.dart';
import 'package:masar/features/practice/practice_core.dart';
import 'package:masar/features/practice/practice_args.dart';
import 'package:masar/features/practice/practice_screen.dart';
import 'package:masar/features/practice/widgets/option_card.dart';

late MockMasarRepository repo;

Future<void> pumpPractice(WidgetTester tester, String location) async {
  // A 360-dp-wide phone: any overflow fails the test.
  tester.view.physicalSize = const Size(360 * 3, 740 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final router = GoRouter(
    initialLocation: location,
    routes: [
      GoRoute(path: '/', builder: (_, _) => const Text('home')),
      GoRoute(path: '/practice/:subjectId', builder: (_, s) => PracticeScreen.fromState(s)),
      GoRoute(path: '/summary/:subjectId', builder: (_, _) => const Text('summary')),
    ],
  );
  await tester.pumpWidget(ProviderScope(
    overrides: [masarRepositoryProvider.overrideWithValue(repo)],
    child: MaterialApp.router(
      routerConfig: router,
      builder: (_, child) => Directionality(textDirection: TextDirection.rtl, child: child!),
    ),
  ));
  await settle(tester);
}

/// Lets the fake's latency timers fire, then waits for animations.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.pumpAndSettle();
}

Question currentQuestion(WidgetTester tester) {
  final text = tester.widget<Text>(find.byKey(const Key('practice.question'))).data;
  return buildMockQuestions().firstWhere((q) => q.question.text == text).question;
}

Future<void> answer(WidgetTester tester, {required bool correctly}) async {
  final q = currentQuestion(tester);
  final key = buildMockQuestions().firstWhere((item) => item.question.id == q.id).answer;
  final option = q.options.firstWhere((o) => (o.label == key) == correctly);
  await tester.tap(find.ancestor(of: find.text(option.text), matching: find.byType(OptionCard)));
  await settle(tester);
}

Future<void> tapNext(WidgetTester tester) async {
  await tester.tap(find.text('التالي'));
  await settle(tester);
}

double readinessBarValue(WidgetTester tester) =>
    tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator)).value!;

void main() {
  setUp(() async {
    repo = MockMasarRepository(simulateLatency: false);
    await repo.signIn();
    await repo.updateProfile('طالب تجريبي');
    await repo.enroll(mockSubjectId, DateTime.now().add(const Duration(days: 7)));
  });

  testWidgets('a correct answer moves readiness up live', (tester) async {
    await pumpPractice(tester, '/practice/first-aid?conceptId=bleeding');
    expect(find.text('النزيف · 1 من 8'), findsOneWidget);
    final before = readinessBarValue(tester);

    await answer(tester, correctly: true);

    expect(readinessBarValue(tester), greaterThan(before));
    expect(find.textContaining(RegExp(r'^الجاهزية \d+% \(\+\d+\)$')), findsOneWidget);
    final correctCard = tester.widgetList<OptionCard>(find.byType(OptionCard))
        .where((c) => c.state == OptionState.correct);
    expect(correctCard, hasLength(1));
  });

  testWidgets('two wrong answers on one concept open the mentor intervention', (tester) async {
    await pumpPractice(tester, '/practice/first-aid?conceptId=bleeding');

    await answer(tester, correctly: false);
    expect(find.textContaining(RegExp(r'^الجاهزية \d+%')), findsOneWidget);
    expect(tester.widgetList<OptionCard>(find.byType(OptionCard)).map((c) => c.state),
        containsAll([OptionState.wrong, OptionState.correct]));
    await tapNext(tester);
    expect(find.textContaining('شكلك ملخبط'), findsNothing);
    expect(find.text('النزيف · 2 من 8'), findsOneWidget);

    await answer(tester, correctly: false);
    await tapNext(tester);
    expect(find.text('شكلك ملخبط شوي بـالنزيف. بدك أشرحلك بدقيقة؟'), findsOneWidget);

    await tester.tap(find.text('لا، بكمل'));
    await settle(tester);
    expect(find.textContaining('شكلك ملخبط'), findsNothing);
    expect(find.text('النزيف · 3 من 8'), findsOneWidget);
  });

  testWidgets('plan mode walks the plan and ends on the summary', (tester) async {
    await pumpPractice(tester, '/practice/first-aid?mode=plan');
    final plan = (await tester.runAsync(() => repo.todayPlan('first-aid')))!;
    final first = plan.items.first;
    expect(find.text('${first.conceptName} · 1 من ${plan.items.fold(0, (s, i) => s + i.count)}'),
        findsOneWidget);

    for (var i = 0; i < 40 && find.text('summary').evaluate().isEmpty; i++) {
      await answer(tester, correctly: true);
      await tapNext(tester);
    }
    expect(find.text('summary'), findsOneWidget);
    expect(((await tester.runAsync(() => repo.todayPlan('first-aid')))!).items.first.done, greaterThan(0));
  });

  testWidgets('exam mode shows the paper with its label', (tester) async {
    await pumpPractice(tester, '/practice/first-aid?mode=exam&examId=first-aid-final-2024');
    final paper = (await tester.runAsync(() => repo.examQuestions('first-aid-final-2024')))!;
    expect(find.text('من نهائي 2024'), findsOneWidget);
    expect(find.textContaining('1 من ${paper.length}'), findsOneWidget);
    expect(currentQuestion(tester).id, paper.first.id);
  });

  testWidgets('leaving mid-session asks for confirmation', (tester) async {
    await pumpPractice(tester, '/practice/first-aid?conceptId=burns');
    await answer(tester, correctly: true);
    await tester.tap(find.byIcon(Icons.close));
    await settle(tester);
    expect(find.text('بدك تطلع؟'), findsOneWidget);
    await tester.tap(find.text('بكمل'));
    await settle(tester);
    expect(find.byType(PracticeScreen), findsOneWidget);
  });

  test('route args pick the mode', () {
    expect(PracticeArgs.fromRoute('s', {'mode': 'plan'}).mode, PracticeMode.plan);
    expect(PracticeArgs.fromRoute('s', {}).mode, PracticeMode.plan);
    expect(PracticeArgs.fromRoute('s', {'conceptId': 'c'}).mode, PracticeMode.concept);
    expect(PracticeArgs.fromRoute('s', {'mode': 'exam', 'examId': 'e'}).mode, PracticeMode.exam);
  });
}
