import {describe, expect, it} from "vitest";
import {
  buildPlan, mastery, pickDiagnostic, pickNextQuestion, probability,
  projectedReadiness, readiness, status, studentStep, updateAbility, updateDifficulty,
  type WeightedConcept,
} from "./engine";

const concepts: WeightedConcept[] = [
  {id: "a", name: "أ", weight: 0.5, order: 0},
  {id: "b", name: "ب", weight: 0.3, order: 1},
  {id: "c", name: "ج", weight: 0.2, order: 2},
];

describe("learning engine", () => {
  it("updates ability and question difficulty with the contracted Elo math", () => {
    const p = probability(-1, 0);
    expect(p).toBeCloseTo(0.2689414214);
    expect(studentStep(0)).toBe(0.8);
    expect(updateAbility(-1, 0, 0, true)).toBeCloseTo(-1 + 0.8 * (1 - p));
    expect(updateAbility(-1, 0, 0, true, true)).toBeCloseTo(-1 + 0.4 * (1 - p));
    expect(updateDifficulty(-1, 0, true)).toBeCloseTo(-0.05 * (1 - p));
    expect(studentStep(100)).toBe(0.25);
  });

  it("keeps unattempted concepts unknown and out of readiness", () => {
    const states = {a: {theta: 2, attempts: 1, correct: 1, recent: [true]}};
    expect(mastery(2)).toBe(88);
    expect(status(0, 88)).toBe("unknown");
    expect(status(1, 39)).toBe("weak");
    expect(status(1, 40)).toBe("medium");
    expect(status(1, 70)).toBe("strong");
    expect(readiness(concepts, states)).toBe(44);
    expect(projectedReadiness(44, 10)).toBe(90);
  });

  it("allocates the full plan budget, plus eligible reviews", () => {
    const plan = buildPlan(concepts, {}, 7, new Date("2026-10-09T12:00:00Z"));
    expect(plan.items.reduce((sum, item) => sum + item.count, 0)).toBe(15);
    expect(plan.items.every((item) => item.count >= 2)).toBe(true);
    expect(plan.minutes).toBe(20);
    expect(buildPlan([], {}, 7, new Date()).items).toEqual([]);
  });

  it("selects diagnostic questions across exams and next questions near the target", () => {
    const questions = [
      {id: "a1", examId: "x", difficulty: 0, conceptIds: ["a"]},
      {id: "a2", examId: "y", difficulty: 0.1, conceptIds: ["a"]},
      {id: "b1", examId: "x", difficulty: 0, conceptIds: ["b"]},
      {id: "b2", examId: "y", difficulty: 0.2, conceptIds: ["b"]},
    ];
    expect(pickDiagnostic(concepts, questions).map((q) => q.id)).toEqual(["a1", "b2"]);
    expect(pickNextQuestion(questions, -1, new Set(["a1"]))?.id).toBe("b1");
  });

});
