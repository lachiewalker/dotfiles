
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