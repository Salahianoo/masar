export type MasteryStatus = "unknown" | "weak" | "medium" | "strong";

export interface ConceptState {
  theta: number;
  attempts: number;
  correct: number;
  recent: boolean[];
  lastSeen?: Date;
}

export interface WeightedConcept {
  id: string;
  name: string;
  weight: number;
  order: number;
}

export interface PlanEntry {
  conceptId: string;
  count: number;
  done: number;
  isReview: boolean;
}

export interface CandidateQuestion {
  id: string;
  examId: string;
  difficulty: number;
  conceptIds: string[];
}

export const probability = (theta: number, difficulty: number): number =>
  1 / (1 + Math.exp(-(theta - difficulty)));

export const studentStep = (attempts: number): number =>
  Math.max(0.25, 0.8 / (1 + 0.15 * attempts));

export function updateAbility(
  theta: number,
  difficulty: number,
  attempts: number,
  correct: boolean,
  secondary = false,
): number {
  const step = studentStep(attempts) * (secondary ? 0.5 : 1);
  return theta + step * ((correct ? 1 : 0) - probability(theta, difficulty));
}

export function updateDifficulty(
  theta: number,
  difficulty: number,
  correct: boolean,
): number {
  return difficulty - 0.05 * ((correct ? 1 : 0) - probability(theta, difficulty));
}

export const mastery = (theta: number): number =>
  Math.round(100 / (1 + Math.exp(-theta)));

export function status(attempts: number, masteryValue: number): MasteryStatus {
  if (attempts === 0) return "unknown";
  if (masteryValue < 40) return "weak";
  if (masteryValue < 70) return "medium";
  return "strong";
}

export function readiness(
  concepts: WeightedConcept[],
  states: Record<string, ConceptState>,
): number {
  return Math.round(concepts.reduce((sum, concept) => {
    const state = states[concept.id];
    return sum + concept.weight * (state?.attempts ? mastery(state.theta) : 0);
  }, 0));
}

export const projectedReadiness = (value: number, daysLeft: number): number =>
  Math.min(90, value + 7 * daysLeft);

export function buildPlan(
  concepts: WeightedConcept[],
  states: Record<string, ConceptState>,
  daysLeft: number,
  now: Date,
): {items: PlanEntry[]; minutes: number} {
  const priority = [...concepts].sort((a, b) => {
    const am = states[a.id]?.attempts ? mastery(states[a.id].theta) : 0;
    const bm = states[b.id]?.attempts ? mastery(states[b.id].theta) : 0;
    return b.weight * (1 - bm / 100) - a.weight * (1 - am / 100) || a.order - b.order;
  });
  const selected = priority.slice(0, 3);
  if (selected.length === 0) return {items: [], minutes: 0};
  const budget = daysLeft > 14 ? 12 : 15;
  const scores = selected.map((concept) => {
    const state = states[concept.id];
    return concept.weight * (1 - (state?.attempts ? mastery(state.theta) : 0) / 100);
  });
  const scoreTotal = scores.reduce((sum, score) => sum + score, 0);
  const counts = selected.map(() => 2);
  let left = Math.max(0, budget - counts.reduce((sum, count) => sum + count, 0));
  const shares = scores.map((score) => scoreTotal > 0 ? score / scoreTotal : 1 / selected.length);
  const fractional = shares.map((share, i) => ({i, value: share * left - Math.floor(share * left)}));
  shares.forEach((share, i) => { counts[i] += Math.floor(share * left); });
  left = budget - counts.reduce((sum, count) => sum + count, 0);
  fractional.sort((a, b) => b.value - a.value || a.i - b.i);
  for (let i = 0; i < left; i++) counts[fractional[i].i]++;
  const items: PlanEntry[] = selected.map((concept, i) => ({
    conceptId: concept.id, count: counts[i], done: 0, isReview: false,
  }));
  const reviews = concepts.filter((concept) => {
    const state = states[concept.id];
    return !selected.some((item) => item.id === concept.id) && state?.attempts > 0 &&
      status(state.attempts, mastery(state.theta)) === "strong" &&
      !!state.lastSeen && now.getTime() - state.lastSeen.getTime() >= 2 * 86400000;
  }).sort((a, b) => b.weight - a.weight || a.order - b.order).slice(0, 2);
  reviews.forEach((concept) => items.push({conceptId: concept.id, count: 1, done: 0, isReview: true}));
  return {items, minutes: Math.round(items.reduce((sum, item) => sum + item.count, 0) * 1.3)};
}

export function pickNextQuestion(
  questions: CandidateQuestion[],
  theta: number,
  answeredRecently: Set<string>,
): CandidateQuestion | null {
  const eligible = questions.filter((question) => !answeredRecently.has(question.id));
  eligible.sort((a, b) =>
    Math.abs(a.difficulty - (theta - 0.85)) - Math.abs(b.difficulty - (theta - 0.85)) ||
    a.id.localeCompare(b.id));
  return eligible[0] ?? null;
}

export function pickDiagnostic(
  concepts: WeightedConcept[],
  questions: CandidateQuestion[],
): CandidateQuestion[] {
  const selected: CandidateQuestion[] = [];
  const usedExams = new Set<string>();
  const ranked = [...concepts].sort((a, b) => b.weight - a.weight || a.order - b.order).slice(0, 8);
  for (const concept of ranked) {
    const pool = questions.filter((question) => question.conceptIds.includes(concept.id) &&
      !selected.some((item) => item.id === question.id));
    pool.sort((a, b) =>
      Number(usedExams.has(a.examId)) - Number(usedExams.has(b.examId)) ||
      Math.abs(a.difficulty) - Math.abs(b.difficulty) || a.id.localeCompare(b.id));
    if (pool[0]) {
      selected.push(pool[0]);
      usedExams.add(pool[0].examId);
    }
  }
  return selected;
}
