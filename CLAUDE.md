# Instructions for every coding agent

0. Read `docs/STATUS.md` first: where the project is, how to run it, and what's next.
1. Read `docs/CONTRACT.md` before doing anything. It is binding: names, schema,
   function signatures, folder ownership and the learning-engine math.
2. Your task prompt is in `docs/prompts/` (Salah → `prompt-salah-codex.md` for backend/dashboard and
   `prompt-salah-design-codex.md` for icon, brand and mentor images,
   Amer → `prompt-amer-claude.md`, Osama → `prompt-osama-claude.md`). Ask your human
   which one is yours if it's unclear.
3. Edit only the paths your owner owns (CONTRACT §2). Need a change elsewhere? Stop and tell your human.
4. Work on your own branch, commit small, `git pull --rebase` before every push. Never force-push `main`.
5. Never commit secrets (`.env`, service-account keys, API keys).
