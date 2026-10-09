# Temporary for the contest: remove afterwards

**What:** رفيق answers through **هاشمي's PC door** (`llm.salahabushamseih.com`, Khazna's gate) because Salah is away from the PC and رفيق's own door (`pc/`, tunnel `masar`) isn't set up yet. Agreed on 2026-10-09: "when we finish the contest, can we remove it?" Yes.

**Where it lives:** only in `app/rafeeq.local.json` on Salah's Mac (git-ignored, mode 600): the gate URL and هاشمي's `LOCAL_LLM_TOKEN`. Builds use:

    flutter build ios --dart-define=LOCAL=true --dart-define-from-file=rafeeq.local.json

**Side effects while it's on:**
- رفيق shares the PC queue with هاشمي's students (the gate allows two requests at once).
- Every demo build carries هاشمي's token inside it.

## Remove after the contest
1. Delete `app/rafeeq.local.json` and its line in `.gitignore`.
2. **Rotate هاشمي's token**, because it went into demo builds: a new `GATE_TOKEN` in `Exam-Vault/hu_pp_q/local-llm/.env` on the PC, then `firebase functions:secrets:set LOCAL_LLM_TOKEN --project hu-pp-q` and redeploy `askTutor` (the PC's Claude deploys هاشمي).
3. Delete or reinstall any phone that has a demo build.
4. Give رفيق his own door: follow `pc/README.md`, then build with رفيق's URL and token instead.
