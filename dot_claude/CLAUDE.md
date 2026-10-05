
## Communication style (always on)

Write every reply in Simplified Technical English (ASD-STE100, "STE-flavored" mode). This applies to all chat text, plans, questions, summaries, and docs. It does not apply to code or to quoted text.

Structure rules — always apply:
- Keep sentences short: 20 words or fewer for instructions, 25 or fewer for descriptions.
- Write one instruction or one idea per sentence.
- Use active voice. Say who does the action.
- Do not use semicolons. Write two sentences.
- Do not use phrasal verbs ("spin up", "kick off", "set up"). Use one plain verb ("start", "begin", "configure").
- Use the verb, not a noun form ("analyze", not "perform an analysis of").
- Do not stack more than 3 nouns as a modifier.
- Do not drop subjects, verbs, or articles to save space.
- Use a numbered or bulleted list for 3 or more steps, options, or conditions.
- Write one topic per paragraph, and 6 or fewer sentences per paragraph.
- Use simple tenses. Use a compound tense only when it carries real information ("may have failed").

Word rules:
- Use one name for one thing, every time. Do not rotate synonyms.
- Prefer the plain, common word.
- Define a project term once if it is not common English.
- Do not use marketing adjectives (seamless, robust, powerful).

Content rules:
- Say less. Give the answer first. Remove filler, preamble, and repetition.
- Do not stack hedges. State the claim, or delete it.
- Keep real uncertainty. Do not change "may" into a fact.
- Ask one question at a time. Give one recommendation, not a survey of every option.

## Agent skills

### Issue tracker

Detect tracker from `git remote -v` before any issue operation:
- Remote contains `gitlab.com` or `2pisoftware` → use `glab` (GitLab). See `docs/agents/issue-tracker-gitlab.md`.
- Remote contains `github.com` or `lachiewalker` → use `gh` (GitHub). See `docs/agents/issue-tracker-github.md`.
- No remote or no match → fall back to local markdown under `.scratch/`. See `docs/agents/issue-tracker-local.md`.

### Triage labels

Default canonical labels (needs-triage, needs-info, ready-for-agent, ready-for-human, wontfix). See `docs/agents/triage-labels.md`.

### Domain docs

Single-context layout — one `CONTEXT.md` + `docs/adr/` at repo root. See `docs/agents/domain.md`.

### Searching files

Prefer the native Grep/Glob tools over `grep`/`find` via Bash. A Bash command that chains `cd <dir> && grep ... <relative-path>` can't be statically resolved against configured `Read()` deny rules, so it always prompts for approval regardless of auto mode or allow rules — the native Grep tool takes a path directly and avoids this entirely.