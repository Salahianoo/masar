import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:masar/data/datasources/local/local_data.g.dart';
import 'package:masar/data/datasources/remote/rafeeq_client.dart';
import 'package:masar/data/repositories/local_masar_repository.dart';
import 'package:masar/presentation/screens/mentor/mentor_screen.dart';
import 'package:masar/presentation/screens/mentor/rafeeq_welcome.dart';
import 'package:masar/presentation/state/providers.dart';

/// رفيق without the PC: always answers the same, and remembers what it was asked.
class FakeRafeeqClient extends RafeeqClient {
  static const reply = 'هاد جواب رفيق التجريبي';
  final List<String> systems = [];
  final List<String> lastUserTexts = [];

  @override
  Future<String> chat({
    required String system,
    required List<({String role, String text})> history,
  }) async {
    systems.add(system);
    lastUserTexts.add(history.last.text);
    return reply;
  }
}

late LocalMasarRepository repo;
late FakeRafeeqClient rafeeq;

Future<void> pumpMentor(WidgetTester tester, {double height = 780, double keyboard = 0}) async {
  // A 360-dp-wide phone: any overflow fails the test.
  tester.view.physicalSize = Size(360 * 3, height * 3);
  tester.view.devicePixelRatio = 3;
  tester.view.viewInsets = FakeViewPadding(bottom: keyboard * 3);
  addTearDown(tester.view.reset);

  final router = GoRouter(
    initialLocation: '/mentor',
    routes: [
      GoRoute(path: '/mentor', builder: (_, _) => const MentorScreen()),
      GoRoute(
        path: '/practice/:subjectId',
        builder: (_, s) => Text(
            'practice ${s.pathParameters['subjectId']} ${s.uri.queryParameters['mode']}'),
      ),
    ],
  );
  await tester.pumpWidget(ProviderScope(
    overrides: [masarRepositoryProvider.overrideWithValue(repo)],
    child: MaterialApp.router(
      routerConfig: router,
      builder: (_, child) => Directionality(textDirection: TextDirection.rtl, child: child!),
    ),
  ));
  await tester.pumpAndSettle();
}


/// The welcome scrolls: bring the card into view, then tap it.
Future<void> tapCard(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text));
  await tester.pumpAndSettle();
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() async {
    rafeeq = FakeRafeeqClient();
    repo = LocalMasarRepository(rafeeq: rafeeq);
    await repo.signIn();
    await repo.updateProfile('طالب تجريبي');
    await repo.enroll('first-aid', DateTime.now().add(const Duration(days: 7)));
  });

  testWidgets('shows the greeting with the mentor name and the 4 cards', (tester) async {
    await pumpMentor(tester);

    expect(find.text('أهلاً، أنا ${localConfig.mentorName}'), findsOneWidget);
    expect(find.text('جرّب تسأل:'), findsOneWidget);
    expect(find.byType(SuggestionCard), findsNWidgets(4));
    for (final text in [
      RafeeqWelcome.examSoon,
      RafeeqWelcome.topTopics,
      RafeeqWelcome.quizMe,
      RafeeqWelcome.explainTopic,
    ]) {
      expect(find.bySemanticsLabel(text), findsOneWidget);
    }
    // every card is a comfortable tap target
    for (final card in tester.widgetList(find.byType(SuggestionCard))) {
      expect(tester.getSize(find.byWidget(card)).height, greaterThanOrEqualTo(48));
    }
  });

  testWidgets('scrolls without overflow when the keyboard is open', (tester) async {
    await pumpMentor(tester, height: 640, keyboard: 300);
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text(RafeeqWelcome.explainTopic));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text(RafeeqWelcome.explainTopic).hitTestable(), findsOneWidget);
  });

  testWidgets('card 2 sends its text and the reply replaces the welcome', (tester) async {
    await pumpMentor(tester);

    await tapCard(tester, RafeeqWelcome.topTopics);

    expect(rafeeq.lastUserTexts, [RafeeqWelcome.topTopics]);
    expect(find.text(RafeeqWelcome.topTopics), findsOneWidget); // now the user's bubble
    expect(find.text(FakeRafeeqClient.reply), findsOneWidget);
    expect(find.byType(RafeeqWelcome), findsNothing);
  });

  testWidgets('card 3 opens plan practice and sends nothing', (tester) async {
    await pumpMentor(tester);

    await tapCard(tester, RafeeqWelcome.quizMe);

    expect(find.text('practice first-aid plan'), findsOneWidget);
    expect(rafeeq.lastUserTexts, isEmpty);
  });

  testWidgets('card 4 picks a concept and asks about it, grounded on it', (tester) async {
    await pumpMentor(tester);
    final concept = (await repo.concepts('first-aid')).first;

    await tapCard(tester, RafeeqWelcome.explainTopic);
    await tester.ensureVisible(find.text(concept.name).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text(concept.name).last);
    await tester.pumpAndSettle();

    expect(rafeeq.lastUserTexts, ['اشرحلي ${concept.name}']);
    expect(rafeeq.systems.single, contains(concept.explanation.split('\n').first));
    expect(find.text(FakeRafeeqClient.reply), findsOneWidget);
  });
}
