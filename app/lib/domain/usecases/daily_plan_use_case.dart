import 'package:masar/domain/entities/entities.dart';
import 'package:masar/domain/services/learning_engine.dart';

typedef PlanConceptState = ({double theta, int attempts, DateTime? lastSeen});

/// Builds the CONTRACT §7 plan from concepts and current mastery only.
abstract final class DailyPlanUseCase {
  static TodayPlan build({
    required String subjectId,
    required List<Concept> concepts,
    required Map<String, PlanConceptState> states,
    required int daysLeft,
    required DateTime now,
  }) {
    final ranked = concepts.map((concept) {
      final state = states[concept.id]!;
      final mastery = LearningEngine.mastery(state.theta);
      return (
        concept: concept,
        state: state,
        mastery: mastery,
        priority: LearningEngine.priority(
          weight: concept.weight, mastery: mastery, attempts: state.attempts),
      );
    }).toList()
      ..sort((a, b) => b.priority.compareTo(a.priority));

    final top = ranked.take(LearningEngine.planConcepts).toList();
    final counts = LearningEngine.splitBudget(
      top.map((item) => item.priority).toList(), LearningEngine.dailyBudget(daysLeft));
    final items = <PlanItem>[
      for (var i = 0; i < top.length; i++)
        PlanItem(
          conceptId: top[i].concept.id,
          conceptName: top[i].concept.name,
          count: counts[i], done: 0, isReview: false,
          status: LearningEngine.status(
            attempts: top[i].state.attempts, mastery: top[i].mastery),
        ),
    ];

    final topIds = top.map((item) => item.concept.id).toSet();
    final review = ranked.where((item) =>
      !topIds.contains(item.concept.id) &&
      LearningEngine.status(attempts: item.state.attempts, mastery: item.mastery) ==
          MasteryStatus.strong &&
      item.state.lastSeen != null &&
      now.difference(item.state.lastSeen!).inDays >= LearningEngine.reviewAfterDays,
    ).toList()..sort((a, b) => a.state.lastSeen!.compareTo(b.state.lastSeen!));
    final reviewPicks = review.take(LearningEngine.reviewQuestions).toList();
    for (final item in reviewPicks) {
      items.add(PlanItem(
        conceptId: item.concept.id,
        conceptName: item.concept.name,
        count: LearningEngine.reviewQuestions ~/ reviewPicks.length,
        done: 0, isReview: true, status: MasteryStatus.strong,
      ));
    }
    final total = items.fold(0, (sum, item) => sum + item.count);
    return TodayPlan(
      subjectId: subjectId, daysLeft: daysLeft,
      minutes: LearningEngine.planMinutes(total), items: items, completed: false,
    );
  }
}
