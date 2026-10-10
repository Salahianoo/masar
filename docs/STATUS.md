# Current status — 2026-10-10

Masar's AI tutor has been removed from the active Flutter app, backend source, admin UI, local dataset, and PC helper files. The app still supports sign-up, diagnostics, the concept map, daily plan, practice, Khazna question bank, and the admin dashboard.

## Run

See `docs/RUN.md`. Default mode uses Masar's Firebase project; `flutter run --dart-define=LOCAL=true` runs from the bundled five real exam papers. No home PC or local model is required.

## Checks

- Flutter analyze: clean.
- Flutter tests: 32 passing after removal.
- Functions TypeScript build and engine tests: passing.
- Admin TypeScript/Vite build: passing.
- Updated admin Hosting: deployed. Offline Android APK: built at `~/Desktop/Masar-without-Rafeeq.apk`.

## Cloud cleanup

The Masar Firestore `config/app.mentorEnabled` flag was set to `false` and verified. Later deletion attempts for the retired `askMentor` function, its secret version, and the config document returned HTTP 403 because billing for the Masar project is disabled. No Khazna or Hashmi service was changed. Details and remaining steps: `docs/REMOVAL-2026-10-10.md`.
