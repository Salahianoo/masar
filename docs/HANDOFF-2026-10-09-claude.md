# Handoff from Claude → Codex (2026-10-09, evening)

Read this before touching the app, the functions or the admin. Everything below is working and
tested on the iPhone 17 Pro simulator against the real Firebase project. Please don't undo it.

## 1. Where the code is
- Branch **`salah/app-flow`** (pushed). It is built on **your local commit `3038baf`** (salah/google-sign-in,
  7 commits that were never pushed), so those 7 commits are now on GitHub inside this branch.
- Not merged into `main` yet. To continue: `git fetch && git checkout salah/app-flow`. Don't rebase it onto
  an older base, or you'll bring back the Google sign-in flow.
- Worktree used: `~/Desktop/masar-ui`. 38 Flutter tests pass; `flutter analyze` is clean.

## 2. Live changes in Firebase (`masar-hackathon-jo-2026-salah`)
| What | State | Why |
|---|---|---|
| Auth → **Anonymous** provider | **enabled** | Sign-up is now just a name (Salah's decision). It was off, so sign-up failed with `ADMIN_ONLY_OPERATION`. |
| `updateProfile` | **deployed** | Gives each student a unique **5-digit `studentId`**, reserved in `studentIds/{n}` in the same transaction. Saves `email` and `signInProvider` from the token. Returns `{ok, studentId}`. |
| `askMentor` | **deployed** | Secrets `MASAR_LLM_URL`, `MASAR_LLM_TOKEN` (TEMPORARY: هاشمي's gate, see `docs/contest-temporary.md`), `ANTHROPIC_API_KEY`="not-configured". |
| Cloud Run service **`askmentor`** IAM | `roles/run.invoker` → `allUsers` | **This was the real reason رفيق said "busy".** The service had no invoker binding, so every call got a 401 before the code ran. Every other callable already had this binding; the function itself still checks auth, enrollment and the daily limit. **If you redeploy or recreate askMentor, check that this binding still exists.** |
| `config/app` | `mentorEnabled: true`, `mentorSource: "pc"` | رفيق on, answering from the home PC (LM Studio, qwen3.5-9b). |
| Hosting (admin) | redeployed | «الرقم» column, email under the name, search by number. |
| `firestore.rules` | unchanged | `studentIds` stays private (catch-all deny). |

Quick health check for رفيق (it must return the function's own JSON error, **not** a 401):
```bash
curl -s -X POST https://europe-west1-masar-hackathon-jo-2026-salah.cloudfunctions.net/askMentor -H 'content-type: application/json' -d '{"data":{}}'
```
Expected: `{"error":{"message":"سجّل دخولك أولاً.","status":"UNAUTHENTICATED"}}`

## 3. Traps that already bit us (please avoid)
1. **Admin build without `admin/.env.local` breaks the live dashboard.** The page then shows
   «أضف إعدادات Firebase». The file exists only in your worktree (it's git-ignored). Before
   `npm run build` and deploying hosting from any other checkout, copy it in.
2. **`flutter pub get/build` rewrites `app/analysis_options.yaml`.** Revert it before committing.
3. **Deploy only what you changed** (`--only functions:<name>` / `--only hosting`), and tell Salah first.
4. A Firebase user saved in the iOS keychain whose token can't refresh used to hang the splash forever.
   `FirebaseMasarRepository.signIn()` now force-refreshes the token with a timeout, and on failure signs out and
   creates a new anonymous user. Keep that logic.

## 4. App flow now
splash → **3 intro slides** (once per device, prefs `masar.introSeen`) → **name only** → home.
- Name screen: `signIn()` (anonymous) + `updateProfile(name)`. The welcome snackbar shows the 5-digit number,
  and the profile shows «رقمي 12345». The local repo generates its own 5-digit number.
- **The Google sign-in screen was removed** from the flow (`sign_in_screen.dart` deleted). `FirebaseGoogleAccountService`
  remains in `data/` but nothing in the UI uses it. Don't put it back on the start path.
- Home, with no subject: a navy button «اختار المادة اللي بدك تختبرها» → `/subjects/add` → diagnostic.
- Home, with subjects: a **swipeable deck of subject cards** (readiness ring). Tapping a card opens its map, or the
  diagnostic if it isn't done. The header رفيق avatar slides to the رفيق tab. The greeting is random per launch.
- **Tabs swipe**: `StatefulShellRoute` with a custom `navigatorContainerBuilder` → `AppShell` (a PageView synced with
  the bottom bar). Branches use `preload: true`. Please keep this; don't switch back to `.indexedStack`.
- Every non-tab route uses `pageBuilder` with a slide+fade (`router.dart` `_animated`).
- Diagnostic: shows right/wrong, the correct option and the running score after each answer, then a score
  screen before the map (Salah asked for it; this reverses the earlier "reveal nothing" rule).
- رفيق chat: a هاشمي-style header and reply cards (Masar colours), `**bold**` rendered, a send button that lights up when
  there's text, and a compact welcome where all 4 suggestions fit.
- `friendlyError` prefers the server's Arabic message over generic text.

## 5. Data notes
- Test student **«ُثسف ئمشعيث», number 60716** was created by Claude during testing. Salah may ask to delete it
  (`users/{uid}` + `studentIds/60716`).
- `scripts/cli-token.ts` gives a REST token from the Firebase CLI login (no gcloud/ADC on this Mac). Run
  ad-hoc scripts as `.mts` with `npx tsx` from `scripts/`.

## 6. After the contest (TEMPORARY items)
Follow `docs/contest-temporary.md`:
- delete `askMentor` or move it to Masar's own gateway
- delete the 3 secrets
- set `mentorEnabled:false`
- delete `app/rafeeq.local.json`
- **rotate هاشمي's token**

Never touch Khazna (`hu-pp-q`) or هاشمي's setup.
