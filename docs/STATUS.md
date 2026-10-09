# Masar: where we are (handoff)

Snapshot: **2026-10-09, 20:10**. Updated on branch `salah/app-flow` (built on Codex's local 3038baf + Amer's UI).
Read this first, then `docs/CONTRACT.md`. Salah now owns the whole repo; Amer and Osama are paused.

## The product in two lines
An adaptive learning app for Jordanian university students (hackathon JORDAN.NEXT(), track
"Education & learning"). A short diagnostic builds a concept map with mastery % per concept and
an exam readiness %. A daily plan targets weak concepts, weighted by how often each concept
appears in real past exams. The mentor **رفيق** steps in after two misses on one concept.
Questions come from Khazna, the team's past-exams app, which lives inside Masar as one tab.
Khazna's own app, repo and Firebase project (`hu-pp-q`) are never touched.

## How to run
```bash
cd app
flutter run --dart-define=LOCAL=true                                         # real data; رفيق says he is not connected
flutter run --dart-define=LOCAL=true --dart-define-from-file=rafeeq.local.json   # + رفيق live after configuring Masar's separate PC gateway
flutter test                                                                 # 28 tests, all pass
node ../scripts/build-app-data.mjs   # regenerate the app's dataset after editing scripts/data/masar-5/*
```
- `LOCAL=true` (the old `MOCK=true` also works) runs everything **on the device**, using the five real papers, with
  no backend. Without it, the app uses `FirebaseMasarRepository` with anonymous auth (see "Start-up flow").
- For the PC mentor, copy `app/rafeeq.local.example.json` to the ignored `app/rafeeq.local.json` and fill in
  only Masar's own `RAFEEQ_GATE_TOKEN` from the separate PC gateway (`pc/README.md`). Do not use هاشمي's token.
- `flutter pub get/build` rewrites `app/analysis_options.yaml` every time. Revert it before committing.
- iOS simulator: `flutter build ios --simulator --debug --dart-define=LOCAL=true` then install `build/ios/iphonesimulator/Runner.app`.

## Code layout (clean architecture; the dependency rule holds, keep it that way)
```
app/lib/
  core/          di/repository_provider.dart  ← the ONLY place that picks Local vs Firebase
                 errors/app_exception.dart     ← user-safe Arabic errors; UI checks `is AppException`
                 utils/
  domain/        entities/ (Subject, Concept, Question, Exam, Enrollment, progress…)
                 repositories/masar_repository.dart   ← the contract (CONTRACT §6 + signOut)
                 services/learning_engine.dart        ← CONTRACT §7 math (Elo, mastery, readiness, plan)
  data/          datasources/local/local_data.g.dart  ← GENERATED dataset, don't edit
                 datasources/local/session_store.dart ← SharedPreferences snapshot (masar.session.v1)
                 datasources/remote/rafeeq_client.dart← OpenAI-style call to the PC LLM
                 models/local_question.dart
                 repositories/local_masar_repository.dart, firebase_masar_repository.dart
  presentation/  screens/ (splash, onboarding, diagnostic, map, home, practice, mentor, khazna,
                 summary, profile, subjects/add_subject), components/, navigation/, themes/, state/providers.dart
```
Rules: `domain` imports nothing from `data` or `presentation`, and `data` and `presentation` never import each other.
Check with `grep -rn "package:masar/data" lib/presentation` (expect nothing) before pushing.

## Data
- `scripts/data/masar-5/`: the five reviewed papers (JSON in Khazna's shape, plus Masar-branded PDFs). They were converted
  from Khazna by Masar Agent (`~/Desktop/Masar-Agent`, `src/from-khazna.ts`) with no model calls.
  - Computer ethics: 34
  - Environment: 121
  - First aid: 50
  - Databases: 33
  - Military science: 38
  - **276** questions in all.
- `scripts/data/masar-5/concepts.json`: 34 hand-written concepts with رفيق's explanations (Jordanian dialect,
  grounded only in the papers' answers), per-subject `mentorNotes`, and **6 `suspect` questions** whose
  source answer looks wrong. Those are kept but never served. Never change an answer: answers come only from the source.
- `scripts/build-app-data.mjs` turns all of that into `local_data.g.dart` + `app/assets/papers/*.pdf`.
  It fails loudly if any usable question has no concept.

## Start-up flow (since 2026-10-09 evening)
splash → 3 intro slides (once per device, prefs key `masar.introSeen`) → name only → home.
- Saving the name signs in anonymously and calls `updateProfile`, which gives the student a unique
  **5-digit number** (`users/{uid}.studentId`, reserved in the private `studentIds/{n}` collection in the
  same transaction). The profile header shows «رقمي 12345»; the admin dashboard lists and searches it.
- Home with no subject shows one navy button «اختار المادة اللي بدك تختبرها» → `/subjects/add` → diagnostic.
- `FirebaseMasarRepository.signIn()` validates a saved user with a forced token refresh; a dead session
  (it used to hang the splash forever) is dropped and replaced. Auth and start-up reads have timeouts.
- Pages slide+fade (`router.dart` `_animated`); reduced motion turns it into a cut.
- The Google-only sign-in screen was removed from the flow. `FirebaseGoogleAccountService` is still in
  `data/` for linking later, but nothing in the UI uses it.
- Verified on the iPhone 17 Pro simulator against Firebase: sign-up → number 60716 → `users` + `studentIds`
  written → relaunch lands on home. 38 Flutter tests pass.

## Done
- 3D رفيق poses (`app/assets/mentor/`, sources in `design/mentor/3d`), his face as the mentor tab, and an
  «رفيق عم يحضّرلك الجواب» typing bubble.
- Animated splash: the book opens, the path climbs, the dot lights up, with a synthesised shine sound
  (`design/splash/make_shine.py`). It respects reduced motion and the silent switch.
- Real data only: the sample data is deleted. All five subjects work: diagnostic, map, plan, practice, Khazna tab (bundled PDFs).
- رفيق: `askMentor` builds the prompt from `docs/mentor-persona.md` + the concept explanation + up to 6 real
  questions with answers + the student's state, and calls the PC. If the PC can't answer, the student sees
  «رفيق مشغول هلق». There are no canned replies.
- Session survives restarts (SharedPreferences). Add a subject from home («＋ مادة») or profile. Sign out.
- Backend code (Codex): callable functions, rules, emulator tests, رفيق persona/fallback. Seven learning functions and rules deployed; `askMentor` awaits secrets.
- Admin dashboard: Arabic RTL, live Firestore pages for overview, students, student detail, subjects, questions and settings. Hosted at `https://masar-hackathon-jo-2026-salah.web.app`. Admin access granted only to Salah's confirmed Auth UID.
- Masar Firestore contains 5 subjects, 34 weighted concepts, 276 reviewed questions, 276 separate answer keys, 9 exams and `config/app`. Six suspect questions are flagged and excluded from diagnostic and practice. The importer works through the Firebase CLI token without ADC.
- Google sign-in is wired on iOS and Android; the iOS simulator build and Flutter tests pass. It has not been exercised with a human Google account on-device.
- Pitch script: https://claude.ai/artifact/6wmqu2Z2dACmuy5PPfF1M1 (source `~/Desktop/masar-pitch/pitch.html`).

## ⚠️ Temporary for the contest (remove after, see `docs/contest-temporary.md`)
- An older local demo used هاشمي's PC gate. Do not copy its token into new builds. Configure
  Masar's separate رفيق gateway and token in the git-ignored `app/rafeeq.local.json` (`pc/README.md`).
- After the contest: rotate any token embedded in demo builds and move the client call behind `askMentor`.

## Gaps, in priority order
1. **Admin dashboard**: Implemented and hosted. Verify the six pages using Salah's admin account and an active student. Demo users are labelled «بيانات تجريبية» and can be hidden; historical `statsDaily` aggregates still include them.
2. **Firebase path**: Blaze, Firestore, import, rules and seven learning functions are live. Remaining:
   - رفيق: `askMentor` is deployed with secrets `MASAR_LLM_URL`/`MASAR_LLM_TOKEN` (TEMPORARY: هاشمي's gate, see `docs/contest-temporary.md`) and `ANTHROPIC_API_KEY`="not-configured". `config/app` is `mentorEnabled=true`, `mentorSource=pc`.
     **Blocker:** the `askmentor` Cloud Run service has no `roles/run.invoker` for `allUsers` (every other callable has it), so every call is rejected with 401 before the code runs and the app says رفيق is busy. Salah must approve granting it (Console → Cloud Run → askmentor → Security → "Allow public access", or `setIamPolicy`).
   - The five reviewed PDFs are bundled in the Flutter app and Firestore `exams.pdfUrl` points to their `asset:` paths, so they work without Firebase Storage. Enable Storage later only for new papers distributed after an app release.
   - Run an end-to-end phone test of Google sign-in, diagnostic, plan and admin live updates.
3. **Diagnostic answer reveal**: Changed on Salah's request (2026-10-09). Each answer now shows right/wrong, the correct option and the running score («2 من 3 · 67%»); after the last one a score screen («جبت 5 من 8 صح», %), then the map.
4. **Extract use cases**: Diagnostic selection, daily plan building, and answer updates now live in pure `domain/usecases/`; the local repository handles storage and persistence. All Flutter tests remain green.
5. **Firebase session**: The profile sign-out confirmation and Google-login routing have a widget test. The repository signs out of Firebase Auth and Google; start-up reuses Firebase Auth's persisted user. A real Google account sign-in/restart/sign-out cycle still needs an on-device check.

## Don'ts
- Don't touch Khazna (`~/Desktop/Exam-Vault*`, project `hu-pp-q`) except reading, and don't change هاشمي's setup.
- Don't commit secrets: `app/rafeeq.local.json`, `pc/.env`, any API key.
- Don't solve or "fix" exam answers. Flag them instead.
- Don't force-push `main`. Branch, commit small, `git pull --rebase` before pushing.
