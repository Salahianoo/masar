import {beforeAll, afterAll, describe, expect, it} from "vitest";
import {initializeApp as initializeAdminApp, deleteApp as deleteAdminApp} from "firebase-admin/app";
import {getFirestore, Timestamp} from "firebase-admin/firestore";
import {initializeApp, deleteApp} from "firebase/app";
import {getAuth, connectAuthEmulator, signInAnonymously} from "firebase/auth";
import {getFunctions, connectFunctionsEmulator, httpsCallable} from "firebase/functions";

const projectId = "demo-masar-backend";
const adminApp = initializeAdminApp({projectId}, "backend-test");
const db = getFirestore(adminApp);
const clientApps = [1, 2].map((i) => initializeApp({projectId, apiKey: "demo-key", appId: `demo-${i}`}, `student-${i}`));
const call = (index: number, name: string) => httpsCallable(getFunctions(clientApps[index], "europe-west1"), name);

beforeAll(async () => {
  for (const app of clientApps) {
    connectAuthEmulator(getAuth(app), "http://127.0.0.1:9099", {disableWarnings: true});
    connectFunctionsEmulator(getFunctions(app, "europe-west1"), "127.0.0.1", 5001);
  }
  await Promise.all(clientApps.map((app) => signInAnonymously(getAuth(app))));
  const batch = db.batch();
  batch.set(db.doc("subjects/first-aid"), {name: "ثقافة صحية", questionCount: 9, conceptCount: 8, active: true});
  for (let i = 0; i < 8; i++) {
    const id = `concept-${i}`;
    const questionId = `question-${i}`;
    batch.set(db.doc(`subjects/first-aid/concepts/${id}`), {
      name: `مفهوم ${i}`, weight: 0.125, explanation: `شرح المفهوم ${i}`,
      order: i, learners: 0, masterySum: 0,
    });
    batch.set(db.doc(`questions/${questionId}`), {subjectId: "first-aid", examId: `exam-${i % 2}`,
      examLabel: "نهائي 2024", kind: "mcq", text: `السؤال ${i}`, conceptIds: [id],
      options: [{label: "أ", text: "صحيح"}, {label: "ب", text: "خطأ"}], difficulty: 0,
      attempts: 0, correctCount: 0, optionCounts: {}, flagged: false});
    batch.set(db.doc(`answerKeys/${questionId}`), {answer: "أ"});
  }
  batch.set(db.doc("questions/question-extra"), {subjectId: "first-aid", examId: "exam-extra",
    examLabel: "نصفي 2024", kind: "mcq", text: "سؤال إضافي", conceptIds: ["concept-0"],
    options: [{label: "أ", text: "صحيح"}, {label: "ب", text: "خطأ"}], difficulty: 0.5,
    attempts: 0, correctCount: 0, optionCounts: {}, flagged: false});
  batch.set(db.doc("answerKeys/question-extra"), {answer: "أ"});
  await batch.commit();
}, 30000);

afterAll(async () => {
  await Promise.all(clientApps.map(deleteApp));
  await deleteAdminApp(adminApp);
});

describe("callable learning flow", () => {
  it("keeps two students' readiness separate and updates analytics atomically", async () => {
    const examDate = new Date(Date.now() + 10 * 86400000).toISOString().slice(0, 10);
    for (let i = 0; i < 2; i++) {
      await call(i, "updateProfile")({displayName: `طالب ${i}`});
      await call(i, "enroll")({subjectId: "first-aid", examDate});
      const diagnostic = (await call(i, "startDiagnostic")({subjectId: "first-aid"})).data as {
        questions: {id: string}[];
      };
      expect(diagnostic.questions).toHaveLength(8);
      for (const question of diagnostic.questions) {
        await call(i, "submitAnswer")({questionId: question.id, chosen: i === 0 ? "أ" : "ب",
          ms: 1200, source: "diagnostic"});
      }
      const result = (await call(i, "completeDiagnostic")({subjectId: "first-aid"})).data as {
        readiness: number; concepts: unknown[];
      };
      expect(result.concepts).toHaveLength(8);
      expect(result.readiness).toBeGreaterThan(0);
      const plan = (await call(i, "todayPlan")({subjectId: "first-aid"})).data as {
        items: {count: number}[]; minutes: number;
      };
      expect(plan.items.reduce((sum, item) => sum + item.count, 0)).toBe(15);
      expect(plan.minutes).toBe(20);
    }
    const uid1 = getAuth(clientApps[0]).currentUser!.uid;
    const uid2 = getAuth(clientApps[1]).currentUser!.uid;
    const first = await db.doc(`users/${uid1}/mastery/first-aid`).get();
    const second = await db.doc(`users/${uid2}/mastery/first-aid`).get();
    expect(first.get("readiness")).toBeGreaterThan(second.get("readiness"));
    const day = new Intl.DateTimeFormat("en-CA", {timeZone: "Asia/Amman", year: "numeric",
      month: "2-digit", day: "2-digit"}).format(new Date());
    const stats = await db.doc(`statsDaily/${day}`).get();
    expect(stats.get("newUsers")).toBe(2);
    expect(stats.get("activeUsers")).toBe(2);
    expect(stats.get("answers")).toBe(16);
    expect(stats.get("correct")).toBe(8);
    expect(stats.get("diagnosticsCompleted")).toBe(2);
    const concept = await db.doc("subjects/first-aid/concepts/concept-0").get();
    expect(concept.get("learners")).toBe(2);
    expect(concept.get("masterySum")).toBeGreaterThan(0);
  }, 120000);

  it("nudges after two wrong attempts on the same concept", async () => {
    const result = (await call(1, "submitAnswer")({questionId: "question-0", chosen: "ب",
      ms: 1000, source: "khazna"})).data as {nudge: {conceptId: string; message: string} | null};
    expect(result.nudge?.conceptId).toBe("concept-0");
    expect(result.nudge?.message).toContain("مفهوم 0");
    const question = await db.doc("questions/question-0").get();
    expect(question.get("attempts")).toBe(3);
    expect(question.get("optionCounts.ب")).toBe(2);
  }, 30000);

  it("picks an unseen question and advances the saved daily plan", async () => {
    const next = (await call(1, "nextQuestion")({subjectId: "first-aid", conceptId: "concept-0"})).data as {
      question: {id: string} | null;
    };
    expect(next.question?.id).toBe("question-extra");
    await call(1, "submitAnswer")({questionId: "question-extra", chosen: "أ", ms: 1000, source: "plan"});
    const plan = (await call(1, "todayPlan")({subjectId: "first-aid"})).data as {
      items: {conceptId: string; done: number}[];
    };
    expect(plan.items.find((item) => item.conceptId === "concept-0")?.done).toBe(1);
  }, 30000);
});
