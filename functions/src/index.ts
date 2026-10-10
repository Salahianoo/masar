import {initializeApp} from "firebase-admin/app";
import {getFirestore, Timestamp, type DocumentData} from "firebase-admin/firestore";
import {setGlobalOptions} from "firebase-functions/v2";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {
  buildPlan, mastery, pickDiagnostic, pickNextQuestion, projectedReadiness,
  readiness, status, updateAbility, updateDifficulty,
  type CandidateQuestion, type ConceptState, type WeightedConcept,
} from "./engine";

initializeApp();
const db = getFirestore();
setGlobalOptions({region: "europe-west1", maxInstances: 10});

const fail = (code: "invalid-argument" | "not-found" | "failed-precondition" | "resource-exhausted", message: string): never => {
  throw new HttpsError(code, message);
};
const uidOf = (auth: {uid: string} | undefined): string => {
  if (!auth) throw new HttpsError("unauthenticated", "سجّل دخولك أولاً.");
  return auth.uid;
};
const object = (value: unknown): Record<string, unknown> =>
  value && typeof value === "object" && !Array.isArray(value) ? value as Record<string, unknown> : {};
const string = (value: unknown): string => typeof value === "string" ? value.trim() : "";
const today = (): string => new Intl.DateTimeFormat("en-CA", {
  timeZone: "Asia/Amman", year: "numeric", month: "2-digit", day: "2-digit",
}).format(new Date());
const dayOf = (date: Date): string => new Intl.DateTimeFormat("en-CA", {
  timeZone: "Asia/Amman", year: "numeric", month: "2-digit", day: "2-digit",
}).format(date);
const dayDiff = (end: string, start: string): number =>
  Math.max(0, Math.ceil((Date.parse(`${end}T00:00:00Z`) - Date.parse(`${start}T00:00:00Z`)) / 86400000));
const dateFrom = (value: unknown): Date | undefined => value instanceof Timestamp ? value.toDate() : undefined;
const initialState = (): ConceptState => ({theta: -1, attempts: 0, correct: 0, recent: []});
const readStates = (data: DocumentData | undefined): Record<string, ConceptState> => {
  const raw = object(data?.concepts);
  return Object.fromEntries(Object.entries(raw).map(([id, value]) => {
    const item = object(value);
    return [id, {
      theta: typeof item.theta === "number" ? item.theta : -1,
      attempts: typeof item.attempts === "number" ? item.attempts : 0,
      correct: typeof item.correct === "number" ? item.correct : 0,
      recent: Array.isArray(item.recent) ? item.recent.filter((v): v is boolean => typeof v === "boolean").slice(-3) : [],
      lastSeen: dateFrom(item.lastSeen),
    }];
  }));
};
const writeStates = (states: Record<string, ConceptState>): DocumentData =>
  Object.fromEntries(Object.entries(states).map(([id, state]) => [id, {
    theta: state.theta, attempts: state.attempts, correct: state.correct,
    recent: state.recent, lastSeen: state.lastSeen ? Timestamp.fromDate(state.lastSeen) : null,
  }]));
const conceptList = (docs: FirebaseFirestore.QueryDocumentSnapshot[]): WeightedConcept[] =>
  docs.map((doc) => ({id: doc.id, name: String(doc.get("name") ?? ""),
    weight: Number(doc.get("weight") ?? 0), order: Number(doc.get("order") ?? 0)}));
const clientQuestion = (id: string, data: DocumentData): DocumentData => ({
  id, subjectId: data.subjectId, examId: data.examId, examLabel: data.examLabel,
  kind: data.kind, text: data.text, options: data.options, conceptIds: data.conceptIds,
});
const candidate = (doc: FirebaseFirestore.QueryDocumentSnapshot): CandidateQuestion => ({
  id: doc.id, examId: String(doc.get("examId") ?? ""),
  difficulty: Number(doc.get("difficulty") ?? 0), conceptIds: doc.get("conceptIds") ?? [],
});
const progress = (subjectId: string, concepts: WeightedConcept[], states: Record<string, ConceptState>, examDate: Date) => {
  const value = readiness(concepts, states);
  return {subjectId, readiness: value, projectedReadiness: projectedReadiness(value, dayDiff(dayOf(examDate), today())),
    concepts: [...concepts].sort((a, b) => b.weight - a.weight || a.order - b.order).map((concept) => {
      const state = states[concept.id] ?? initialState();
      const value = state.attempts ? mastery(state.theta) : 0;
      return {conceptId: concept.id, name: concept.name, weight: concept.weight,
        mastery: value, attempts: state.attempts, status: status(state.attempts, value)};
    })};
};
const baseStats = (data: DocumentData | undefined) => ({
  newUsers: Number(data?.newUsers ?? 0), activeUsers: Number(data?.activeUsers ?? 0),
  answers: Number(data?.answers ?? 0), correct: Number(data?.correct ?? 0),
  diagnosticsCompleted: Number(data?.diagnosticsCompleted ?? 0),
});
const requiredSubject = async (subjectId: string) => {
  const doc = await db.doc(`subjects/${subjectId}`).get();
  if (!doc.exists || doc.get("active") === false) fail("not-found", "المادة غير متاحة.");
  return doc;
};
const requiredEnrollment = async (uid: string, subjectId: string) => {
  const doc = await db.doc(`users/${uid}/enrollments/${subjectId}`).get();
  if (!doc.exists) fail("failed-precondition", "سجّل المادة أولاً.");
  return doc;
};

/** A free 5-digit student number (10000–99999), reserved in studentIds/{n}
 *  inside the same transaction that writes the student, so two students can
 *  never hold the same number. */
const STUDENT_ID_ATTEMPTS = 12;
const randomStudentId = () => String(10000 + Math.floor(Math.random() * 90000));

export const updateProfile = onCall(async (request) => {
  const uid = uidOf(request.auth);
  const displayName = string(object(request.data).displayName);
  if (!displayName || displayName.length > 80) fail("invalid-argument", "اكتب اسمك بشكل صحيح.");
  const userRef = db.doc(`users/${uid}`);
  const statsRef = db.doc(`statsDaily/${today()}`);
  // Pick candidates outside the transaction; the transaction re-reads them.
  const candidates = Array.from({length: STUDENT_ID_ATTEMPTS}, randomStudentId);
  const studentId = await db.runTransaction(async (tx) => {
    const [user, statsDoc, ...taken] = await Promise.all([tx.get(userRef), tx.get(statsRef),
      ...candidates.map((id) => tx.get(db.doc(`studentIds/${id}`)))]);
    const isNew = !user.exists;
    let id = user.get("studentId") as string | undefined;
    if (!id) {
      id = candidates.find((_, i) => !taken[i].exists);
      if (!id) fail("resource-exhausted", "صار ضغط على التسجيل، جرّب كمان مرة.");
      tx.create(db.doc(`studentIds/${id}`), {uid, createdAt: Timestamp.now()});
    }
    // The sign-in email and provider come from the verified auth token, never
    // from the client, so the admin dashboard can tell students apart.
    const token = request.auth?.token as {email?: string; firebase?: {sign_in_provider?: string}} | undefined;
    tx.set(userRef, {displayName, studentId: id, createdAt: user.get("createdAt") ?? Timestamp.now(),
      lastActiveAt: user.get("lastActiveAt") ?? Timestamp.now(),
      lastActiveDay: user.get("lastActiveDay") ?? "",
      email: token?.email ?? null,
      signInProvider: token?.firebase?.sign_in_provider ?? null}, {merge: true});
    if (isNew) {
      const stats = baseStats(statsDoc.data());
      stats.newUsers++;
      tx.set(statsRef, stats);
    }
    return id;
  });
  return {ok: true, studentId};
});

export const enroll = onCall(async (request) => {
  const uid = uidOf(request.auth);
  const data = object(request.data);
  const subjectId = string(data.subjectId);
  const examDate = string(data.examDate);
  const parsed = /^\d{4}-\d{2}-\d{2}$/.test(examDate) ? new Date(`${examDate}T00:00:00Z`) : null;
  if (!subjectId || !/^\d{4}-\d{2}-\d{2}$/.test(examDate) ||
      !parsed || Number.isNaN(parsed.getTime()) || parsed.toISOString().slice(0, 10) !== examDate ||
      examDate <= today()) {
    fail("invalid-argument", "اختَر مادة وتاريخ امتحان مستقبلي صحيح.");
  }
  await requiredSubject(subjectId);
  const ref = db.doc(`users/${uid}/enrollments/${subjectId}`);
  await db.runTransaction(async (tx) => {
    const existing = await tx.get(ref);
    tx.set(ref, {subjectId, examDate: Timestamp.fromDate(new Date(`${examDate}T09:00:00Z`)),
      diagnosticDone: existing.get("diagnosticDone") ?? false,
      readiness: existing.get("readiness") ?? 0,
      createdAt: existing.get("createdAt") ?? Timestamp.now()});
  });
  return {ok: true};
});

export const startDiagnostic = onCall(async (request) => {
  const uid = uidOf(request.auth);
  const subjectId = string(object(request.data).subjectId);
  if (!subjectId) fail("invalid-argument", "حدّد المادة.");
  await requiredEnrollment(uid, subjectId);
  const [concepts, questions] = await Promise.all([
    db.collection(`subjects/${subjectId}/concepts`).get(),
    db.collection("questions").where("subjectId", "==", subjectId).get(),
  ]);
  const available = questions.docs.filter((doc) => doc.get("flagged") !== true);
  const chosen = pickDiagnostic(conceptList(concepts.docs), available.map(candidate));
  if (!chosen.length || chosen.length !== Math.min(8, concepts.size)) {
    fail("failed-precondition", "ما في أسئلة كافية للتشخيص حالياً.");
  }
  const byId = new Map(available.map((doc) => [doc.id, doc]));
  return {questions: chosen.map((question) => clientQuestion(question.id, byId.get(question.id)!.data()))};
});

export const completeDiagnostic = onCall(async (request) => {
  const uid = uidOf(request.auth);
  const subjectId = string(object(request.data).subjectId);
  if (!subjectId) fail("invalid-argument", "حدّد المادة.");
  const enrollmentRef = db.doc(`users/${uid}/enrollments/${subjectId}`);
  const [enrollment, conceptDocs, attempts, masteryDoc] = await Promise.all([
    requiredEnrollment(uid, subjectId),
    db.collection(`subjects/${subjectId}/concepts`).get(),
    db.collection(`users/${uid}/attempts`).where("subjectId", "==", subjectId).where("source", "==", "diagnostic").get(),
    db.doc(`users/${uid}/mastery/${subjectId}`).get(),
  ]);
  const count = new Set(attempts.docs.map((doc) => doc.get("questionId"))).size;
  const expected = Math.min(8, conceptDocs.size);
  if (!expected || count < expected) fail("failed-precondition", "كمّل أسئلة التشخيص أولاً.");
  const statsRef = db.doc(`statsDaily/${today()}`);
  await db.runTransaction(async (tx) => {
    const [current, statsDoc] = await Promise.all([tx.get(enrollmentRef), tx.get(statsRef)]);
    if (!current.get("diagnosticDone")) {
      tx.update(enrollmentRef, {diagnosticDone: true});
      const stats = baseStats(statsDoc.data());
      stats.diagnosticsCompleted++;
      tx.set(statsRef, stats);
    }
  });
  return progress(subjectId, conceptList(conceptDocs.docs), readStates(masteryDoc.data()),
    dateFrom(enrollment.get("examDate")) ?? new Date());
});

export const todayPlan = onCall(async (request) => {
  const uid = uidOf(request.auth);
  const subjectId = string(object(request.data).subjectId);
  if (!subjectId) fail("invalid-argument", "حدّد المادة.");
  const [enrollment, conceptDocs, masteryDoc] = await Promise.all([
    requiredEnrollment(uid, subjectId),
    db.collection(`subjects/${subjectId}/concepts`).get(),
    db.doc(`users/${uid}/mastery/${subjectId}`).get(),
  ]);
  const examDate = dateFrom(enrollment.get("examDate")) ?? new Date();
  const daysLeft = dayDiff(dayOf(examDate), today());
  const concepts = conceptList(conceptDocs.docs);
  const states = readStates(masteryDoc.data());
  const ref = db.doc(`users/${uid}/plans/${subjectId}_${today()}`);
  const generated = buildPlan(concepts, states, daysLeft, new Date());
  const stored = await db.runTransaction(async (tx) => {
    const existing = await tx.get(ref);
    if (existing.exists) return existing.data()!;
    const plan = {...generated, completed: generated.items.length === 0};
    tx.create(ref, plan);
    return plan;
  });
  const byId = new Map(concepts.map((concept) => [concept.id, concept]));
  return {subjectId, daysLeft, minutes: stored.minutes, completed: stored.completed,
    items: stored.items.map((item: {conceptId: string; count: number; done: number; isReview: boolean}) => {
      const concept = byId.get(item.conceptId);
      const state = states[item.conceptId] ?? initialState();
      return {...item, conceptName: concept?.name ?? "", status: status(state.attempts,
        state.attempts ? mastery(state.theta) : 0)};
    })};
});

export const nextQuestion = onCall(async (request) => {
  const uid = uidOf(request.auth);
  const data = object(request.data);
  const subjectId = string(data.subjectId);
  let conceptId = string(data.conceptId);
  if (!subjectId) fail("invalid-argument", "حدّد المادة.");
  await requiredEnrollment(uid, subjectId);
  if (!conceptId) {
    const plan = await db.doc(`users/${uid}/plans/${subjectId}_${today()}`).get();
    if (!plan.exists) fail("failed-precondition", "اطلب خطة اليوم أولاً.");
    conceptId = (plan.get("items") as {conceptId: string; count: number; done: number}[])
      .find((item) => item.done < item.count)?.conceptId ?? "";
    if (!conceptId) return {question: null};
  }
  const conceptDoc = await db.doc(`subjects/${subjectId}/concepts/${conceptId}`).get();
  if (!conceptDoc.exists) fail("not-found", "المفهوم غير موجود.");
  const [questions, attempts, masteryDoc] = await Promise.all([
    db.collection("questions").where("conceptIds", "array-contains", conceptId).get(),
    db.collection(`users/${uid}/attempts`).where("at", ">=", Timestamp.fromMillis(Date.now() - 3 * 86400000)).get(),
    db.doc(`users/${uid}/mastery/${subjectId}`).get(),
  ]);
  const recent = new Set(attempts.docs.map((doc) => String(doc.get("questionId"))));
  const theta = readStates(masteryDoc.data())[conceptId]?.theta ?? -1;
  const available = questions.docs.filter((doc) => doc.get("subjectId") === subjectId && doc.get("flagged") !== true);
  const chosen = pickNextQuestion(available.map(candidate), theta, recent);
  const doc = questions.docs.find((item) => item.id === chosen?.id);
  return {question: doc ? clientQuestion(doc.id, doc.data()) : null};
});

export const submitAnswer = onCall(async (request) => {
  const uid = uidOf(request.auth);
  const data = object(request.data);
  const questionId = string(data.questionId);
  const chosen = string(data.chosen);
  const source = string(data.source);
  const ms = data.ms;
  if (!questionId || !chosen || !["diagnostic", "plan", "khazna"].includes(source) ||
      typeof ms !== "number" || !Number.isFinite(ms) || ms < 0 || ms > 3600000) {
    fail("invalid-argument", "بيانات الإجابة غير صحيحة.");
  }
  const questionRef = db.doc(`questions/${questionId}`);
  const answerRef = db.doc(`answerKeys/${questionId}`);
  return db.runTransaction(async (tx) => {
    const [q, a] = await Promise.all([tx.get(questionRef), tx.get(answerRef)]);
    if (!q.exists || !a.exists) fail("not-found", "السؤال غير موجود.");
    const currentQuestion = q.data()!;
    const subjectId = String(currentQuestion.subjectId);
    const conceptIds = currentQuestion.conceptIds as string[];
    if (!Array.isArray(conceptIds) || !conceptIds.length ||
        !Array.isArray(currentQuestion.options) ||
        !(currentQuestion.options as {label: string}[]).some((option) => option.label === chosen)) {
      fail("invalid-argument", "الخيار غير صحيح.");
    }
    const masteryRef = db.doc(`users/${uid}/mastery/${subjectId}`);
    const enrollmentRef = db.doc(`users/${uid}/enrollments/${subjectId}`);
    const userRef = db.doc(`users/${uid}`);
    const statsRef = db.doc(`statsDaily/${today()}`);
    const planRef = db.doc(`users/${uid}/plans/${subjectId}_${today()}`);
    const conceptRefs = conceptIds.map((id) => db.doc(`subjects/${subjectId}/concepts/${id}`));
    const correctAnswer = String(a.get("answer"));
    const isCorrect = chosen === correctAnswer;
    const [masteryDoc, enrollment, user, statsDoc, plan, ...conceptDocs] = await Promise.all([
      tx.get(masteryRef), tx.get(enrollmentRef),
      tx.get(userRef), tx.get(statsRef), tx.get(planRef), ...conceptRefs.map((ref) => tx.get(ref)),
    ]);
    if (!enrollment.exists) fail("failed-precondition", "سجّل المادة أولاً.");
    if (!user.exists) fail("failed-precondition", "أكمل ملفك أولاً.");
    if (source === "plan" && !plan.exists) fail("failed-precondition", "اطلب خطة اليوم أولاً.");
    if (conceptDocs.some((doc) => !doc.exists)) fail("failed-precondition", "مفاهيم السؤال غير مكتملة.");
    const states = readStates(masteryDoc.data());
    const beforeReadiness = Number(masteryDoc.get("readiness") ?? 0);
    const difficulty = Number(currentQuestion.difficulty ?? 0);
    const primaryTheta = states[conceptIds[0]]?.theta ?? -1;
    const previous: {attempts: number; mastery: number}[] = [];
    for (let i = 0; i < conceptIds.length; i++) {
      const id = conceptIds[i];
      const before = states[id] ?? initialState();
      previous.push({attempts: before.attempts, mastery: before.attempts ? mastery(before.theta) : 0});
      states[id] = {theta: updateAbility(before.theta, difficulty, before.attempts, isCorrect, i > 0),
        attempts: before.attempts + 1, correct: before.correct + Number(isCorrect),
        recent: [...before.recent, isCorrect].slice(-3), lastSeen: new Date()};
    }
    const conceptDocsForReadiness = await tx.get(db.collection(`subjects/${subjectId}/concepts`));
    const weighted = conceptList(conceptDocsForReadiness.docs);
    const newReadiness = readiness(weighted, states);
    const history = object(masteryDoc.get("history"));
    history[today()] = newReadiness;
    tx.set(masteryRef, {concepts: writeStates(states), readiness: newReadiness, history});
    tx.update(enrollmentRef, {readiness: newReadiness});
    const newDifficulty = updateDifficulty(primaryTheta, difficulty, isCorrect);
    const attempts = Number(currentQuestion.attempts ?? 0) + 1;
    const correctCount = Number(currentQuestion.correctCount ?? 0) + Number(isCorrect);
    const optionCounts = {...object(currentQuestion.optionCounts)} as Record<string, number>;
    optionCounts[chosen] = Number(optionCounts[chosen] ?? 0) + 1;
    const wrongMax = Math.max(0, ...Object.entries(optionCounts)
      .filter(([label]) => label !== correctAnswer).map(([, value]) => Number(value)));
    tx.update(questionRef, {difficulty: newDifficulty, attempts, correctCount, optionCounts,
      flagged: currentQuestion.flagged === true || (attempts >= 20 && correctCount / attempts < 0.25 && wrongMax / attempts >= 0.5)});
    for (let i = 0; i < conceptDocs.length; i++) {
      const before = previous[i];
      const after = mastery(states[conceptIds[i]].theta);
      tx.update(conceptRefs[i], {learners: Number(conceptDocs[i].get("learners") ?? 0) + Number(before.attempts === 0),
        masterySum: Number(conceptDocs[i].get("masterySum") ?? 0) + after - before.mastery});
    }
    if (source === "plan") {
      const items = (plan.get("items") as {conceptId: string; count: number; done: number; isReview: boolean}[])
        .map((item) => ({...item}));
      const item = items.find((entry) => entry.conceptId === conceptIds[0] && entry.done < entry.count) ??
        items.find((entry) => conceptIds.includes(entry.conceptId) && entry.done < entry.count);
      if (item) item.done++;
      tx.update(planRef, {items, completed: items.every((entry) => entry.done >= entry.count)});
    }
    const stats = baseStats(statsDoc.data());
    stats.answers++;
    stats.correct += Number(isCorrect);
    if (user.get("lastActiveDay") !== today()) stats.activeUsers++;
    tx.set(statsRef, stats);
    tx.update(userRef, {lastActiveAt: Timestamp.now(), lastActiveDay: today()});
    tx.create(db.collection(`users/${uid}/attempts`).doc(), {questionId, subjectId, conceptIds,
      chosen, correct: isCorrect, ms, source, at: Timestamp.now()});
    const updated = conceptIds.map((id) => {
      const concept = weighted.find((item) => item.id === id)!;
      const state = states[id];
      const value = mastery(state.theta);
      return {conceptId: id, name: concept.name, weight: concept.weight,
        mastery: value, attempts: state.attempts, status: status(state.attempts, value)};
    });
    return {correct: isCorrect, correctAnswer, readiness: newReadiness,
      readinessDelta: newReadiness - beforeReadiness, updated};
  });
});
