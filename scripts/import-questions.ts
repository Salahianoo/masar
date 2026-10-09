import {createHash} from "node:crypto";
import {readdir, readFile} from "node:fs/promises";
import {basename, join} from "node:path";
import {initializeApp, applicationDefault} from "firebase-admin/app";
import {getFirestore} from "firebase-admin/firestore";

type SourceOption = {label?: unknown; text?: unknown};
type SourceQuestion = {
  number?: unknown; text?: unknown; kind?: unknown; options?: SourceOption[];
  answer?: unknown;
};
type SourceSection = {title?: unknown; questions?: SourceQuestion[]};
type SourceFile = {
  subjectName?: unknown; examTypeLabel?: unknown; year?: unknown;
  sections?: SourceSection[];
};
type ImportQuestion = {
  id: string; answer: string; subjectId: string; examId: string; examLabel: string;
  kind: "mcq" | "truefalse"; text: string;
  options: {label: string; text: string}[];
  conceptIds: string[]; difficulty: number; attempts: number; correctCount: number;
  optionCounts: Record<string, number>; flagged: boolean;
};
type ImportExam = {id: string; subjectId: string; label: string; pdfUrl: null; questionCount: number; order: number};

const pilotSubjects: Record<string, string> = {
  "ثقافة صحية و اسعافات أولية": "first-aid",
  "مقدمة في نظم قواعد البيانات": "database-intro",
  "التنمية و البيئة": "environment-development",
  "مهارات حياتية": "life-skills",
};
const allowed = new Set(Object.values(pilotSubjects));

function args() {
  const argv = process.argv.slice(2);
  const sourceDir = argv.find((part) => !part.startsWith("--"));
  const write = argv.includes("--write");
  const requested = argv.find((part) => part.startsWith("--subjects="))?.slice("--subjects=".length);
  if (!sourceDir || (write && argv.includes("--dry-run"))) {
    throw new Error("Usage: npm run import -- <source-folder> [--dry-run|--write] [--subjects=first-aid,database-intro,...]");
  }
  const subjects = new Set(requested ? requested.split(",") : allowed);
  for (const subject of subjects) if (!allowed.has(subject)) throw new Error(`Not a pilot subject: ${subject}`);
  return {sourceDir, write, subjects};
}

function normalize(value: string): string {
  return value.trim().replace(/[\u064B-\u065F\u0670\u0640]/g, "")
    .replace(/[أإآ]/g, "ا").replace(/ة/g, "ه").replace(/ى/g, "ي")
    .replace(/[.،:؛!?؟\s]+/g, " ").trim().toLowerCase();
}

function truth(value: string): string | undefined {
  const word = normalize(value);
  if (["صح", "صحيح", "صحيحه", "العباره صحيحه", "true"].includes(word)) return "صح";
  if (["خطا", "خاطئه", "العباره خاطئه", "غلط", "false"].includes(word)) return "خطأ";
  return undefined;
}

function answerLabel(q: SourceQuestion, options: {label: string; text: string}[]): string | undefined {
  if (typeof q.answer !== "string" && typeof q.answer !== "number") return undefined;
  const answer = String(q.answer).trim();
  const original = Array.isArray(q.options) ? q.options : [];
  const matchingOriginal = original.find((option) => String(option.label).trim() === answer);
  const index = original.findIndex((option) => option === matchingOriginal);
  if (q.kind === "truefalse") {
    const fromValue = truth(answer) ?? (matchingOriginal ? truth(String(matchingOriginal.text ?? "")) : undefined);
    if (fromValue) return fromValue;
    if (/^\d+$/.test(answer)) return truth(String(original[Number(answer) - 1]?.text ?? ""));
    return undefined;
  }
  if (matchingOriginal && index >= 0) return options[index]?.label;
  if (/^\d+$/.test(answer)) return options[Number(answer) - 1]?.label;
  if (/^[a-e]$/i.test(answer)) return options[answer.toLowerCase().charCodeAt(0) - 97]?.label;
  return options.find((option) => normalize(option.text) === normalize(answer))?.label;
}

function questionOptions(q: SourceQuestion): {label: string; text: string}[] {
  if (q.kind === "truefalse") return [{label: "صح", text: "صح"}, {label: "خطأ", text: "خطأ"}];
  if (!Array.isArray(q.options)) return [];
  return q.options.map((option) => ({label: String(option.label ?? "").trim(), text: String(option.text ?? "").trim()}));
}

function examLabel(source: SourceFile, section: SourceSection): string {
  const type = String(source.examTypeLabel ?? "امتحان").replace(/^ال?امتحان\s*/, "").trim() || "امتحان";
  const year = source.year ? ` ${String(source.year).trim()}` : "";
  const title = section.title ? ` · ${String(section.title).trim()}` : "";
  return `${type}${year}${title}`;
}

function hash(value: string): string {
  return createHash("sha256").update(value).digest("hex").slice(0, 12);
}

async function collect(sourceDir: string, subjects: Set<string>) {
  const files = (await readdir(sourceDir)).filter((file) => file.endsWith(".json") &&
    !file.startsWith("bench-") && file !== "test.json" && !file.includes("DRAFT")).sort();
  const bySubject = new Map<string, {name: string; exams: ImportExam[]; questions: ImportQuestion[]; skipped: number}>();
  for (const file of files) {
    const source = JSON.parse(await readFile(join(sourceDir, file), "utf8")) as SourceFile;
    const name = String(source.subjectName ?? "");
    const subjectId = pilotSubjects[name];
    if (!subjectId || !subjects.has(subjectId)) continue;
    const group = bySubject.get(subjectId) ?? {name, exams: [], questions: [], skipped: 0};
    bySubject.set(subjectId, group);
    const sections = Array.isArray(source.sections) ? source.sections : [];
    for (const [sectionIndex, section] of sections.entries()) {
      const examId = `${basename(file, ".json").replace(/[^a-zA-Z0-9-]+/g, "-")}-${sectionIndex + 1}`;
      const label = examLabel(source, section);
      const questions: ImportQuestion[] = [];
      for (const [position, q] of (section.questions ?? []).entries()) {
        if (q.kind !== "mcq" && q.kind !== "truefalse") continue;
        if (q.answer == null || String(q.answer).trim() === "") continue;
        const options = questionOptions(q);
        const answer = answerLabel(q, options);
        const text = String(q.text ?? "").trim();
        if (!text || !answer || options.length < 2 || options.some((option) => !option.label || !option.text) ||
            new Set(options.map((option) => option.label)).size !== options.length) {
          group.skipped++;
          console.warn(`Skipping ambiguous answer: ${file} section ${sectionIndex + 1} question ${String(q.number ?? position + 1)}`);
          continue;
        }
        const id = `${examId}-${position + 1}-${hash(text)}`;
        questions.push({id, answer, subjectId, examId, examLabel: label, kind: q.kind,
          text, options, conceptIds: [], difficulty: 0, attempts: 0, correctCount: 0,
          optionCounts: {}, flagged: false});
      }
      if (!questions.length) continue;
      group.exams.push({id: examId, subjectId, label, pdfUrl: null,
        questionCount: questions.length, order: group.exams.length});
      group.questions.push(...questions);
    }
  }
  return bySubject;
}

async function main() {
  const {sourceDir, write, subjects} = args();
  const groups = await collect(sourceDir, subjects);
  for (const [id, group] of groups) {
    console.log(`${id}: ${group.exams.length} exams, ${group.questions.length} questions, ${group.skipped} ambiguous skipped`);
  }
  if (!write) return;
  if (!process.env.GOOGLE_CLOUD_PROJECT) throw new Error("Set GOOGLE_CLOUD_PROJECT to the Masar project before --write");
  if (process.env.GOOGLE_CLOUD_PROJECT !== "masar-hackathon-jo-2026-salah" &&
      !process.env.FIRESTORE_EMULATOR_HOST) throw new Error("Refusing to write to a project other than Masar");
  initializeApp({credential: applicationDefault(), projectId: process.env.GOOGLE_CLOUD_PROJECT});
  const db = getFirestore();
  for (const [id, group] of groups) {
    const writer = db.bulkWriter();
    const subjectRef = db.doc(`subjects/${id}`);
    if (!(await subjectRef.get()).exists) writer.create(subjectRef, {name: group.name,
      questionCount: group.questions.length, conceptCount: 0, active: false});
    else writer.update(subjectRef, {questionCount: group.questions.length});
    for (const exam of group.exams) {
      const examRef = db.doc(`exams/${exam.id}`);
      if (!(await examRef.get()).exists) writer.create(examRef, exam);
    }
    for (const {id: questionId, answer, ...question} of group.questions) {
      const questionRef = db.doc(`questions/${questionId}`);
      const existing = await questionRef.get();
      if (existing.exists) continue; // Preserve attempts, concepts and any reviewed corrections on re-run.
      writer.create(questionRef, question);
      writer.create(db.doc(`answerKeys/${questionId}`), {answer});
    }
    await writer.close();
    console.log(`Wrote ${id}`);
  }
}

main().catch((error: unknown) => {console.error(error); process.exitCode = 1;});
