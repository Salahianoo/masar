# Masar: how to run it

Everything you need to install, build, run and test Masar. It is written for someone who has never seen the
project. If something here doesn't work, the **Troubleshooting** section at the end covers the usual causes.

> **Current version:** build from source (§3). The old v1.0.0 APK is a historical contest build.

---

## 0. What's in the repo

```
app/        Flutter mobile app (iOS + Android), the part students use
functions/  Firebase Cloud Functions (TypeScript): learning engine and daily plan
admin/      Admin dashboard (React + Vite), hosted on Firebase Hosting
scripts/    Data pipeline: the 5 subjects' exam papers → questions + concepts → app dataset / Firestore
design/     App icon and brand assets
docs/       This guide, the shared CONTRACT (data schema + engine maths), and removal status
```

The original app targeted Firebase project (`masar-hackathon-jo-2026-salah`), which was seeded with:
5 subjects, 34 weighted concepts, 276 real past-exam questions, 9 exams. The owner deleted that project after the contest. The hosted mode and admin dashboard are unavailable. **You do not need a Firebase project to run the app in local mode.** The client config files (`app/lib/firebase_options.dart`,
`app/android/app/google-services.json`, `app/ios/Runner/GoogleService-Info.plist`) are committed for that reason.
They are public client identifiers, not secrets.

---

## 1. Historical Android APK

The [v1.0.0 APK](https://github.com/Salahianoo/masar/releases/tag/v1.0.0) is the contest snapshot and still includes the retired tutor. Build the current source with `flutter build apk --release` after installing the requirements below.

## 2. Historical admin dashboard

The source is preserved in `admin/`, but its hosted service and Firebase data are unavailable because the Masar project was deleted. The former judges' account is no longer usable.

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

Run the offline mode (the former default Firebase project was deleted):
```bash
flutter run --dart-define=LOCAL=true
```
Uses the same 276 bundled questions and the same learning engine on the device, with progress saved in
SharedPreferences.

### Release builds
```bash
flutter build apk --release --dart-define=LOCAL=true  # → build/app/outputs/flutter-apk/app-release.apk
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
7. **Practice:** answer questions from the daily plan and watch your mastery change.
8. **أنا → «كيف بنقيس مستواك؟»:** how the rating works, with a live simulator that runs the real engine.

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
npm test                             # learning-engine unit tests
# Integration and rules tests need the Firebase emulators (Java 21+):
#   firebase emulators:exec --only auth,firestore,functions "npm test"
```
The former Masar Firebase project was deleted. Deployment requires a new project and configuration; these archived deploy commands do not apply to the current offline app.

## 7. Historical admin dashboard source (optional)

```bash
cd admin
npm ci
npm run build                    # verifies the archived source compiles
```

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| `flutter pub get` fails | Use Flutter 3.47+ (Dart 3.13+): `flutter upgrade`. |
| Android build: "Unable to locate a Java Runtime" / wrong Java | Install JDK 17+, or point `JAVA_HOME` to Android Studio's JDK: `export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"` |
| iOS build: CocoaPods errors | `cd app/ios && pod install --repo-update`, then build again. |
| Splash cannot connect to Firebase | The old Masar project was deleted. Use `--dart-define=LOCAL=true`. |
| Admin shows «أضف إعدادات Firebase» | The old Firebase project was deleted. The dashboard source is archival. |
| `analysis_options.yaml` shows as modified after a build | Flutter rewrites it. It's safe to ignore or `git checkout` it. |
