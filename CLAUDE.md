# CLAUDE.md — Engineering Instructions for Claude Code

This file is the engineering-tone source of truth for AI agents working on the
`Unreal_Nice_Plugins` host repo. Human-facing onboarding lives in `README.md`
and `SETUP.md` (Thai-mixed prose). Do **not** engineering-ize those files.

## Ownership Table

| Concern | Owner |
|---|---|
| Push protocol | Root `CLAUDE.md` (this file) |
| Skill registry (4 clusters: ralph+verify, deep-interview→ralplan→autopilot, external-context+document-specialist, team/ultrawork) | Root `CLAUDE.md` |
| Manager-agent prompt | Root `CLAUDE.md` |
| Sector convention | Root `CLAUDE.md` |
| Beads block + hooksPath workaround | Root `CLAUDE.md` |
| Build/test commands | Root `CLAUDE.md` |
| Versioning summary (1 paragraph) | Root `CLAUDE.md` (link → `docs/VERSIONING.md`) |
| Versioning detail | `docs/VERSIONING.md` |
| Plugin-specific consumer description | per-plugin `README.md` (AC6) |

## Manager Agent (`start` / `next`)

The manager-agent is invoked when the user types `start` or `next` in Claude
Code at the host repo root.

### `start` — bootstrap a session

1. Read `planning/MILESTONES.md` and confirm at least one row exists with
   `Status = [ ]`.
2. Read `planning/TASK_ASSIGNMENTS.md` to surface ownership / blockers.
3. Run `bd ready` to surface available beads issues.
4. Print the next sector summary and wait for the user to type `next`.

### `next` — execute the next sector

Pseudocode:

```
row    = first MILESTONES.md row with Status == "[ ]"
plugin = row.Plugin              # column 3 (no <Plugin>: prefix in column 2)
sector = row.ID                  # M{milestone}.S{sector}
bdId   = row.Bd
detail = row.Detail              # docs/sectors/<sector>.md (or -bootstrap.md)

# Plugin-scoped work happens INSIDE the submodule
cd HostProject/Plugins/<plugin>

spawn ralph(sector_detail=detail, verifier=architect-verifier)
# ralph re-applies the change on `dev`, runs scripts/regenerate.ps1,
# and lands a verifier-approved commit on the plugin's `dev` branch.

# Back at host root, run the transactional pin script:
scripts/sector-commit.ps1 -Plugin <plugin> -SectorId <sector> -BdId <bdId>

# On exit-code 0:
print "Continue to next sector?"
```

The manager-agent **must not** open-code `git push` sequences. All sector
push transactions go through `scripts/sector-commit.ps1`.

> **Bootstrap-only note (R8 mitigation):** P5a pre-staging is a one-time
> bootstrap step that validates the workflow itself. Future sectors run
> `next` cold; ralph + the architect-verifier are responsible for
> correctness from that point on.

## Sector Convention

- Sector IDs are `M{milestone}.S{sector}` (e.g. `M1.S1`, `M1.S2`, `M2.S1`).
- One commit per sector on the plugin's `dev` branch (atomic).
- One commit per sector on the host repo, updating the submodule SHA pin.
- Sector detail markdowns live under `docs/sectors/<M.S>.md`. The bootstrap
  sector uses the suffix `-bootstrap.md` (e.g. `docs/sectors/M1.S1-bootstrap.md`)
  to mark it as a one-off workflow-validation sector.

## Beads (`bd`) Issue Tracker

Install: <https://github.com/steveyegge/beads>. First-time setup is documented
in `docs/BEADS_SETUP.md` (run `bd init` and seed the three baseline issues
listed there).

### Quick reference

```powershell
bd prime              # Show full bd workflow context
bd ready              # List available work
bd show <id>          # Inspect issue
bd update <id> --claim
bd close <id>         # Closed by sector-commit.ps1 after host push lands
```

### Label conventions

- `plugin:<name>` — plugin scope (e.g. `plugin:SamplePlugin`)
- `sector:<M.S>` — sector scope (e.g. `sector:M1.S1`)
- `ac:<ACn>`     — acceptance criterion (e.g. `ac:AC1`)

### hooksPath workaround

`bd` installs hooks under `.beads/hooks` that conflict with submodule-aware
git operations. When committing/pushing manually, swap hooks for the
duration of the operation:

```powershell
git config core.hooksPath .git/hooks
git add ...
git commit -m "..."
git push
git config core.hooksPath .beads/hooks
```

`scripts/sector-commit.ps1` performs this swap automatically.

## Push-or-Not-Done Protocol

Sector work is **not** complete until BOTH pushes succeed:

1. Plugin submodule push: `git -C HostProject/Plugins/<name> push origin dev`
2. Host repo push: `git push origin <host-branch>` (commit pins the new SHA)

`scripts/sector-commit.ps1` is the only sanctioned execution path. It is
transactional — see exit codes in the script header. If the host push fails
after the plugin push succeeded, the script either auto-resets the local
host commit (clean recovery) or refuses and prints a `git reflog` recovery
hint (when upstream advanced).

Never claim a sector is done if either push has not landed.

## Committed Skills

The following four skill clusters are core dependencies (AC5):

| Cluster | Purpose |
|---|---|
| `oh-my-claudecode:ralph` + `oh-my-claudecode:verify` | Sector executor with architect/critic gating before merge to `dev`. |
| `oh-my-claudecode:deep-interview` → `oh-my-claudecode:ralplan` → `oh-my-claudecode:autopilot` | 3-stage planning chain for new plugins or major sectors. |
| `oh-my-claudecode:external-context` + `document-specialist` agent | UE5 / Epic API documentation lookup; covers the user's "technical support" need. |
| `oh-my-claudecode:team` + `oh-my-claudecode:ultrawork` | Multi-plugin parallel execution; engaged selectively when N≥2 plugins are active. |

## Build & Test

```powershell
# Regenerate VS solution + project files (idempotent, safe to re-run)
scripts/regenerate.ps1

# Open the editor (Windows)
# Double-click HostProject/HostProject.uproject  → "Yes" if it asks to rebuild

# First build will compile the engine modules touched by plugins; expect
# 5-15 min on a cold cache. Subsequent builds are seconds.
```

## Versioning (summary)

Each plugin submodule uses `main` (stable, semver-tagged, FF-only), `dev`
(active work), and `exp/<topic>` (risky experiments). The host repo pins
plugin SHAs (never branch refs); sector commits update the pin. SemVer tags
are created by `scripts/plugin-version.ps1` via FF-only merge from `dev`
into `main`. Rollback = `git checkout <tag>` inside the plugin submodule.

Full detail, branch discipline rules, rollback runbook, and migration
triggers: see [`docs/VERSIONING.md`](docs/VERSIONING.md).

---

> Human-facing onboarding lives in `README.md` and `SETUP.md` (Thai-mixed).
> This file is engineering-tone instructions for AI agents only.


<!-- BEGIN BEADS INTEGRATION v:1 profile:minimal hash:ca08a54f -->
## Beads Issue Tracker

This project uses **bd (beads)** for issue tracking. Run `bd prime` to see full workflow context and commands.

### Quick Reference

```bash
bd ready              # Find available work
bd show <id>          # View issue details
bd update <id> --claim  # Claim work
bd close <id>         # Complete work
```

### Rules

- Use `bd` for ALL task tracking — do NOT use TodoWrite, TaskCreate, or markdown TODO lists
- Run `bd prime` for detailed command reference and session close protocol
- Use `bd remember` for persistent knowledge — do NOT use MEMORY.md files

## Session Completion

**When ending a work session**, you MUST complete ALL steps below. Work is NOT complete until `git push` succeeds.

**MANDATORY WORKFLOW:**

1. **File issues for remaining work** - Create issues for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **PUSH TO REMOTE** - This is MANDATORY:
   ```bash
   git pull --rebase
   bd dolt push
   git push
   git status  # MUST show "up to date with origin"
   ```
5. **Clean up** - Clear stashes, prune remote branches
6. **Verify** - All changes committed AND pushed
7. **Hand off** - Provide context for next session

**CRITICAL RULES:**
- Work is NOT complete until `git push` succeeds
- NEVER stop before pushing - that leaves work stranded locally
- NEVER say "ready to push when you are" - YOU must push
- If push fails, resolve and retry until it succeeds
<!-- END BEADS INTEGRATION -->
