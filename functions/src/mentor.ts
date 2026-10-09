import {getFirestore, type DocumentData} from "firebase-admin/firestore";
import {defineSecret} from "firebase-functions/params";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {inferMentorConcepts, mastery} from "./engine";

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

class PcTimeoutError extends Error {}

async function pcReply(system: string, messages: {role: string; text: string}[]): Promise<string> {
  const base = llmUrl.value();
  const token = llmToken.value();
  if (!base || !token) throw new HttpsError("failed-precondition", "المرشد غير مهيأ حالياً.");
  const url = new URL("chat/completions", base.endsWith("/") ? base : `${base}/`);
  const controller = new AbortController();
  let firstToken = false;
  const firstTimer = setTimeout(() => controller.abort(), 12000);
  const responseTimer = setTimeout(() => controller.abort(), 60000);
  try {
    const response = await fetch(url, {method: "POST", signal: controller.signal,
      headers: {"Content-Type": "application/json", "Authorization": `Bearer ${token}`},
      body: JSON.stringify({model: process.env.MASAR_LLM_MODEL ?? "Qwen3.5-9B", stream: true,
        messages: [{role: "system", content: system}, ...messages.map((message) => ({
          role: message.role === "mentor" ? "assistant" : "user", content: message.text,
        }))]})});
    if (!response.ok || !response.body) throw new Error(`PC model HTTP ${response.status}`);
    const reader = response.body.getReader();
    const decoder = new TextDecoder();
    let buffer = "";
    let reply = "";
    let reading = true;
    while (reading) {
      const {value, done} = await reader.read();
      if (done) {
        reading = false;
        continue;
      }
      buffer += decoder.decode(value, {stream: true});
      const lines = buffer.split("\n");
      buffer = lines.pop() ?? "";
      for (const line of lines) {
        if (!line.startsWith("data: ") || line === "data: [DONE]") continue;
        const parsed = JSON.parse(line.slice(6));
        const content = parsed.choices?.[0]?.delta?.content;
        if (typeof content === "string" && content) {
          if (!firstToken) {
            firstToken = true;
            clearTimeout(firstTimer);
          }
          reply += content;
        }
      }
    }
    if (!reply.trim()) throw new Error("Empty PC reply");
    return reply.trim();
  } catch (error) {
    if (!firstToken && controller.signal.aborted) throw new PcTimeoutError();
    throw error;
  } finally {
    clearTimeout(firstTimer);
    clearTimeout(responseTimer);
  }
}

async function cloudReply(system: string, messages: {role: string; text: string}[]): Promise<string> {
  const key = anthropicKey.value();
  if (!key) throw new HttpsError("failed-precondition", "المرشد غير مهيأ حالياً.");
  const response = await fetch("https://api.anthropic.com/v1/messages", {method: "POST",
    headers: {"Content-Type": "application/json", "x-api-key": key, "anthropic-version": "2023-06-01"},
    body: JSON.stringify({model: process.env.MENTOR_MODEL ?? "claude-haiku-5-5", max_tokens: 700,
      system, messages: messages.map((message) => ({
        role: message.role === "mentor" ? "assistant" : "user", content: message.text,
      }))})});
  if (!response.ok) throw new Error(`Cloud model HTTP ${response.status}`);
  const result = await response.json() as {content?: {type: string; text?: string}[]};
  const reply = result.content?.filter((item) => item.type === "text").map((item) => item.text ?? "").join(" ").trim();
  if (!reply) throw new Error("Empty cloud reply");
  return reply;
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
  const conversation = messages as {role: string; text: string}[];
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
  const limit = Number(config.get("dailyMentorLimit") ?? 30);
  if (Number(daily.get("count") ?? 0) >= limit) {
    throw new HttpsError("resource-exhausted", "خلصت رسائل المرشد لليوم. ارجع بكرا.");
  }
  const subjectQuestions = await db.collection("questions").where("subjectId", "==", subjectId).get();
  const conceptCandidates = concepts.docs.map((doc) => ({id: doc.id,
    name: String(doc.get("name") ?? ""), weight: Number(doc.get("weight") ?? 0),
    explanation: String(doc.get("explanation") ?? ""),
    questions: subjectQuestions.docs.filter((question) =>
      (question.get("conceptIds") as string[]).includes(doc.id)).map((question) => String(question.get("text") ?? "")),
  }));
  const selectedIds = conceptId ? [conceptId] : inferMentorConcepts(
    conversation[conversation.length - 1].text, conceptCandidates);
  const selectedConcepts = conceptCandidates.filter((candidate) => selectedIds.includes(candidate.id));
  const relevant = subjectQuestions.docs.filter((doc) =>
    (doc.get("conceptIds") as string[]).some((id) => selectedIds.includes(id)));
  const preferred = selectedIds.flatMap((id) => relevant.filter((doc) =>
    (doc.get("conceptIds") as string[]).includes(id)).slice(0, Math.ceil(6 / selectedIds.length)));
  const questionDocs = [...new Map([...preferred, ...relevant].map((doc) => [doc.id, doc])).values()].slice(0, 6);
  const answerDocs = questionDocs.length ? await db.getAll(...questionDocs.map((doc) =>
    db.doc(`answerKeys/${doc.id}`))) : [];
  const samples = questionDocs.map((doc, i) => ({question: doc.get("text"),
    options: doc.get("options"), answer: answerDocs[i]?.get("answer")}));
  const rawStates = dataObject(masteryDoc.get("concepts"));
  const weakest = Object.entries(rawStates).map(([id, value]) => {
    const state = dataObject(value);
    return {id, value: Number(state.attempts ?? 0) > 0 ? mastery(Number(state.theta ?? -1)) : 0};
  }).filter((item) => conceptCandidates.some((candidate) => candidate.id === item.id))
    .sort((a, b) => a.value - b.value).slice(0, 3).map((item) => ({
      name: conceptCandidates.find((candidate) => candidate.id === item.id)?.name,
      mastery: item.value,
    }));
  const grounding = selectedConcepts.length ? [
    `المفاهيم: ${JSON.stringify(selectedConcepts.map((item) => ({
      name: item.name, weight: item.weight, explanation: item.explanation,
    })))}.`,
    `أسئلة وإجابات من هذه المفاهيم: ${JSON.stringify(samples)}.`,
  ] : [
    `نظرة المادة: ${JSON.stringify(conceptCandidates.map((item) => ({name: item.name, weight: item.weight})))}.`,
    `أضعف ثلاثة مفاهيم لدى الطالب: ${JSON.stringify(weakest)}.`,
  ];
  const system = [
    "أنت مرشد مسار التعليمي. أجب بالعربية بلهجة أردنية ودودة وباختصار (حتى 150 كلمة إلا إذا طلب الطالب المزيد).",
    "التزم بالمادة المحددة فقط وارفض بلطف أي موضوع خارجها. لا تخترع حقائق خارج المواد المعطاة.",
    `المادة: ${subject.get("name")}.`,
    ...grounding,
  ].join("\n");
  let source = String(config.get("mentorSource") ?? "cloud");
  if (source !== "pc" && source !== "cloud") {
    throw new HttpsError("failed-precondition", "مصدر المرشد غير صحيح.");
  }
  let reply: string;
  try {
    if (source === "pc") {
      try {
        reply = await pcReply(system, conversation);
      } catch (error) {
        if (!(error instanceof PcTimeoutError) || process.env.MENTOR_FALLBACK !== "cloud") throw error;
        source = "cloud";
        reply = await cloudReply(system, conversation);
      }
    } else {
      reply = await cloudReply(system, conversation);
    }
  } catch (error) {
    if (error instanceof HttpsError) throw error;
    throw new HttpsError("failed-precondition", "المرشد مش متاح حالياً. جرّب بعد شوي.");
  }
  const dailyRef = db.doc(`users/${uid}/mentorDaily/${day()}`);
  const statsRef = db.doc(`statsDaily/${day()}`);
  await db.runTransaction(async (tx) => {
    const [dailyDoc, statsDoc] = await Promise.all([tx.get(dailyRef), tx.get(statsRef)]);
    const count = Number(dailyDoc.get("count") ?? 0);
    if (count >= limit) throw new HttpsError("resource-exhausted", "خلصت رسائل المرشد لليوم. ارجع بكرا.");
    tx.set(dailyRef, {count: count + 1});
    const stats = statsShape(statsDoc.data());
    stats.mentorMessages++;
    stats.mentorBySource[source as "pc" | "cloud"]++;
    tx.set(statsRef, stats);
  });
  return {reply};
});
