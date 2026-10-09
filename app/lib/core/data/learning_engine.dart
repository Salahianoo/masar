import 'dart:math' as math;

import '../models/enums.dart';

/// CONTRACT §7 math. Pure functions so the mock and the tests share one copy.
/// Salah's functions implement the same formulas in TypeScript.
abstract final class LearningEngine {
  static const initialTheta = -1.0;
  static const initialDifficulty = 0.0;
  static const questionStep = 0.05;
  static const targetOffset = 0.85; // theta − 0.85 ≈ 70% success
  static const projectedCap = 90;
  static const projectedPerDay = 7;
  static const reviewQuestions = 2;
  static const reviewAfterDays = 2;
  static const skipRecentDays = 3;
  static const diagnosticSize = 8;
  static const planConcepts = 3;
  static const minPerConcept = 2;

  static String nudgeMessage(String conceptName) =>
      'شكلك ملخبط شوي بـ$conceptName. بدك أشرحلك بدقيقة؟';

  /// p = 1 / (1 + exp(-(theta - b)))
  static double pCorrect(double theta, double b) => 1 / (1 + math.exp(-(theta - b)));

  /// K_s = max(0.25, 0.8 / (1 + 0.15 * attempts))
  static double studentStep(int attempts) => math.max(0.25, 0.8 / (1 + 0.15 * attempts));

  /// New theta after one answer. Secondary concepts move half a step.
  static double updateTheta({
    required double theta,
    required double b,
    required int attempts,
    required bool correct,
    bool secondary = false,
  }) {
    final r = correct ? 1.0 : 0.0;
    final k = studentStep(attempts) * (secondary ? 0.5 : 1.0);
    return theta + k * (r - pCorrect(theta, b));
  }

  /// b −= 0.05 × (r − p), with p from the primary concept's theta before the update.
  static double updateDifficulty({required double b, required double theta, required bool correct}) {
    final r = correct ? 1.0 : 0.0;
    return b - questionStep * (r - pCorrect(theta, b));
  }

  /// mastery = round(100 / (1 + exp(-theta)))
  static int mastery(double theta) => (100 / (1 + math.exp(-theta))).round();

  static MasteryStatus status({required int attempts, required int mastery}) {
    if (attempts == 0) return MasteryStatus.unknown;
    if (mastery < 40) return MasteryStatus.weak;
    if (mastery < 70) return MasteryStatus.medium;
    return MasteryStatus.strong;
  }

  /// round(Σ weight × mastery); concepts with no attempts count as 0.
  /// [concepts] maps conceptId → (weight, mastery, attempts).
  static int readiness(Iterable<({double weight, int mastery, int attempts})> concepts) {
    var sum = 0.0;
    for (final c in concepts) {
      if (c.attempts > 0) sum += c.weight * c.mastery;
    }
    return sum.round();
  }

  static int projectedReadiness(int readiness, int daysLeft) =>
      math.min(projectedCap, readiness + projectedPerDay * daysLeft);

  /// priority = weight × (1 − mastery/100); unknown → weight.
  static double priority({required double weight, required int mastery, required int attempts}) =>
      attempts == 0 ? weight : weight * (1 - mastery / 100);

  /// 15 questions a day, 12 when the exam is more than two weeks away.
  static int dailyBudget(int daysLeft) => daysLeft > 14 ? 12 : 15;

  /// Splits [budget] across [priorities] proportionally, at least [minPerConcept] each.
  /// Rounding leftovers go to the highest priorities first.
  static List<int> splitBudget(List<double> priorities, int budget) {
    if (priorities.isEmpty) return const [];
    final total = priorities.fold(0.0, (a, b) => a + b);
    final shares = total <= 0
        ? List<double>.filled(priorities.length, budget / priorities.length)
        : priorities.map((p) => budget * p / total).toList();
    final counts = shares.map((s) => math.max(minPerConcept, s.floor())).toList();
    var left = budget - counts.fold(0, (a, b) => a + b);
    // priorities arrive sorted desc, so index order is priority order
    for (var i = 0; left > 0; i = (i + 1) % counts.length) {
      counts[i]++;
      left--;
    }
    return counts;
  }

  /// minutes = round(totalQuestions × 1.3)
  static int planMinutes(int totalQuestions) => (totalQuestions * 1.3).round();

  /// The difficulty the next question should be closest to.
  static double targetDifficulty(double theta) => theta - targetOffset;
}
