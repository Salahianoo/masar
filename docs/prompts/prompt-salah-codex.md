> **Repo:** https://github.com/Salahianoo/masar (private)
> ```
> git clone https://github.com/Salahianoo/masar.git
> ```
> The contract is at `docs/CONTRACT.md`. The root `CLAUDE.md` / `AGENTS.md` point every agent to it.

You are the backend and admin-dashboard engineer on a 3-person hackathon team building
**Masar**, an adaptive learning app. Your human is Salah. Before anything else, read
`docs/CONTRACT.md` in the repo. It is binding: use its names, schema, function signatures
and math exactly. If something you need is missing or wrong there, stop and tell Salah.
Don't invent a variant.

## Your ownership (edit only these)
`functions/`, `admin/`, `scripts/`, `firestore.rules`, `firestore.indexes.json`,
`firebase.json`, and the single app file `app/lib/core/data/firebase_masar_repository.dart`.
Amer and Osama own the rest of `app/`. Never touch Khazna / Exam-Vault repos or its
Firebase project. Masar is a separate Firebase project.

## Stack
- Firebase: Auth (anonymous for students, email/password for admins), Firestore,
  Cloud Functions 2nd gen in TypeScript (Node 22, region `europe-west1`), Hosting for the dashboard.
- Admin dashboard: React 19 + Vite + TypeScript + `firebase` web SDK + `react-router-dom`.
  Charts: `recharts`. Arabic RTL UI, clean and simple.
- Scripts: Node + TypeScript (`tsx`), `firebase-admin`.

## Work in this order. Commit after each step.

### 1. Firebase setup (first 30 min, then push)
The repo already exists with `docs/CONTRACT.md`, `AGENTS.md`, `CLAUDE.md`, `.gitignore` and
empty `app/ functions/ admin/ scripts/` folders. Don't recreate them.
- Create a **new** Firebase project for Masar (never Khazna's `hu-pp-q`). Add `.firebaserc`.
- From the repo root, `firebase init`: Firestore, Functions (TypeScript, in `functions/`),
  Hosting (public dir `admin/dist`, SPA rewrite), Emulators (auth, firestore, functions).
- Create the dashboard with `npm create vite@latest admin -- --template react-ts`.
- Set up `scripts/` as a small TS package (`tsx`, `firebase-admin`).
- Enable Anonymous and Email/Password sign-in. Create the first admin user and their
  `admins/{uid}` doc. Push, then tell Salah to share the Firebase config with Amer.

### 2. Import script: `scripts/import-questions.ts`
- Input: a folder of Khazna-shaped JSON files, by default **`scripts/data/masar-5/`** (the
  five reviewed demo papers, see CONTRACT §9). Skip `bench-*.json`, `test.json`, `*DRAFT*`.
- File shape: `{ subjectName, examTypeLabel, year?, language, sections: [{ title?, questions: [...] }] }`.
  Question: `{ number, text, kind, options?: [{label,text}], answer?, confidence }`.
  Kinds seen: mcq, truefalse, written, note, fill. **Import only mcq and truefalse that have an answer.**
- Normalize truefalse to options `[{label:"صح",text:"صح"},{label:"خطأ",text:"خطأ"}]`.
  The source answer may be `"صحيح"`/`"خطأ"` text, or a label like `"1"`/`"2"` that points
  into the question's own options. Map both. Log and skip anything ambiguous.
- `examId` = file slug + section index. `label` = Arabic, built from `examTypeLabel`, `year`
  and the section title, e.g. "نهائي 2024".
- Writes `subjects`, `exams`, `questions` (no answer field) and `answerKeys`. Run it with
  `--dry-run` (prints counts per subject) or `--write`. Re-running must not duplicate data
  (use deterministic ids).
- The subjectIds and exact names are in the CONTRACT §9 table. Skip answers that don't match an
  option label, and print them (aid-mid Q18 must show up in that list).

### 3. Concept tagging: `scripts/tag-concepts.ts`
For one subject:
1. Send all its questions (with answers) to an LLM. Ask for 8–20 concepts as JSON
   `[{id: slug, name: short Arabic}]`.
2. Tag every question with 1–2 conceptIds, in batches of ~40, using structured JSON output.
3. `weight_c` = the share of the subject's questions whose primary concept is c.
4. Generate `explanation` per concept: Arabic, Jordanian-friendly, ≤ 1200 chars, Markdown,
   grounded only in that concept's questions and answers.
5. Write a review file `scripts/out/{subjectId}-concepts.json` first. Write to Firestore
   only with `--write`, after Salah has reviewed it.
- LLM endpoint: OpenAI-compatible base URL + token from env (LM Studio on the team PC), or
  Anthropic (`ANTHROPIC_API_KEY`) with `--provider anthropic`. Retry on invalid JSON.

### 4. Cloud Functions: everything in CONTRACT §5, §7, §8
- Put the math from §7 in `functions/src/engine.ts` as pure functions and unit-test them
  (vitest): Elo update, mastery, status, readiness, plan builder, next-question pick, nudge.
- `submitAnswer` runs in one Firestore transaction. It reads `answerKeys`, updates the
  user's `mastery` doc (theta, attempts, recent, readiness, `history[today]`), the
  question's `difficulty`/`attempts`/`correctCount`/`optionCounts`, the concept's
  `learners`/`masterySum` (apply deltas), today's plan `done`, the enrollment `readiness`,
  writes the attempt, and increments `statsDaily` (count `activeUsers` once per user per
  day via `users/{uid}.lastActiveDay`).
- Flag a question (`flagged: true`) when attempts ≥ 20, the correct rate is < 25%, and one
  wrong option has ≥ 50% of the answers. That points to a likely wrong answer key.
- `askMentor`: follow §8 exactly. LLM secrets via `defineSecret`. Count `mentorMessages`
  and `mentorBySource` in `statsDaily`.
- A `beforeUserCreated` or first-`updateProfile` hook increments `statsDaily.newUsers`.
- Test with the emulator suite and a seed script (`scripts/seed-emulator.ts`).

### 5. `firestore.rules`
Implement CONTRACT §4 access rules. Default deny. `isAdmin()` =
`exists(/databases/$(database)/documents/admins/$(request.auth.uid))`. Write rules tests
with `@firebase/rules-unit-testing`. Must-pass cases: a student cannot read `answerKeys`,
cannot read another user, and cannot write anything.

### 6. `app/lib/core/data/firebase_masar_repository.dart`
Implement `MasarRepository` from CONTRACT §6 using `firebase_auth`, `cloud_firestore`,
`cloud_functions` (region `europe-west1`). `progress()` is a live snapshot of
`users/{uid}/mastery/{subjectId}` joined with the subject's concepts. Coordinate with Amer
for the packages in `app/pubspec.yaml` and the models' `fromJson`. This file is yours,
everything else in `app/` is his.

### 7. Admin dashboard (`admin/`), Arabic RTL
Login with email/password, then the `admins/{uid}` check. Pages:
1. **نظرة عامة**: KPI cards (total students, active today, active 7 days, answers today,
   accuracy today, average readiness), a 14-day line chart from `statsDaily` (active users,
   answers), and a bar chart of mentor messages by source.
2. **الطلاب**: table with name, subjects, readiness per subject, last active, answers count.
   Search and sort.
3. **ملف الطالب**: per subject, the concept map (colored bars, same colors as the app),
   readiness history chart, latest 50 attempts, and the plan completion streak. Live updates
   (onSnapshot) so the demo shows changes as a phone answers.
4. **المواد**: per subject, concepts with weight (the "exam blueprint" pie chart), average
   class mastery (`masterySum / learners`), learners count, and the **weakest concepts across
   all students**. Inline editing of a concept's `name`/`explanation`.
5. **الأسئلة**: filter by subject/concept, columns difficulty, attempts, correct %, option
   distribution, `flagged`. Filter "flagged only". Shows the answer key (admins only).
6. **الإعدادات**: edit `config/app` (mentorName, mentorEnabled, mentorSource pc/cloud,
   dailyMentorLimit).
Deploy to Firebase Hosting.

### 8. Demo seed
`scripts/seed-demo.ts` creates ~30 fake students with realistic 7-day histories, so the
dashboard charts aren't empty during the pitch. Mark them `demo: true` in `users/{uid}`. The
dashboard gets a toggle to hide demo users.

## Rules for you
- Small commits, clear messages, `git pull --rebase` before push. Never force-push `main`.
- Never commit secrets. Use Firebase secrets and `.env` files that are in `.gitignore`.
- When a step is done, tell Salah what to run to verify it (exact commands) and what you could not test.
