/**
 * Builds the app's local dataset from the five demo papers, so the app runs
 * on real questions with no backend:
 *
 *   node scripts/build-app-data.mjs
 *
 * Reads   scripts/data/masar-5/{paper}.json + concepts.json
 * Writes  app/lib/data/datasources/local/local_data.g.dart  (generated, don't edit by hand)
 *         app/assets/papers/{paper}.pdf        (the Masar-branded papers for the Khazna tab)
 *
 * Same rules as scripts/import-questions.ts: only mcq/truefalse with an answer
 * that names one of the question's own options; nothing is solved or guessed.
 * Questions listed as suspect in concepts.json come through flagged, and the
 * app keeps them out of practice.
 */
import {copyFileSync, mkdirSync, readFileSync, writeFileSync} from "node:fs";
import {dirname, join} from "node:path";
import {fileURLToPath} from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const dataDir = join(root, "scripts/data/masar-5");
const out = join(root, "app/lib/data/datasources/local/local_data.g.dart");
const papersOut = join(root, "app/assets/papers");

const conceptsFile = JSON.parse(readFileSync(join(dataDir, "concepts.json"), "utf8"));

function normalize(value) {
  return String(value).trim().replace(/[\u064B-\u065F\u0670\u0640]/g, "")
    .replace(/[أإآ]/g, "ا").replace(/ة/g, "ه").replace(/ى/g, "ي")
    .replace(/[.،:؛!?؟\s]+/g, " ").trim().toLowerCase();
}

function truth(value) {
  const word = normalize(value);
  if (["صح", "صحيح", "صحيحه", "العباره صحيحه", "true"].includes(word)) return "صح";
  if (["خطا", "خاطئه", "العباره خاطئه", "غلط", "false"].includes(word)) return "خطأ";
  return undefined;
}

/** The answer as one of the question's own option labels, or undefined. */
function answerLabel(q, options) {
  if (q.answer == null || String(q.answer).trim() === "") return undefined;
  const answer = String(q.answer).trim();
  const original = Array.isArray(q.options) ? q.options : [];
  const match = original.find((o) => String(o.label).trim() === answer);
  if (q.kind === "truefalse") {
    return truth(answer) ?? (match ? truth(match.text) : undefined) ??
      (/^\d+$/.test(answer) ? truth(original[Number(answer) - 1]?.text ?? "") : undefined);
  }
  return match ? String(match.label).trim() : undefined;
}

/** Display text for the app: the papers' LaTeX-ish numbers as plain text. */
function display(text) {
  return String(text)
    .replace(/\$([^$]*)\$/g, (_, m) => m.replace(/\\_/g, "–").replace(/\\%/g, "%").replace(/\\/g, ""))
    .replace(/[ \t]+\n/g, "\n").trim();
}

function dart(value) {
  return "'" + String(value).replace(/\\/g, "\\\\").replace(/\$/g, "\\$").replace(/'/g, "\\'")
    .replace(/\r/g, "").replace(/\n/g, "\\n") + "'";
}

const subjects = [];
const concepts = [];
const exams = [];
const questions = [];
let order = 0;

for (const [subjectId, s] of Object.entries(conceptsFile.subjects)) {
  const paper = JSON.parse(readFileSync(join(dataDir, `${s.file}.json`), "utf8"));
  if (paper.subjectName !== s.name) throw new Error(`${s.file}: subject name mismatch`);
  const conceptOf = new Map();
  for (const c of s.concepts) {
    c.questions.forEach((key, i) => {
      const list = conceptOf.get(key) ?? [];
      list.push(c.id);
      conceptOf.set(key, list);
    });
  }
  const suspect = conceptsFile.suspect[s.file] ?? {};
  const examId = `${s.file}`;
  const examLabel = String(paper.examTypeLabel ?? "امتحان").trim();
  const subjectQuestions = [];
  paper.sections.forEach((section, si) => {
    section.questions.forEach((q, pi) => {
      if (q.kind !== "mcq" && q.kind !== "truefalse") return;
      const key = `${si}.${pi}`;
      const options = q.kind === "truefalse"
        ? [{label: "صح", text: "صح"}, {label: "خطأ", text: "خطأ"}]
        : (q.options ?? []).map((o) => ({label: String(o.label).trim(), text: display(o.text)}));
      const answer = answerLabel(q, options);
      if (!answer || !options.some((o) => o.label === answer)) return;
      const ids = conceptOf.get(key);
      if (!ids) throw new Error(`${s.file} ${key} has an answer but no concept`);
      subjectQuestions.push({
        id: `${s.file}-${si}-${pi}`, subjectId, examId, examLabel, kind: q.kind,
        text: display(q.text.replace(/^\s*معلومة:[\s\S]*?\n\s*\n/, "")), options, conceptIds: ids, answer,
        flagged: Boolean(suspect[key]),
      });
    });
  });
  const tagged = [...conceptOf.keys()].length;
  if (tagged !== subjectQuestions.length) {
    throw new Error(`${s.file}: ${tagged} tagged keys but ${subjectQuestions.length} usable questions`);
  }
  // Weight = share of the paper's questions whose primary concept this is.
  const primaryCount = new Map();
  for (const q of subjectQuestions) primaryCount.set(q.conceptIds[0], (primaryCount.get(q.conceptIds[0]) ?? 0) + 1);
  s.concepts.forEach((c, i) => concepts.push({
    id: c.id, subjectId, name: c.name, order: i + 1,
    weight: Number(((primaryCount.get(c.id) ?? 0) / subjectQuestions.length).toFixed(4)),
    explanation: c.explanation,
  }));
  subjects.push({id: subjectId, name: s.name, questionCount: subjectQuestions.filter((q) => !q.flagged).length,
    conceptCount: s.concepts.length, order: order++});
  exams.push({id: examId, subjectId, label: examLabel, pdfUrl: `asset:assets/papers/${s.file}.pdf`,
    questionCount: subjectQuestions.filter((q) => !q.flagged).length});
  questions.push(...subjectQuestions);
  mkdirSync(papersOut, {recursive: true});
  copyFileSync(join(dataDir, `${s.file}.pdf`), join(papersOut, `${s.file}.pdf`));
}

const L = [];
L.push("// GENERATED by scripts/build-app-data.mjs from scripts/data/masar-5/. Do not edit.");
L.push("// The five reviewed demo papers: real questions, answers only as the papers printed them.");
L.push("// ignore_for_file: lines_longer_than_80_chars");
L.push("");
L.push("import 'package:masar/domain/entities/entities.dart';");
L.push("import 'package:masar/data/models/local_question.dart';");
L.push("");
L.push("const localSubjects = <Subject>[");
for (const s of subjects) L.push(`  Subject(id: ${dart(s.id)}, name: ${dart(s.name)}, questionCount: ${s.questionCount}, conceptCount: ${s.conceptCount}),`);
L.push("];");
L.push("");
L.push("const localConcepts = <Concept>[");
for (const c of concepts) L.push(`  Concept(id: ${dart(c.id)}, subjectId: ${dart(c.subjectId)}, name: ${dart(c.name)}, weight: ${c.weight}, order: ${c.order}, explanation: ${dart(c.explanation)}),`);
L.push("];");
L.push("");
L.push("const localExams = <Exam>[");
for (const e of exams) L.push(`  Exam(id: ${dart(e.id)}, subjectId: ${dart(e.subjectId)}, label: ${dart(e.label)}, pdfUrl: ${dart(e.pdfUrl)}, questionCount: ${e.questionCount}),`);
L.push("];");
L.push("");
L.push("List<LocalQuestion> buildLocalQuestions() => [");
for (const q of questions) {
  const opts = q.options.map((o) => `QuestionOption(label: ${dart(o.label)}, text: ${dart(o.text)})`).join(", ");
  L.push(`  LocalQuestion(const Question(id: ${dart(q.id)}, subjectId: ${dart(q.subjectId)}, examId: ${dart(q.examId)}, examLabel: ${dart(q.examLabel)}, kind: QuestionKind.${q.kind}, text: ${dart(q.text)}, options: [${opts}], conceptIds: [${q.conceptIds.map(dart).join(", ")}]), ${dart(q.answer)}, 0${q.flagged ? ", flagged: true" : ""}),`);
}
L.push("];");
writeFileSync(out, L.join("\n") + "\n");

const flagged = questions.filter((q) => q.flagged).length;
for (const s of subjects) {
  console.log(`${s.id.padEnd(18)} ${s.questionCount} usable · ${s.conceptCount} concepts`);
}
console.log(`total ${questions.length} questions (${flagged} flagged, kept out of practice) → ${out}`);
