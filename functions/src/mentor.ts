import {getFirestore, type DocumentData} from "firebase-admin/firestore";
import {defineSecret} from "firebase-functions/params";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {inferMentorConcepts, mastery, status} from "./engine";
import {approximateTokens, assembleMentorPrompt, formatGroundingQuestion,
  type GroundingQuestion} from "./mentor-prompt";
import {requestCloudReply, requestPcReply, resolveMentorReply,
  type MentorMessage, type MentorSource} from "./mentor-transport";

const llmUrl = defineSecret("MASAR_LLM_URL");
const llmToken = defineSecret("MASAR_LLM_TOKEN");
const anthropicKey = defineSecret("ANTHROPIC_API_KEY");
const day = (): string => new Intl.DateTimeFormat("en-CA", {
  timeZone: "Asia/Amman", year: "numeric", month: "2-digit", day: "2-digit",
}).format(new Date());
const dataObject = (value: unknown): Record<string, unknown> =>
  value && typeof value === "object" && !Array.isArray(value) ? value as Record<string, unknown> : {};
const statsShape = (data: DocumentData | undefined) => ({
  newUsers: Number(data?.newUsers ?? 0), activeUsers: Number(data?.activeUsers ?? 0),
  answers: Number(data?.answers ?? 0), correct: Number(data?.correct ?? 0),
  diagnosticsCompleted: Number(data?.diagnosticsCompleted ?? 0),
  mentorMessages: Number(data?.mentorMessages ?? 0),
  mentorBySource: {pc: Number(data?.mentorBySource?.pc ?? 0), cloud: Number(data?.mentorBySource?.cloud ?? 0)},
});

type SubjectConcept = {id: string; name: string; weight: number; explanation: string; questions: string[]};

function studentState(
  selected: SubjectConcept[],
  rawStates: Record<string, unknown>,
): string {
  const known = selected.flatMap((concept) => {
    const state = dataObject(rawStates[concept.id]);
    const attempts = Number(state.attempts ?? 0);
    if (!attempts) return [];
    const value = mastery(Number(state.theta ?? -1));
    const label = {unknown: "غير معروف", weak: "ضعيف", medium: "متوسط", strong: "قوي"}[status(attempts, value)];
    const recent = Array.isArray(state.recent) ? state.recent : [];
    const wrongTwice = recent.length >= 2 && recent[recent.length - 1] === false &&
      recent[recent.length - 2] === false;
    return [`${concept.name}: ${label} (${value}%)${wrongTwice ? "، غلط آخر سؤالين" : ""}`];
  });
  return known.length ? `مستوى الطالب بهاد المفهوم: ${known.join("؛ ")}.` : "غير معروف";
}

function overview(concepts: SubjectConcept[], rawStates: Record<string, unknown>): string {
  const names = concepts.map((concept) => `${concept.name} (${Math.round(concept.weight * 100)}%)`);
  const weakest = Object.entries(rawStates).flatMap(([id, value]) => {
    const concept = concepts.find((item) => item.id === id);
    const state = dataObject(value);
    if (!concept || !Number(state.attempts ?? 0)) return [];
    return [{name: concept.name, value: mastery(Number(state.theta ?? -1))}];
  }).sort((a, b) => a.value - b.value).slice(0, 3);
  return `مفاهيم المادة وأوزانها: ${names.join("، ")}.\n` +
    `أضعف ثلاثة مفاهيم لدى الطالب: ${weakest.length ? weakest.map((item) =>
      `${item.name} (${item.value}%)`).join("، ") : "غير معروف"}.`;
}

export const askMentor = onCall({region: "europe-west1", maxInstances: 1, concurrency: 1,
  secrets: [llmUrl, llmToken, anthropicKey]}, async (request) => {
  const db = getFirestore();
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "سجّل دخولك أولاً.");
  const input = dataObject(request.data);
  const subjectId = typeof input.subjectId === "string" ? input.subjectId.trim() : "";
  const conceptId = typeof input.conceptId === "string" ? input.conceptId.trim() : "";
  const messages = input.messages;
  if (!subjectId || !Array.isArray(messages) || !messages.length || messages.length > 12 ||
      !messages.every((item) => item && ["user", "mentor"].includes(item.role) &&
        typeof item.text === "string" && item.text.trim() && item.text.length <= 2000) ||
      messages[messages.length - 1].role !== "user") {
    throw new HttpsError("invalid-argument", "رسائل المرشد غير صحيحة.");
  }
  const conversation = messages as MentorMessage[];
  const [subject, enrollment, config, concepts, masteryDoc, daily] = await Promise.all([
    db.doc(`subjects/${subjectId}`).get(),
    db.doc(`users/${uid}/enrollments/${subjectId}`).get(),
    db.doc("config/app").get(),
    db.collection(`subjects/${subjectId}/concepts`).get(),
    db.doc(`users/${uid}/mastery/${subjectId}`).get(),
    db.doc(`users/${uid}/mentorDaily/${day()}`).get(),
  ]);
  if (!subject.exists || (conceptId && !concepts.docs.some((doc) => doc.id === conceptId))) {
    throw new HttpsError("not-found", "المادة أو المفهوم غير موجود.");
  }
  if (!enrollment.exists) throw new HttpsError("failed-precondition", "سجّل المادة أولاً.");
  if (!config.exists || config.get("mentorEnabled") !== true) {
    throw new HttpsError("failed-precondition", "المرشد غير متاح حالياً.");
  }
  const mentorName = String(config.get("mentorName") ?? "");
  if (!mentorName) throw new HttpsError("failed-precondition", "اسم المرشد غير مهيأ.");
  const limit = Number(config.get("dailyMentorLimit") ?? 30);
  if (Number(daily.get("count") ?? 0) >= limit) {
    throw new HttpsError("resource-exhausted", "خلصت رسائل المرشد لليوم. ارجع بكرا.");
  }
  const source = String(config.get("mentorSource") ?? "cloud");
  if (source !== "pc" && source !== "cloud") {
    throw new HttpsError("failed-precondition", "مصدر المرشد غير صحيح.");
  }
  const subjectQuestions = await db.collection("questions").where("subjectId", "==", subjectId).get();
  const candidates: SubjectConcept[] = concepts.docs.map((doc) => ({id: doc.id,
    name: String(doc.get("name") ?? ""), weight: Number(doc.get("weight") ?? 0),
    explanation: String(doc.get("explanation") ?? ""),
    questions: subjectQuestions.docs.filter((question) =>
      (question.get("conceptIds") as string[]).includes(doc.id)).map((question) => String(question.get("text") ?? "")),
  }));
  const selectedIds = conceptId ? [conceptId] : inferMentorConcepts(
    conversation[conversation.length - 1].text, candidates);
  const selected = selectedIds.map((id) => candidates.find((item) => item.id === id)!);
  const rawStates = dataObject(masteryDoc.get("concepts"));
  const relevant = subjectQuestions.docs.filter((doc) =>
    (doc.get("conceptIds") as string[]).some((id) => selectedIds.includes(id)));
  const preferred = selectedIds.flatMap((id) => relevant.filter((doc) =>
    (doc.get("conceptIds") as string[]).includes(id)).slice(0, Math.ceil(6 / selectedIds.length)));
  const questionDocs = [...new Map([...preferred, ...relevant].map((doc) => [doc.id, doc])).values()].slice(0, 6);
  const answerDocs = questionDocs.length ? await db.getAll(...questionDocs.map((doc) =>
    db.doc(`answerKeys/${doc.id}`))) : [];
  const questions: GroundingQuestion[] = questionDocs.flatMap((doc, i) => {
    const answer = answerDocs[i]?.get("answer");
    if (typeof answer !== "string") return [];
    return [{text: String(doc.get("text") ?? ""), options: doc.get("options") ?? [], answer}];
  });
  const conceptText = selected.length ? selected.map((item) =>
    `المفهوم: ${item.name}\nالشرح: ${item.explanation}`).join("\n\n") : overview(candidates, rawStates);
  const stateText = studentState(selected, rawStates);
  let history = conversation.slice(-12);
  let includedQuestions = [...questions];
  const assemble = () => assembleMentorPrompt({mentorName, subjectName: String(subject.get("name") ?? ""),
    studentState: stateText,
    grounding: [conceptText, ...includedQuestions.map(formatGroundingQuestion)].join("\n\n")});
  let system = assemble();
  while (approximateTokens(system, history) > 5500 && history.length > 1) history = history.slice(1);
  while (approximateTokens(system, history) > 5500 && includedQuestions.length) {
    includedQuestions = includedQuestions.slice(0, -1);
    system = assemble();
  }
  let result: {reply: string; source: MentorSource | null};
  try {
    result = await resolveMentorReply({source: source as MentorSource,
      fallbackToCloud: process.env.MENTOR_FALLBACK === "cloud",
      pc: () => {
        if (!llmUrl.value() || !llmToken.value()) {
          throw new HttpsError("failed-precondition", "المرشد غير مهيأ حالياً.");
        }
        return requestPcReply({baseUrl: llmUrl.value(), token: llmToken.value(), system, messages: history});
      },
      cloud: () => {
        if (!anthropicKey.value()) throw new HttpsError("failed-precondition", "المرشد غير مهيأ حالياً.");
        return requestCloudReply({token: anthropicKey.value(),
          model: process.env.MENTOR_MODEL ?? "claude-haiku-5-5", system, messages: history});
      },
    });
  } catch (error) {
    if (error instanceof HttpsError) throw error;
    throw new HttpsError("failed-precondition", "المرشد مش متاح حالياً. جرّب بعد شوي.");
  }
  if (!result.source) return {reply: result.reply};
  const effectiveSource = result.source;
  const dailyRef = db.doc(`users/${uid}/mentorDaily/${day()}`);
  const statsRef = db.doc(`statsDaily/${day()}`);
  await db.runTransaction(async (tx) => {
    const [dailyDoc, statsDoc] = await Promise.all([tx.get(dailyRef), tx.get(statsRef)]);
    const count = Number(dailyDoc.get("count") ?? 0);
    if (count >= limit) throw new HttpsError("resource-exhausted", "خلصت رسائل المرشد لليوم. ارجع بكرا.");
    tx.set(dailyRef, {count: count + 1});
    const stats = statsShape(statsDoc.data());
    stats.mentorMessages++;
    stats.mentorBySource[effectiveSource]++;
    tx.set(statsRef, stats);
  });
  return {reply: result.reply};
});
