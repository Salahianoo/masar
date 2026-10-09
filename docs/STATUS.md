# Masar: where we are (handoff)

Snapshot: **2026-10-09, evening**, `main` = `salah/ui` at the commit that added this file.
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
flutter run --dart-define=LOCAL=true                                         # real data, رفيق says «مشغول»
flutter run --dart-define=LOCAL=true --dart-define-from-file=rafeeq.local.json   # + رفيق live (Salah's Mac only)
flutter test                                                                 # 26 tests, all pass
node ../scripts/build-app-data.mjs   # regenerate the app's dataset after editing scripts/data/masar-5/*
```
- `LOCAL=true` (the old `MOCK=true` also works) runs everything **on the device**, using the five real papers, with
  no backend. Without it, the app uses `FirebaseMasarRepository`, but the backend is **not deployed** (see Gaps).
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
- Backend code (Codex): callable functions, rules, emulator tests, رفيق persona/fallback. **Not deployed.**
- Pitch script: https://claude.ai/artifact/6wmqu2Z2dACmuy5PPfF1M1 (source `~/Desktop/masar-pitch/pitch.html`).

## ⚠️ Temporary for the contest (remove after, see `docs/contest-temporary.md`)
- رفيق goes through **هاشمي's PC gate** (`llm.salahabushamseih.com`, هاشمي's token) because Salah is away
  from the PC. URL and token live only in the git-ignored `app/rafeeq.local.json` on Salah's Mac.
- After the contest: delete that file, **rotate هاشمي's token** (it's inside demo builds), and give رفيق his own door (`pc/README.md`).

## Gaps, in priority order
1. **Admin dashboard**: `admin/` is still the Vite starter. The dashboard needs shared data, so it depends on (2).
   The spec is in `docs/prompts/prompt-salah-codex.md` step 7. Show demo/synthetic users labelled «بيانات تجريبية» (hackathon data rule).
2. **Firebase path**, needed before the dashboard can see students:
   - Blaze plan unknown: the Cloud Billing API is disabled. Check console → Usage and billing. Functions need Blaze.
   - Storage isn't enabled (it also needs Blaze), so the PDFs can't be uploaded yet.
   - `scripts/import-questions.ts` knows the five papers but **ignores `concepts.json`**: no concepts, conceptIds or
     weights, and `flagged: false`. Make it write concepts from concepts.json and flag the 6 suspects.
   - No gcloud or ADC on the Mac. For REST writes, use `scripts/cli-token.ts` (it reuses the `firebase login` token).
   - `functions/` doesn't skip `flagged` questions when serving. Add that before going live.
3. **Diagnostic reveals right/wrong**: CONTRACT §6/onboarding says it must not. Fix in `presentation/screens/diagnostic`.
4. **Extract use cases**: `local_masar_repository.dart` (~750 lines) mixes data access with orchestration
   (diagnostic pick, plan build, answer update). Move those into `domain/usecases/`, keeping the tests green.
5. **Firebase repository** has no `signOut` UI test and no session persistence (it relies on Firebase Auth).

## Don'ts
- Don't touch Khazna (`~/Desktop/Exam-Vault*`, project `hu-pp-q`) except reading, and don't change هاشمي's setup.
- Don't commit secrets: `app/rafeeq.local.json`, `pc/.env`, any API key.
- Don't solve or "fix" exam answers. Flag them instead.
- Don't force-push `main`. Branch, commit small, `git pull --rebase` before pushing.
