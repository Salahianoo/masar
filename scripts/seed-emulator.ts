import {initializeApp} from "firebase-admin/app";
import {getFirestore} from "firebase-admin/firestore";

if (!process.env.FIRESTORE_EMULATOR_HOST || !process.env.FIREBASE_AUTH_EMULATOR_HOST) {
  throw new Error("This seed only runs with Firestore and Auth emulators.");
}

const projectId = process.env.GCLOUD_PROJECT || process.env.GOOGLE_CLOUD_PROJECT || "demo-masar-backend";
initializeApp({projectId});
const db = getFirestore();
const batch = db.batch();
const subjectId = "first-aid";
const concepts = ["النزيف", "الكسور", "الإنعاش القلبي", "الضغط النفسي",
  "الحروق", "الاختناق", "الجروح", "الإغماء"];

batch.set(db.doc("config/app"), {
  mentorName: "رفيق", mentorEnabled: true, mentorSource: "cloud", dailyMentorLimit: 30,
});
batch.set(db.doc(`subjects/${subjectId}`), {
  name: "ثقافة صحية و اسعافات أولية", questionCount: 24, conceptCount: 8, active: true,
});
batch.set(db.doc("exams/first-aid-demo"), {
  subjectId, label: "تجربة محلية", pdfUrl: null, questionCount: 24, order: 0,
});
for (let i = 0; i < concepts.length; i++) {
  const conceptId = `demo-concept-${i + 1}`;
  batch.set(db.doc(`subjects/${subjectId}/concepts/${conceptId}`), {
    name: concepts[i], weight: 1 / concepts.length,
    explanation: `راجع أسئلة ${concepts[i]} لتثبيت الفكرة.`, order: i,
    learners: 0, masterySum: 0,
  });
  for (let j = 0; j < 3; j++) {
    const questionId = `demo-question-${i + 1}-${j + 1}`;
    batch.set(db.doc(`questions/${questionId}`), {
      subjectId, examId: "first-aid-demo", examLabel: "تجربة محلية",
      kind: "mcq", text: `سؤال تدريبي ${j + 1} عن ${concepts[i]}؟`,
      options: [{label: "أ", text: "الإجابة الصحيحة"}, {label: "ب", text: "إجابة أخرى"}],
      conceptIds: [conceptId], difficulty: 0, attempts: 0, correctCount: 0,
      optionCounts: {}, flagged: false,
    });
    batch.set(db.doc(`answerKeys/${questionId}`), {answer: "أ"});
  }
}
await batch.commit();
console.log(`Seeded local emulator ${projectId} with 1 subject, 8 concepts and 24 questions.`);
