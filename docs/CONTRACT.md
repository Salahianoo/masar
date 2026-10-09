# Masar — shared team contract

> Every agent on the team reads this file first. It is the single source of truth for
> names, data shapes, function signatures and folder ownership. If your task needs
> something that isn't here, **do not invent a parallel version** — stop and tell your
> human, who agrees the change with the team and updates this file.

## 1. The product in one paragraph

Masar (مسار — working name, may change) is an adaptive learning app for Jordanian
university students, built for the "Education & learning" challenge: *"Students learn at
different paces with uneven access to support."* A student picks a subject and their exam
date, answers a short diagnostic (8 questions), and gets a **concept map** with a mastery %
per concept plus one **readiness %** for the exam. Every day the app builds a short plan
that targets the student's weakest concepts, weighted by how often each concept appears
in **real past exams**. After two mistakes in a row on the same concept, an AI **mentor**
(a 3D character, name TBD, read from config) steps in with an explanation. The question
bank comes from Khazna (خزنة), an existing past-exams app, which lives inside Masar as one
tab. Masar is a **separate product**: separate Firebase project, repo, branding and bot.
Nothing here touches Khazna's app, backend or data.

Language: Arabic UI, RTL, Jordanian-friendly tone. Code, identifiers and comments in English.

## 2. Team and ownership

| Person | Tool | Owns (only they edit these paths) |
|---|---|---|
| Salah | Codex | `functions/`, `admin/`, `scripts/`, `firestore.rules`, `firestore.indexes.json`, `firebase.json`, `app/lib/core/data/firebase_masar_repository.dart`, and all visuals: `design/**`, `app/assets/**` (icon, brand, mentor images) |
| Amer | Claude | `app/` shell: `app/lib/main.dart`, `app/lib/core/` (except the Firebase repository file), `app/lib/features/onboarding/`, `diagnostic/`, `map/`, `home/`, `profile/` |
| Osama | Claude | `app/lib/features/practice/`, `mentor/`, `khazna/`, `summary/` |

- One Git repo, `main` protected by convention. Work on your own branch (`salah/...`,
  `amer/...`, `osama/...`), merge small and often. `git pull --rebase` before every push.
- Need a change in a path you don't own? Ask its owner. Don't edit it yourself.
- `app/pubspec.yaml` belongs to Amer. Osama asks Amer to add packages.

## 3. Repo layout

```
masar/
  app/                      Flutter app (iOS + Android)
    lib/
      main.dart
      core/
        theme/              colors, typography, spacing (Amer)
        models/             the Dart models in section 6 (Amer)
        data/
          masar_repository.dart           interface, section 6 (Amer)
          mock_masar_repository.dart      in-memory fake (Amer)
          firebase_masar_repository.dart  real one (Salah)
        router.dart
        widgets/            shared widgets (Amer)
      features/
        onboarding/ diagnostic/ map/ home/ profile/      (Amer)
        practice/ mentor/ khazna/ summary/               (Osama)
  functions/                Cloud Functions, TypeScript, 2nd gen (Salah)
  admin/                    Admin dashboard, React + Vite + TS (Salah)
  scripts/                  import / tagging scripts, Node + TS (Salah)
  design/                   brand, icon, mentor sources and pitch visuals (Salah)
  docs/CONTRACT.md          this file
  firestore.rules  firestore.indexes.json  firebase.json
```

## 4. Firestore schema

All timestamps are Firestore `Timestamp`. Day keys are `yyyy-MM-dd` in Asia/Amman.

```
config/app
  mentorName: string            // the bot's display name, e.g. "TBD"
  mentorEnabled: bool
  mentorSource: "pc" | "cloud"  // where askMentor sends requests
  dailyMentorLimit: number      // messages per student per day, default 30

subjects/{subjectId}            // subjectId = short slug, e.g. "first-aid"
  name: string                  // Arabic name as shown in Khazna
  questionCount: number
  conceptCount: number
  active: bool

subjects/{subjectId}/concepts/{conceptId}   // conceptId = slug, e.g. "bleeding"
  name: string                  // Arabic, short ("النزيف")
  weight: number                // share of past-exam questions, 0..1; weights of one subject sum to 1
  explanation: string           // pre-generated, Arabic, Markdown, ≤ 1200 chars
  order: number
  learners: number              // students with ≥1 attempt   (functions maintain)
  masterySum: number            // sum of those students' mastery 0..100 (functions maintain)

exams/{examId}                  // one past paper, e.g. "first-aid-final-2024"
  subjectId, label: string      // label e.g. "نهائي 2024"
  pdfUrl: string | null
  questionCount: number
  order: number

questions/{questionId}
  subjectId, examId, examLabel: string
  kind: "mcq" | "truefalse"
  text: string
  options: [{ label: string, text: string }]   // mcq: أ ب ج د; truefalse: [{label:"صح"},{label:"خطأ"}] with text equal to label
  conceptIds: string[]          // 1–2, first is primary
  difficulty: number            // Elo b, starts 0   (functions maintain)
  attempts: number, correctCount: number        (functions maintain)
  optionCounts: { [label]: number }             (functions maintain)
  flagged: bool                 // suspected wrong answer key (functions / admin)

answerKeys/{questionId}         // NEVER readable by the app
  answer: string                // option label

users/{uid}
  displayName: string
  createdAt, lastActiveAt: Timestamp
  lastActiveDay: string

users/{uid}/enrollments/{subjectId}
  subjectId: string
  examDate: Timestamp
  diagnosticDone: bool
  readiness: number             // 0..100, mirrored from mastery doc for easy listing
  createdAt: Timestamp

users/{uid}/mastery/{subjectId}
  concepts: { [conceptId]: { theta: number, attempts: number, correct: number,
                             lastSeen: Timestamp, recent: bool[] /* last 3, newest last */ } }
  readiness: number
  history: { [dayKey]: number } // readiness at end of each active day

users/{uid}/attempts/{autoId}
  questionId, subjectId: string
  conceptIds: string[]
  chosen: string, correct: bool, ms: number
  source: "diagnostic" | "plan" | "khazna"
  at: Timestamp

users/{uid}/plans/{subjectId}_{dayKey}
  items: [{ conceptId, count, done, isReview }]
  minutes: number
  completed: bool

users/{uid}/mentorDaily/{dayKey}
  count: number

statsDaily/{dayKey}            // functions maintain, admin dashboard reads
  newUsers, activeUsers, answers, correct, diagnosticsCompleted, mentorMessages: number
  mentorBySource: { pc: number, cloud: number }

admins/{uid}                    // existence = admin access to the dashboard
```

### Access rules (summary — Salah implements in firestore.rules)
- Signed-in students **read**: `config/app`, `subjects/**`, `exams/**`, `questions/**`, and
  their own `users/{uid}/**`.
- Students **write nothing directly**. Every write goes through a callable function.
- `answerKeys/**` and `statsDaily/**`: admins and functions only.
- Admins (`admins/{uid}` exists) read everything and may write `config/app`,
  `subjects/**/concepts/**` (`name`, `explanation`, `weight`), and `questions/*.flagged`.

## 5. Cloud Functions (callable, region `europe-west1`)

Every callable requires auth (anonymous is fine). Errors use `HttpsError` codes:
`unauthenticated`, `invalid-argument`, `not-found`, `failed-precondition`,
`resource-exhausted` (mentor limit). The `message` is Arabic and safe to show the student.

| Name | Request | Response |
|---|---|---|
| `updateProfile` | `{ displayName }` | `{ ok: true }` |
| `enroll` | `{ subjectId, examDate /* ISO yyyy-MM-dd */ }` | `{ ok: true }` |
| `startDiagnostic` | `{ subjectId }` | `{ questions: Question[8] }` |
| `completeDiagnostic` | `{ subjectId }` | `SubjectProgress` |
| `todayPlan` | `{ subjectId }` | `TodayPlan` |
| `nextQuestion` | `{ subjectId, conceptId? }` | `{ question: Question \| null }` |
| `submitAnswer` | `{ questionId, chosen, ms, source }` | `AnswerResult` |
| `askMentor` | `{ subjectId, conceptId?, messages: ChatMessage[] /* ≤ 12 */ }` | `{ reply }` |

JSON field names are exactly the Dart field names in section 6. Dates go over the wire as
ISO strings.

## 6. Dart models and repository interface (app)

Amer creates these files exactly as written (plus `fromJson`/`toJson`). Osama codes against
the same names. Salah's Firebase repository implements the interface.

```dart
enum QuestionKind { mcq, truefalse }
enum MasteryStatus { unknown, weak, medium, strong }   // see section 7 for thresholds
enum AnswerSource { diagnostic, plan, khazna }

class AppConfig { final String mentorName; final bool mentorEnabled; }
class UserProfile { final String uid; final String displayName; }
class Subject { final String id; final String name; final int questionCount; final int conceptCount; }
class Concept { final String id; final String subjectId; final String name;
                final double weight; final String explanation; final int order; }
class QuestionOption { final String label; final String text; }
class Question { final String id; final String subjectId; final String examId; final String examLabel;
                 final QuestionKind kind; final String text; final List<QuestionOption> options;
                 final List<String> conceptIds; }
class Enrollment { final String subjectId; final DateTime examDate; final bool diagnosticDone;
                   final int readiness; int get daysLeft; }
class ConceptMastery { final String conceptId; final String name; final double weight;
                       final int mastery; final int attempts; final MasteryStatus status; }
class SubjectProgress { final String subjectId; final int readiness; final int projectedReadiness;
                        final List<ConceptMastery> concepts; }   // sorted by weight desc
class PlanItem { final String conceptId; final String conceptName; final int count; final int done;
                 final bool isReview; final MasteryStatus status; }
class TodayPlan { final String subjectId; final int daysLeft; final int minutes;
                  final List<PlanItem> items; final bool completed; }
class MentorNudge { final String conceptId; final String conceptName; final String message; }
class AnswerResult { final bool correct; final String correctAnswer; final int readiness;
                     final int readinessDelta; final List<ConceptMastery> updated; final MentorNudge? nudge; }
class ChatMessage { final String role; /* "user" | "mentor" */ final String text; }
class Exam { final String id; final String subjectId; final String label; final String? pdfUrl;
             final int questionCount; }
class ReadinessPoint { final DateTime day; final int readiness; }

abstract class MasarRepository {
  Future<void> signIn();                                  // anonymous auth
  Future<UserProfile?> currentProfile();
  Future<void> updateProfile(String displayName);
  Future<AppConfig> config();
  Future<List<Subject>> subjects();
  Future<List<Concept>> concepts(String subjectId);
  Future<void> enroll(String subjectId, DateTime examDate);
  Future<List<Enrollment>> enrollments();
  Stream<SubjectProgress> progress(String subjectId);    // live, from users/{uid}/mastery
  Future<List<Question>> startDiagnostic(String subjectId);
  Future<SubjectProgress> completeDiagnostic(String subjectId);
  Future<TodayPlan> todayPlan(String subjectId);
  Future<Question?> nextQuestion(String subjectId, {String? conceptId});
  Future<AnswerResult> submitAnswer({required String questionId, required String chosen,
                                     required int ms, required AnswerSource source});
  Future<List<Exam>> exams(String subjectId);
  Future<List<Question>> examQuestions(String examId);   // ordered by question order in the paper
  Future<String> askMentor({required String subjectId, String? conceptId,
                            required List<ChatMessage> messages});
  Future<List<ReadinessPoint>> readinessHistory(String subjectId);
}
```

The app picks the implementation at startup:
`flutter run --dart-define=MOCK=true` → `MockMasarRepository`, otherwise Firebase.
The mock must behave like the real thing (section 7 math, Arabic sample data for one
subject with ~8 concepts and ~40 questions), so UI work never waits on the backend.

State management: `flutter_riverpod`. Navigation: `go_router`. PDF: `syncfusion_flutter_pdfviewer`.

## 7. The learning engine (same math in functions and in the mock)

**Ability per concept.** Each student has `theta` per concept (starts at **-1.0**). Each
question has `difficulty` b (starts 0).

```
p        = 1 / (1 + exp(-(theta - b)))          // chance of answering correctly
r        = 1 if correct else 0
K_s      = max(0.25, 0.8 / (1 + 0.15 * attempts))   // student step, shrinks with practice
theta   += K_s * (r - p)        for every concept in question.conceptIds (secondary concepts: half step)
b       -= 0.05 * (r - p)       // questions learn from all students, slowly
mastery  = round(100 / (1 + exp(-theta)))      // 0..100
```

**Status.** `attempts == 0` → `unknown` · mastery < 40 → `weak` · 40–69 → `medium` · ≥ 70 → `strong`.
Colors: unknown = gray, weak = red, medium = amber, strong = green.

**Readiness.** `readiness = round(Σ weight_c × mastery_c)` over all concepts; unknown
concepts count as 0. `projectedReadiness = min(90, readiness + 7 × daysLeft)` (shown as an
estimate, "إذا مشيت على الخطة").

**Diagnostic.** 8 questions: the 8 highest-weight concepts (or all if fewer), one question
each, `difficulty` closest to 0, mcq/truefalse only, from different exams where possible.

**Today's plan.** `priority_c = weight_c × (1 − mastery_c/100)` (unknown → `weight_c`).
Budget = 15 questions/day (12 if daysLeft > 14). Take the top 3 concepts by priority, split
the budget proportionally (minimum 2 each), then add up to 2 review questions (`isReview`)
from `strong` concepts not seen for ≥ 2 days. `minutes = round(totalQuestions × 1.3)`.
The plan is created once per day and stored; `done` counts go up with each `plan` answer.

**Next question.** For the chosen concept, pick the question whose `difficulty` is closest
to `theta − 0.85` (≈ 70% success chance), skipping questions this student answered in the
last 3 days.

**Mentor nudge.** If the student's last 2 attempts on the same concept are both wrong,
`AnswerResult.nudge` is set: `"شكلك ملخبط شوي بـ{conceptName}. بدك أشرحلك بدقيقة؟"`.

## 8. The mentor (askMentor)

- Grounding: the concept's `explanation` + up to 6 questions of that concept **with** their
  answers (from `answerKeys`), + subject name. Answer only about the subject; politely refuse
  anything else. Arabic, Jordanian-friendly, short (≤ 150 words unless asked for more).
- Source from `config/app.mentorSource`:
  - `pc` → OpenAI-compatible endpoint on the team PC (LM Studio, Qwen3.5-9B, 8k context,
    one request at a time). **Its own tunnel hostname and token**, secrets
    `MASAR_LLM_URL`, `MASAR_LLM_TOKEN`. Never reuse Khazna's.
  - `cloud` → Anthropic API, secret `ANTHROPIC_API_KEY`, model from env `MENTOR_MODEL`
    (default `claude-haiku-5-5`). A hard monthly spend limit is set in the Anthropic console.
  - If `pc` times out (12 s to first token), fall back to `cloud` only when env
    `MENTOR_FALLBACK=cloud`.
- Limit: `config/app.dailyMentorLimit` per student per day → `resource-exhausted`.
- For the hackathon demo, `mentorSource = cloud`.

## 9. Data source

Questions come from a **snapshot copy** of Khazna's extracted exams
(`Exam-Vault-Agent/out/*.json` on Salah's Mac). Only questions with an answer are imported.
Pilot subjects for the demo: ثقافة صحية و اسعافات أولية, مقدمة في نظم قواعد البيانات,
التنمية و البيئة, مهارات حياتية. Concepts, weights and explanations are generated once by
`scripts/` with an LLM and reviewed by a human before the demo.

## 10. Definition of done for the demo

1. Fresh install → name → pick subject + exam date → 8-question diagnostic → map with readiness.
2. Two phones answering the same diagnostic differently show **different maps and plans**.
3. Practice: correct answer moves readiness up live; two wrong answers on one concept bring the mentor.
4. Khazna tab: open a past paper as PDF, tap «حلّه كاختبار», answers update the map.
5. Admin dashboard shows the two demo students live: readiness, weakest concepts, activity.
