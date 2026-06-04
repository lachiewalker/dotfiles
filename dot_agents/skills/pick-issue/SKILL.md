---
name: pick-issue
description: Check project board status and begin or resume work on an issue. Fetches board state, shows prioritised ready issues, creates the branch, moves the item to In Progress, and creates an implementation plan. Use when user says "what should I work on", "pick up next issue", "begin work", "resume work", "check the board", "start next", or invokes /pick-issue.
---

# Pick Issue

Checks the project board, identifies what to work on, and sets up the branch.

## Detect tracker

```bash
git remote -v
```

- Contains `github.com` → use `gh` (GitHub)
- Contains `gitlab.com` → use `glab` (GitLab)
- No match → fall back to local `.scratch/` markdown

All commands below show GitHub form first, GitLab equivalent in parentheses.

## State machine

```
Entry
  ├─ On feature branch? → RESUME
  └─ On main?           → PICK
```

---

## RESUME — already on a feature branch

1. Parse issue number from branch name (`<issue-id>-<slug>`).
2. Fetch issue: `gh issue view <number> --comments` / `glab issue view <number>`
3. Check `git status` + recent commits on this branch vs `main`.
4. State current progress and ask: "Continue here, or switch to a different issue?"

---

## PICK — choosing the next issue

### 0. Board health check (GitHub only)

Before fetching ready issues, check whether the board needs to be advanced.

```bash
gh project item-list <project-number> --owner <owner> --format json
```

**If every item with a non-Done status is in `Backlog` (i.e. nothing is `Ready` or `In Progress`):**

This means the previous epic is fully done and the board hasn't been advanced yet.

1. Find all items with `status == "Backlog"`, grouped by `epic:N-*` label.
2. Identify the lowest N whose tickets are all still `Backlog` (i.e. the next unstarted epic).
3. Move all items from that epic: `Backlog` → `Ready`.

```bash
gh project item-edit \
  --project-id <project-id> \
  --id <item-id> \
  --field-id <status-field-id> \
  --single-select-option-id <ready-option-id>
```

Get field/option IDs from:
```bash
gh project field-list <project-number> --owner <owner> --format json
# Status field type is ProjectV2SingleSelectField
# Ready option id is in .options[]
```

4. Tell the user: "Advanced board — Epic N tickets now Ready."
5. Continue to step 1 (pick from Ready).

**Do not touch the iteration field** — iterations are cosmetic grouping labels only; status drives advancement.

Skip this step for GitLab.

**GitLab:**
```bash
glab issue list --label "ready" --assignee "" --state opened
```

If project number / owner unknown, check:
```bash
gh repo view --json owner,name
gh project list --owner <owner>
```

### 2. Display

```
Ready issues (Iteration N):
  1. #<n> — <title>  [<labels>]
  2. #<n> — <title>  [<labels>]
...
In Progress:
  #<n> — <title>
```

### 3. Select

Ask user which number to pick (or accept if already specified).

Fetch full issue with comments:
```bash
gh issue view <number> --comments
# or
glab issue view <number>
```

### 4. Create branch

```bash
# Slug: lowercase title, spaces→hyphens, strip special chars, max 40 chars
git checkout main
git pull origin main
git checkout -b <issue-number>-<slug>
```

### 5. Move board item to In Progress

**GitHub:**
```bash
gh project item-edit \
  --project-id <project-id> \
  --id <item-id> \
  --field-id <status-field-id> \
  --single-select-option-id <in-progress-option-id>
```

Get field/option IDs:
```bash
gh project field-list <project-number> --owner <owner> --format json
```

**GitLab:**
```bash
glab issue update <number> --label "in-progress" --unlabel "ready"
```
Or move board column if using GitLab issue boards via UI/API.

### 6. Create implementation plan

Read the issue body in full. Invoke the `plan` skill — pass it:
- Issue title and full body as context
- Any relevant constraints from CLAUDE.md

Review the plan with the user before proceeding to code.

### 7. Confirm

```
Branch: <branch-name>
Issue:  #<n> <title>
Board:  → In Progress
Plan:   created
Ready to work.
```

---

## Rules

- Never commit to `main` directly.
- One issue per branch.
- If user is mid-task on current branch, confirm before switching.
- Infer repo owner/name from `git remote -v` if not provided.
- Cache project/field IDs mentally within session — don't re-fetch each step.
