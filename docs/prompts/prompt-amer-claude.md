> **Repo:** https://github.com/Salahianoo/masar (private)
> ```
> git clone https://github.com/Salahianoo/masar.git
> ```
> The contract is at `docs/CONTRACT.md`. The root `CLAUDE.md` / `AGENTS.md` point every agent to it.

You are a Flutter engineer on a 3-person hackathon team building **Masar**, an adaptive
learning app for Jordanian university students. Your human is Amer. Before anything else,
read `docs/CONTRACT.md` in the repo. It is binding: use its model names, fields, repository
interface, folder layout and learning-engine math exactly. If something you need is missing
or wrong there, stop and tell Amer. Don't invent a variant.

## Your ownership (edit only these)
- `app/lib/main.dart`, `app/lib/core/**` (theme, models, repository interface, mock
  repository, router, shared widgets), `app/pubspec.yaml`
- Features: `app/lib/features/onboarding/`, `diagnostic/`, `map/`, `home/`, `profile/`
- **Not yours:** `app/lib/core/data/firebase_masar_repository.dart` belongs to Salah, and
  `practice/`, `mentor/`, `khazna/`, `summary/` belong to Osama.

Osama builds on top of your core, so **step 1 is urgent**. Push it as early as possible.

## Stack
Flutter (latest stable), `flutter_riverpod`, `go_router`, `google_fonts`
(IBM Plex Sans Arabic), `firebase_core`, `firebase_auth`, `cloud_firestore`,
`cloud_functions`, `syncfusion_flutter_pdfviewer` (Osama uses it, but you add it),
`fl_chart`, `shared_preferences`. The app is Arabic-only, RTL (`Locale('ar')`,
`Directionality.rtl`), and works on iOS and Android.

## Work in this order. Commit after each step.

### 1. Core (target: first 1–2 hours, then push)
- `app/` is empty (except `.gitkeep`). Create the project with
  `flutter create --org jo.masar --project-name masar --platforms ios,android app`.
  Remove `app/.gitkeep`.
- `core/models/`: every class and enum in CONTRACT §6, immutable, with `fromJson`/`toJson`
  and `copyWith` where useful. Field names exactly as written.
- `core/data/masar_repository.dart`: the abstract interface, verbatim from §6.
- `core/data/mock_masar_repository.dart`: a **realistic** in-memory fake.
  - One subject «ثقافة صحية و اسعافات أولية» with ~8 Arabic concepts (النزيف، الكسور،
    الحروق، الإنعاش القلبي، الضغط النفسي، الإصابات العضلية، الإغماء، التسمم) with weights
    summing to 1, a short Arabic explanation each, ~40 Arabic mcq/truefalse questions with
    answers, and 3 fake past exams.
  - Implements the §7 math for real (Elo, mastery, readiness, plan, next question, nudge),
    so the UI behaves as it will in production. Add 300–600 ms fake latency.
    `askMentor` returns a canned, concept-aware Arabic reply after ~1.5 s.
  - `progress()` emits a new value after every `submitAnswer`.
- `core/data/repository_provider.dart`: a Riverpod provider that returns the mock when
  `const bool.fromEnvironment('MOCK')` is true, otherwise `FirebaseMasarRepository`. Until
  Salah's file exists, add a stub class that throws `UnimplementedError`.
- `core/theme/`: one place for all colors, text styles, radii and spacing. The brand isn't
  final, so keep every value as a named token so it can be swapped in minutes. Status
  colors: unknown = gray, weak = red, medium = amber, strong = green. Expose
  `MasteryStatus.color` and `.labelAr` (غير مختبر، ضعيف، متوسط، قوي).
- `core/widgets/`: shared pieces Osama will reuse:
  `ReadinessRing` (big %, animated when the value changes), `ConceptBar` (name + colored
  progress + %), `PrimaryButton`, `MentorAvatar(pose)`. The bot's 3D images aren't ready
  yet: show a colored circle placeholder and read images from `assets/mentor/{pose}.png`
  when present. Poses: wave, happy, thinking, sorry, pointing. Also `AsyncStateView`
  (loading, error with retry, empty).
- `core/router.dart`: go_router with the app shell (bottom navigation, 4 tabs: «مساري»
  home, «خزنة» khazna, mentor (label = `config.mentorName`), «أنا» profile) and these routes:
  `/onboarding`, `/diagnostic/:subjectId`, `/map/:subjectId`, `/practice/:subjectId`
  (query `conceptId`, `examId`, `mode=plan|exam`), `/summary/:subjectId`,
  `/khazna/exam/:examId`, `/mentor`. Osama's routes point to placeholder screens until he
  replaces them.
- `main.dart`: init Firebase (skip when MOCK), anonymous sign-in, then route to
  onboarding if there's no profile or enrollment, otherwise home.
- Push, then tell Amer: "core is pushed, Osama can pull".

### 2. Onboarding (`features/onboarding/`)
1. Welcome: mentor avatar (wave) with the line «أهلاً! أنا {mentorName}. رح أمشي معك
   خطوة خطوة لحد امتحانك».
2. Name: a text field, then `updateProfile`.
3. Subjects: pick one or more subjects; for each, pick the exam date (date picker,
   future dates only), then `enroll`.
4. Go to the diagnostic of the first subject.

### 3. Diagnostic (`features/diagnostic/`)
- Intro: «8 أسئلة بس، مش امتحان، ما في علامة. بدي أعرف وين إنت».
- One question per screen with a progress bar ("سؤال 3 من 8"). Show the subject and
  `examLabel` small. Tap an option, then «التالي». Submit with `source: diagnostic`.
  **Don't** reveal right/wrong during the diagnostic.
- After 8, call `completeDiagnostic`, show a short "building your map" animation
  (~1.5 s), then go to the map.

### 4. Map + readiness (`features/map/`): the demo's wow moment
- Big `ReadinessRing` with "جاهزيتك للامتحان", under it
  «بتوصل {projectedReadiness}% إذا مشيت على الخطة».
- Concept list sorted by weight: `ConceptBar` in status colors. For weak concepts with
  weight ≥ 0.1, add a warning line «بيجي بـ {weight%} من الامتحانات».
- Tapping a concept opens a sheet with its explanation and a button «تمرّن على هاد المفهوم»
  → `/practice/:subjectId?conceptId=...`.
- CTA «شوف خطتك» → home. Live-updates from `progress()`.

### 5. Home: today's plan (`features/home/`)
- Header: greeting with the name, days left, readiness with a trend arrow.
- If enrolled in several subjects: a horizontal subject switcher.
- «خطة اليوم · {minutes} دقيقة»: the plan items with status color, `done/count`, and a
  «مراجعة» tag for review items.
- One big CTA «يلا نبلش» → `/practice/:subjectId?mode=plan`. When the plan is completed,
  show a done state and «تمرّن كمان» (free practice).
- A small «خريطتي» link → map.

### 6. Profile (`features/profile/`)
Name, enrolled subjects with exam dates (editable, re-`enroll`), a readiness history line
chart per subject (`readinessHistory`, `fl_chart`), and the mentor's name and avatar.

## Quality bar
- Every async screen goes through `AsyncStateView`. Arabic error messages, a retry button,
  no raw exceptions shown.
- RTL everywhere, no overflow on a 360-dp-wide phone, large tap targets, works in light mode
  (dark mode is optional).
- Short, friendly Jordanian Arabic copy, no corporate tone.
- Run `flutter analyze` with zero warnings before every push. Write widget tests for the
  map screen and for the mock's readiness math.

## Rules for you
- Small commits, `git pull --rebase` before push, your own branch `amer/...`, merge to `main` often.
- When Osama asks for a core change (a model field, a shared widget, a package), make it
  quickly and tell him when it's pushed.
- When a step is done, tell Amer how to see it: `flutter run --dart-define=MOCK=true` and
  which screen to open.
