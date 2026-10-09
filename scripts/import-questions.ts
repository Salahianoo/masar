import {createHash} from "node:crypto";
import {readdir, readFile} from "node:fs/promises";
import {basename, join} from "node:path";
import {fileURLToPath} from "node:url";
import {accessToken} from "./cli-token.js";
import {commit, getDocument, write as putDoc} from "./firestore-rest.js";

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
type ConceptSource = {id: string; name: string; questions: string[]; explanation: string};
type ConceptFile = {
  subjects: Record<string, {name: string; file: string; concepts: ConceptSource[]; mentorNotes?: string}>;
  suspect: Record<string, Record<string, string>>;
};
type ImportConcept = {id: string; name: string; weight: number; explanation: string; order: number;
  learners: number; masterySum: number};

const pilotSubjects: Record<string, string> = {
  "ثقافة صحية و اسعافات أولية": "first-aid",
  "مقدمة في نظم قواعد البيانات": "databases",
  "التنمية و البيئة": "environment",
  "اخلاقيات حاسوب": "computer-ethics",
  "علوم عسكرية": "military-science",
};
const allowed = new Set(Object.values(pilotSubjects));
const pilotFiles = new Set(["aid-mid.json", "database-final.json", "env-mid.json",
  "ethics-mid.json", "military-mid.json"]);

function args() {
  const argv = process.argv.slice(2);
  const sourceDir = argv.find((part) => !part.startsWith("--")) ??
    fileURLToPath(new URL("./data/masar-5/", import.meta.url));
  const write = argv.includes("--write");
  const requested = argv.find((part) => part.startsWith("--subjects="))?.slice("--subjects=".length);
  if (write && argv.includes("--dry-run")) {
    throw new Error("Usage: npm run import -- [source-folder] [--dry-run|--write] [--subjects=first-aid,databases,...]");
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
  if (q.kind === "truefalse") {
    return truth(answer) ?? (matchingOriginal ? truth(String(matchingOriginal.text ?? "")) : undefined) ??
      (/^\d+$/.test(answer) ? truth(String(original[Number(answer) - 1]?.text ?? "")) : undefined);
  }
  return matchingOriginal ? options.find((option) => option.label === answer)?.label : undefined;
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
  const conceptFile = JSON.parse(await readFile(join(sourceDir, "concepts.json"), "utf8")) as ConceptFile;
  const files = (await readdir(sourceDir)).filter((file) => file.endsWith(".json") &&
    pilotFiles.has(file) && !file.startsWith("bench-") && file !== "test.json" &&
    !file.includes("DRAFT")).sort();
  const bySubject = new Map<string, {name: string; exams: ImportExam[]; questions: ImportQuestion[];
    concepts: ImportConcept[]; mentorNotes: string; skipped: number}>();
  for (const file of files) {
    const source = JSON.parse(await readFile(join(sourceDir, file), "utf8")) as SourceFile;
    const name = String(source.subjectName ?? "");
    const subjectId = pilotSubjects[name];
    if (!subjectId || !subjects.has(subjectId)) continue;
    const sourceConcepts = conceptFile.subjects[subjectId];
    if (!sourceConcepts || sourceConcepts.name !== name || sourceConcepts.file !== basename(file, ".json")) {
      throw new Error(`${file}: concepts.json does not match this paper`);
    }
    const conceptOf = new Map<string, string[]>();
    for (const concept of sourceConcepts.concepts) for (const key of concept.questions) {
      conceptOf.set(key, [...(conceptOf.get(key) ?? []), concept.id]);
    }
    const suspect = conceptFile.suspect[sourceConcepts.file] ?? {};
    const group = bySubject.get(subjectId) ?? {name, exams: [], questions: [], concepts: [],
      mentorNotes: sourceConcepts.mentorNotes ?? "", skipped: 0};
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
          console.warn(`Skipping ambiguous answer: ${file} section ${sectionIndex + 1} question ${String(q.number ?? position + 1)} (answer: ${String(q.answer)})`);
          continue;
        }
        const id = `${examId}-${position + 1}-${hash(text)}`;
        const key = `${sectionIndex}.${position}`;
        const conceptIds = conceptOf.get(key);
        if (!conceptIds?.length || conceptIds.length > 2) throw new Error(`${file} ${key}: missing or excessive concepts`);
        questions.push({id, answer, subjectId, examId, examLabel: label, kind: q.kind,
          text, options, conceptIds, difficulty: 0, attempts: 0, correctCount: 0,
          optionCounts: {}, flagged: Boolean(suspect[key])});
      }
      if (!questions.length) continue;
      group.exams.push({id: examId, subjectId, label, pdfUrl: null,
        questionCount: questions.length, order: group.exams.length});
      group.questions.push(...questions);
    }
    if (group.questions.length !== conceptOf.size) {
      throw new Error(`${file}: ${conceptOf.size} tagged questions but ${group.questions.length} usable questions`);
    }
    group.concepts = sourceConcepts.concepts.map((concept, order) => ({
      id: concept.id, name: concept.name, explanation: concept.explanation, order: order + 1,
      weight: group.questions.filter((question) => question.conceptIds[0] === concept.id).length / group.questions.length,
      learners: 0, masterySum: 0,
    }));
  }
  return bySubject;
}

async function main() {
  const {sourceDir, write, subjects} = args();
  const groups = await collect(sourceDir, subjects);
  for (const [id, group] of groups) {
    console.log(`${id}: ${group.exams.length} exams, ${group.questions.length} questions, ${group.concepts.length} concepts, ${group.questions.filter((q) => q.flagged).length} flagged, ${group.skipped} ambiguous skipped`);
  }
  if (!write) return;
  const token = await accessToken();
  for (const [id, group] of groups) {
    const writes = [];
    const subjectFields = {name: group.name, questionCount: group.questions.filter((q) => !q.flagged).length,
      conceptCount: group.concepts.length, active: true, mentorNotes: group.mentorNotes};
    writes.push(putDoc(`subjects/${id}`, subjectFields));
    for (const concept of group.concepts) {
      const path = `subjects/${id}/concepts/${concept.id}`;
      const existing = await getDocument(path, token);
      writes.push(existing ? putDoc(path, {weight: concept.weight, order: concept.order}, ["weight", "order"])
        : putDoc(path, concept));
    }
    for (const exam of group.exams) {
      const path = `exams/${exam.id}`;
      if (!(await getDocument(path, token))) writes.push(putDoc(path, exam));
    }
    for (const {id: questionId, answer, ...question} of group.questions) {
      const path = `questions/${questionId}`;
      const existing = await getDocument(path, token);
      if (existing) {
        writes.push(putDoc(path, {conceptIds: question.conceptIds,
          flagged: existing.fields?.flagged?.booleanValue === true || question.flagged}, ["conceptIds", "flagged"]));
        continue; // Preserve learned difficulty, attempts and answer keys.
      }
      writes.push(putDoc(path, question));
      writes.push(putDoc(`answerKeys/${questionId}`, {answer}));
    }
    await commit(writes, token);
    console.log(`Wrote ${id}`);
  }
}

main().catch((error: unknown) => {console.error(error); process.exitCode = 1;});
