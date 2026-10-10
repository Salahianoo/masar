# Masar contract (current app)

Masar is an adaptive learning app for Jordanian university students. It uses five reviewed past-exam papers, 276 questions, and 34 concepts. Khazna remains an exam-bank tab. The old AI tutor was removed after the contest; no app or function in this source contacts the team's PC or Khazna's tutor.

## 1. Source layout

- `app/`: Flutter app, Clean Architecture (`core`, `domain`, `data`, `presentation`).
- `functions/`: Firebase callable functions and the learning engine.
- `admin/`: React/Vite dashboard.
- `scripts/data/masar-5/`: reviewed exam data and concept labels.
- `scripts/build-app-data.mjs`: generates the bundled local dataset and paper assets.

## 2. Student flow

Splash → three intro slides (once per device) → name-only anonymous sign-up → home → choose subject and exam date → eight-question diagnostic → concept map → daily plan and practice. The three swipeable tabs are مساري, خزنة, and أنا. The 5-digit student ID appears in the profile and dashboard.

## 3. Firebase data

- `users/{uid}`: student name, student ID, account metadata.
- `studentIds/{number}`: unique ID reservation.
- `users/{uid}/enrollments/{subjectId}`: exam date, diagnostic completion and readiness.
- `users/{uid}/mastery/{subjectId}`: per-concept ability and readiness history.
- `users/{uid}/attempts/{attemptId}`: answers and timestamps.
- `subjects/{subjectId}` and `subjects/{subjectId}/concepts/{conceptId}`: subject and concept metadata.
- `questions/{questionId}` and `exams/{examId}`: past-exam content.
- `statsDaily/{day}`: aggregate activity metrics. Historical tutor counts may remain in older records, but current code does not update them.

Only the app's Firebase project `masar-hackathon-jo-2026-salah` is in scope. Khazna's project is separate.

## 4. Callable API

`updateProfile`, `enroll`, `startDiagnostic`, `completeDiagnostic`, `todayPlan`, `nextQuestion`, and `submitAnswer`. The active source exports no tutor callable. `AnswerResult` includes correctness, the correct answer, readiness, delta and updated concept mastery.

## 5. Local mode

`flutter run --dart-define=LOCAL=true` uses the same real exam questions and learning formulas with SharedPreferences. The default uses Firebase. Neither mode needs a local language model.

## 6. Data integrity

Answers come only from the supplied exam papers. Six questions with suspect source keys are flagged and excluded from practice. Never silently change a source answer.

## 7. Learning engine

The same math runs in `functions/src/engine.ts` and `app/lib/domain/services/learning_engine.dart`.

```text
p       = 1 / (1 + exp(-(theta - b)))
r       = 1 if correct, 0 otherwise
K_s     = max(0.25, 0.8 / (1 + 0.15 * attempts))
theta  += K_s * (r - p) for each concept; secondary concepts get half the step
b      -= 0.05 * (r - p)
mastery = round(100 / (1 + exp(-theta)))
```

`theta` starts at -1, question difficulty `b` at 0. Unattempted concepts are unknown and contribute 0 to readiness. Mastery below 40 is weak, 40–69 medium, and 70+ strong. Readiness is the weighted sum of concept mastery. The daily plan prioritizes `weight × (1 − mastery/100)`, usually picks three concepts, and allocates 12–15 questions plus eligible review. The next question aims near `theta − 0.85`, skipping recent repeats.

## 8. Security and deployment

Never commit credentials. The released contest build is historical and may contain a temporary token; rotate the Khazna gate token before relying on old build secrecy. The current source has no tutor client, URL, or token. See `docs/REMOVAL-2026-10-10.md` for the remaining cloud cleanup blocked by the Masar project's billing status.
