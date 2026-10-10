# Current status — 2026-10-10

Masar's AI tutor has been removed from the active Flutter app, backend source, admin UI, local dataset, and PC helper files. The app still supports local sign-up, diagnostics, the concept map, daily plan, practice, and the Khazna question bank. The hosted admin dashboard is unavailable because the Masar Firebase project was deleted.

## Run

See `docs/RUN.md`. Run `flutter run --dart-define=LOCAL=true` using the bundled five real exam papers. The default Firebase mode no longer works. No home PC or local model is required.

## Checks

- Flutter analyze: clean.
- Flutter tests: 32 passing after removal.
- Functions TypeScript build and engine tests: passing.
- Admin TypeScript/Vite build: passing.
- Updated admin Hosting was deployed before the project was deleted. An offline Android APK was built without Rafeeq.

## Cloud cleanup

The owner deleted the Masar Firebase project. The project is absent from the active Firebase project list; Khazna's separate project remains present. The 403 responses were incorrectly attributed to billing. No Khazna or Hashmi service was changed. The only remaining separation step is rotation of the old Hashmi gate token, which may be present in historical contest builds. See `docs/REMOVAL-2026-10-10.md`.
