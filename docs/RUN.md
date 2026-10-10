# Masar: how to run it

Everything you need to install, build, run and test Masar. It is written for someone who has never seen the
project. If something here doesn't work, the **Troubleshooting** section at the end covers the usual causes.

> **Fastest way to see it:** install the Android APK (§1) or open the admin dashboard (§2). Building from
> source (§3) takes about 10 minutes the first time.

---

## 0. What's in the repo

```
app/        Flutter mobile app (iOS + Android), the part students use
functions/  Firebase Cloud Functions (TypeScript): learning engine, daily plan, رفيق mentor
admin/      Admin dashboard (React + Vite), hosted on Firebase Hosting
scripts/    Data pipeline: the 5 subjects' exam papers → questions + concepts → app dataset / Firestore
design/     App icon and رفيق mentor images
docs/       This guide, the shared CONTRACT (data schema + engine maths), the mentor persona
pc/         Optional: رفيق's own gateway for running the model on a team PC
```

The app talks to a live Firebase project (`masar-hackathon-jo-2026-salah`) that is already set up and seeded:
5 subjects, 34 weighted concepts, 276 real past-exam questions, 9 exams. **You do not need your own Firebase
project to run the app.** The client config files (`app/lib/firebase_options.dart`,
`app/android/app/google-services.json`, `app/ios/Runner/GoogleService-Info.plist`) are committed for that reason.
They are public client identifiers, not secrets.

---

## 1. Android APK (no build needed)

Install the APK we hand in with the submission (`Masar.apk`, about 80 MB) on any Android 7.0+ phone. Allow
"install from unknown sources" when asked. It is signed with a debug key, so uninstall any older Masar build first.

## 2. Admin dashboard (no build needed)

**https://masar-hackathon-jo-2026-salah.web.app**

It shows students, subjects, questions and live statistics. Every new sign-up in the app appears here in
real time. **Judges:** sign in with the demo account given in our submission form. It is a read-only viewer
(Firestore rules block every write for `admins/{uid}.role == "viewer"`), so you can open every page safely.

---

## 3. Build the app from source

### Requirements

| Tool | Version we use | Needed for |
|---|---|---|
| Flutter | **3.47.0** (stable), Dart 3.13 | the app (`flutter --version`) |
| Android | Android SDK 36 + **JDK 17 or newer** | Android build. Android Studio's bundled JDK works |
| iOS (macOS only) | Xcode 27, CocoaPods, iOS 15.0+ | iOS build / simulator |
| Node.js | **22** (24 also works) + npm | functions and admin (optional) |
| Firebase CLI | 15.x (`npm i -g firebase-tools`) | only to deploy (optional) |

Check your setup with `flutter doctor`.

### Steps

```bash
git clone https://github.com/Salahianoo/masar.git
cd masar/app
flutter pub get
```

Then pick one of the two modes.

**A) Full app on the live backend (default; this is the demo):**
```bash
flutter run                    # pick a connected phone, emulator or simulator
```
Registration, diagnostic, concept map, daily plan, practice, the خزنة exam bank, رفيق and the admin dashboard
all go through Firebase. An internet connection is required.

**B) Offline mode, everything on the device (no backend, no internet):**
```bash
flutter run --dart-define=LOCAL=true
```
Uses the same 276 bundled questions and the same learning engine on the device, with progress saved in
SharedPreferences. Useful if the network at your venue is unreliable. In this mode رفيق is not connected.

### Release builds
```bash
flutter build apk --release            # → build/app/outputs/flutter-apk/app-release.apk
flutter build ios --simulator --debug  # → build/ios/iphonesimulator/Runner.app (drag onto a simulator)
```

### Tests
```bash
flutter analyze   # expect: No issues found
flutter test      # expect: 39 tests, all pass
```

---

## 4. Demo walkthrough (about 3 minutes)

1. **Launch:** an animated splash, then 3 intro slides (shown once per device).
2. **Sign up:** type a name only. You get a unique **5-digit student number**, shown on the أنا (profile) tab.
   Open the admin dashboard: the new student is already there.
3. **Pick a subject:** tap the navy «اختار المادة اللي بدك تختبرها» button, choose a subject and an exam date.
4. **Diagnostic (8 questions):** each answer shows right/wrong and your running score, then a result screen.
5. **Concept map:** mastery per concept, coloured red/amber/green and ordered by how often each concept
   appears in real past exams.
6. **Home:** swipe between subject cards (readiness ring); «خطة اليوم» lists today's questions. Swipe between
   the four tabs, or tap the bottom bar.
7. **Practice:** answer two questions wrong on the same concept, and رفيق offers to explain.
8. **رفيق tab:** ask anything about the subject. He answers in Jordanian Arabic, grounded in the real exam
   questions.
9. **أنا → «كيف بنقيس مستواك؟»:** how the rating works, with a live simulator that runs the real engine.

---

## 5. How it works

### The learning engine (Elo, like chess ratings)
Every answer is a "match" between the student (rating θ for that concept) and the question (difficulty d).

```
P(correct)  = 1 / (1 + e^-(θ − d))
θ ← θ + K · (result − P)          K = max(0.25, 0.8 / (1 + 0.15·attempts))
d ← d − 0.05 · (result − P)       questions learn their difficulty from all students
mastery %   = 100 / (1 + e^-θ)    everyone starts at θ = −1 → 27%
readiness % = Σ (concept weight × mastery)   weight = share of real exam questions on that concept
next question: difficulty ≈ θ − 0.85 → about a 70% chance of success
daily plan:  the 3 concepts with the highest weight × (1 − mastery), 12–15 questions
```
The same maths runs on the server (`functions/src/engine.ts`) and in the app
(`app/lib/domain/services/learning_engine.dart`). Full spec: `docs/CONTRACT.md` §7.

### رفيق (the mentor)
- Cloud Function `askMentor` builds the prompt from the persona (`docs/mentor-persona.md`), the concept's
  explanation, up to 6 real questions with their source answers, and the student's mastery.
- The model is a **local LLM** (Qwen 3.5 9B in LM Studio) on the team's PC, reached through an
  authenticated tunnel. The URL and token are Firebase secrets, never in the app or the repo.
- **If the team PC is offline, رفيق replies that he's busy, and everything else keeps working.**
- Students get a per-day message limit, enforced server-side.

### Data
`scripts/data/masar-5/` holds the 5 reviewed papers (JSON) plus `concepts.json` (34 concepts with
explanations). Answers come only from the source papers. Six questions whose source answer looks wrong are
flagged and never shown. `node scripts/build-app-data.mjs` regenerates the app's bundled dataset.

### App architecture (Clean Architecture, Riverpod, go_router)
```
app/lib/core/          dependency injection (the only place that picks Firebase vs local), errors
app/lib/domain/        entities, repository contract, learning engine, use cases (pure Dart)
app/lib/data/          Firebase + local repositories, data sources
app/lib/presentation/  screens, components, navigation, theme (Tajawal font, navy + teal)
```

---

## 6. Backend (optional: it is already deployed)

```bash
cd functions
npm ci
npm run build                        # TypeScript → lib/
npx vitest run src                   # 11 unit tests (engine + mentor)
# Integration and rules tests need the Firebase emulators (Java 21+):
#   firebase emulators:exec --only auth,firestore,functions "npm test"
```
Deploying (team only): `firebase deploy --only functions,hosting,firestore:rules`.

## 7. Admin dashboard locally (optional)

```bash
cd admin
cp .env.example .env.local       # public Firebase web config, already filled in
npm ci
npm run dev                      # → http://localhost:5173
```

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| `flutter pub get` fails | Use Flutter 3.47+ (Dart 3.13+): `flutter upgrade`. |
| Android build: "Unable to locate a Java Runtime" / wrong Java | Install JDK 17+, or point `JAVA_HOME` to Android Studio's JDK: `export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"` |
| iOS build: CocoaPods errors | `cd app/ios && pod install --repo-update`, then build again. |
| رفيق says «مشغول» (busy) | The team PC running the model is offline. Everything else works. Contact the team. |
| Splash spins with no internet | The default mode needs the internet. Use `--dart-define=LOCAL=true` for offline. |
| Admin shows «أضف إعدادات Firebase» | You skipped `cp .env.example .env.local` (local runs only). The hosted dashboard is already configured. |
| `analysis_options.yaml` shows as modified after a build | Flutter rewrites it. It's safe to ignore or `git checkout` it. |
