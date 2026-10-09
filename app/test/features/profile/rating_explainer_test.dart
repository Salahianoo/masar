import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masar/presentation/screens/profile/rating_explainer_screen.dart';

void main() {
  testWidgets('the simulator moves mastery exactly like the learning engine', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 1600 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(
      home: Directionality(textDirection: TextDirection.rtl, child: RatingExplainerScreen()),
    ));
    await tester.pumpAndSettle();

    // Everyone starts at θ = −1 → 27%; a medium question gives a 27% chance.
    expect(find.text('27%'), findsWidgets);

    // A right answer on that question: θ = −1 + 0.8 × (1 − 0.27) ≈ −0.42 → 40%, i.e. +13.
    await tester.tap(find.text('جاوبت صح'));
    await tester.pumpAndSettle();
    expect(find.text('40%'), findsNWidgets(2)); // mastery, and the chance on a medium question
    expect(find.text('\u2066+13%\u2069 بآخر جواب'), findsOneWidget);

    // A wrong answer then pulls it back down.
    await tester.tap(find.text('جاوبت غلط'));
    await tester.pumpAndSettle();
    expect(find.textContaining('-'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
