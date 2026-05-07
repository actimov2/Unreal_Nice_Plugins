# Consensus Plan: Project Environment for Unreal_Nice_Plugins

- **Source spec:** `.omc/specs/deep-interview-project-environment.md` (deep-interview, ambiguity 17%)
- **Consensus mode:** ralplan SHORT, Planner+Architect+Critic, 2 iterations
- **Verdict:** APPROVE (Critic) with 6 binding executor amendments
- **Generated:** 2026-05-07

---

## RALPLAN-DR Summary

### Principles
1. **Preserve existing scaffold** — Thai `README.md`/`SETUP.md`, PowerShell scripts, submodule layout are inputs, not targets.
2. **Host orchestrates, plugin owns** — workflow files at host root coordinate; per-plugin work travels with the submodule SHA.
3. **Submodule SHA is the only contract** between host and plugin.
4. **One source of truth per concern** — no duplicated MILESTONES, no duplicated bd graphs, no duplicated push protocol.
5. **Engineering tone is additive** — new `CLAUDE.md` sits alongside human-facing `README.md`/`SETUP.md`, never replaces them.

### Decision Drivers
1. AC1's atomic-commit constraint (sector commit + SHA pin must be one logical operation).
2. Brownfield reality (SamplePlugin already exists as private submodule).
3. Mixed-audience future-scaling (current N=1; design for now, codify migration triggers for N≥2).

### Decisions

| # | Question | Choice | Rationale |
|---|---|---|---|
| Q1 | MILESTONES hierarchy | **Single-root only** (`planning/MILESTONES.md`); migration trigger at N≥2 plugins | Hybrid is over-engineering for N=1; sync risk dominates benefit |
| Q2 | bd scope | **Host-root `.beads/`** with `plugin:<name>` labels; explicit principle-violation note; migration to `.beads-plugin/` import pattern at N≥2 | Single-graph simplicity; honest disclosure of SHA-contract violation |
| Q3 | Manager-agent plugin detection | **Order in host MILESTONES** (primary) + `bd ready` (override for blocked); always invokes `scripts/sector-commit.ps1` (no open-coded git) | Deterministic, transactional |
| Q4 | CLAUDE.md hierarchy | **Root only** with explicit ownership table; per-plugin `README.md` for consumer description (AC6); migration to per-plugin `CLAUDE.md` at N≥2 | Drift risk vs. value at N=1 |
| Q5 | First sector (AC1 demo) | **M1.S1 = `LogSamplePlugin` startup log** in `SamplePlugin::StartupModule()`; pre-staged on `exp/m1s1-prestage` and rollback-validated before `next` runs | Smallest C++ change exercising compile + module load + tag + rollback |

---

## Implementation Plan

### P1 — Repo scaffolding (host root)

**Files (CREATE unless noted):**
- `CLAUDE.md` (root, engineering tone, ownership table)
- `planning/MILESTONES.md` (single-root, row format below)
- `planning/TASK_ASSIGNMENTS.md`
- `planning/SECTOR_SCHEMA.md`
- `docs/VERSIONING.md` (branch model + §Branch Discipline + §Future Migrations + rollback runbook)
- `docs/sectors/M1.S1-bootstrap.md` (sector detail; `-bootstrap` suffix per Critic amendment #6)
- `.beads/` (initialize via `bd init` at host root)
- `.gitignore` (EDIT — keep `.beads/issues/` tracked, ignore `.beads/db/`)

**MILESTONES.md row format** (Critic amendment #5 — drop redundant prefix):
```
| Status | ID    | Plugin       | Title                              | Bd     | Detail                              |
|--------|-------|--------------|------------------------------------|--------|-------------------------------------|
| [ ]    | M1.S1 | SamplePlugin | Add LogSamplePlugin startup log    | samp-1 | docs/sectors/M1.S1-bootstrap.md     |
```

**Root `CLAUDE.md` ownership table** (verbatim header):

| Concern | Owner |
|---|---|
| Push protocol | Root `CLAUDE.md` |
| Skill registry (4 clusters: ralph+verify, deep-interview→ralplan→autopilot, external-context+document-specialist, team/ultrawork) | Root `CLAUDE.md` |
| Manager-agent prompt | Root `CLAUDE.md` |
| Sector convention | Root `CLAUDE.md` |
| Beads block + hooksPath workaround | Root `CLAUDE.md` |
| Build/test commands | Root `CLAUDE.md` |
| Versioning summary (1 paragraph) | Root `CLAUDE.md` (link → `docs/VERSIONING.md`) |
| Versioning detail | `docs/VERSIONING.md` |
| Plugin-specific consumer description | per-plugin `README.md` (AC6) |

**`docs/VERSIONING.md` sections:** Branch Model (`main`/`dev`/`exp/<topic>`); SemVer Tagging (FF-only); SHA Pinning Contract; §Branch Discipline (no rebase on `dev` after most-recent `v*` tag without coordinated `main` reset); Rollback Runbook (close UE editor → `git checkout <tag>` in submodule → delete `HostProject/Binaries/` + `HostProject/Intermediate/` → `regenerate.ps1`); §Future Migrations (concrete `Get-ChildItem HostProject/Plugins -Directory` triggers for MILESTONES split, per-plugin CLAUDE.md, `.beads-plugin/` pattern).

**ACs touched:** AC3, AC4, AC5.

**Verification:** `Test-Path` each file; architect-agent review of `docs/VERSIONING.md`.

---

### P2 — Manager-agent + transactional `scripts/sector-commit.ps1`

**File:** `scripts/sector-commit.ps1` (CREATE)

**Contract:**
```
Params: -Plugin <name> -SectorId <M.S> -BdId <id> [-DryRun]
Preconditions: plugin tree clean, on dev, sector edits already staged+committed locally in plugin
```

**Atomic flow** (binding amendments #1, #2, #3 baked in):

1. `$pluginSha = git -C HostProject/Plugins/<Plugin> rev-parse HEAD`
2. `git -C HostProject/Plugins/<Plugin> push origin dev` — failure → exit 10, no host changes, log to `.omc/logs/`.
3. **Verify push (Critic amendment #3):** `$remoteSha = (git -C HostProject/Plugins/<Plugin> ls-remote origin refs/heads/dev) -split '\s+' | Select-Object -First 1` ; if `$remoteSha -ne $pluginSha` → exit 11.
4. **Capture host SHA before commit (Critic amendment #1):** `$preCommitSha = git rev-parse HEAD`
5. `git add HostProject/Plugins/<Plugin>` ; `git commit -m "pin: <Plugin>@$pluginSha (sector $SectorId, bd:$BdId)"`
6. `git push origin <current-host-branch>` — on failure-mode-(c):
   - **Critic amendment #2:** `git fetch` ; if upstream has advanced since `$preCommitSha` → exit 12 with prompt "remote advanced; auto-reset refused. Manual recovery: `git reflog`; reset to `$preCommitSha` after reconciling."
   - Otherwise: `git reset --hard $preCommitSha` (NEVER `HEAD~1`), exit 12 (clean recovery).
   - If push partially succeeded (host commit on remote): exit 13, write manual remediation prompt.
7. `bd close <BdId>` — only after step 6 succeeds.
8. Print "Continue to next sector?" prompt.

**Smoke-test fixture:** `tests/sector-commit/` + `.omc/research/sector-commit-fixture/` (bare-repo simulating modes a/b/c).

**Manager-agent block in `CLAUDE.md`:** invokes script by exit code; does NOT open-code git sequence.

**ACs touched:** AC1.

**Verification:** fixture runs all three failure modes; architect-agent review of script (<200 lines).

---

### P3 — bd integration + seed issues

- `bd init` at host root.
- Seed: `samp-1` (M1.S1 LogSamplePlugin), `samp-2` (M1.S2 tag v0.1.0 + AC2 prep), `host-1` (verify regenerate.ps1 post-edit). Labels: `plugin:SamplePlugin`, `sector:M1.S1`, `ac:AC1`.
- `CLAUDE.md` beads block: install link, `bd prime`/`ready`/`close`, hooksPath swap workaround verbatim from live-telemetry, label conventions.
- **Principle-violation note** (Q2 deferred-S3): bd issues for plugin-internal work currently live in host-root `.beads/`; migration trigger at N≥2 → evaluate `.beads-plugin/` manifest pattern.

**ACs touched:** AC1, AC3.

---

### P4 — `scripts/plugin-version.ps1` (FF-only)

**Flow:**
- `git -C <plugin> checkout main`
- `git -C <plugin> merge --ff-only dev` — divergence → exit 20 with message: `"main has diverged from dev for plugin '$Plugin' — see docs/VERSIONING.md §Branch Discipline."`
- `$nextVer` from `git describe --tags --abbrev=0 main` + `-Bump <patch|minor|major>`
- `git -C <plugin> tag -a $nextVer <devShaResolvedBeforeMerge> -m "<Plugin> $nextVer"`
- `git -C <plugin> push origin main --follow-tags` ; `git -C <plugin> push origin dev`

**ACs touched:** AC2 (rollback prereqs), AC4.

**Verification:** dry-run on `SamplePlugin`; `tag --list` shows `v0.0.1` baseline + `v0.1.0` after demo.

---

### P5 — AC1 demo: M1.S1 `LogSamplePlugin` startup log

**Files (executor will edit during P5b):**
- `HostProject/Plugins/SamplePlugin/Source/SamplePlugin/Public/SamplePlugin.h` — `DECLARE_LOG_CATEGORY_EXTERN(LogSamplePlugin, Log, All)`
- `HostProject/Plugins/SamplePlugin/Source/SamplePlugin/Private/SamplePlugin.cpp` — `DEFINE_LOG_CATEGORY(LogSamplePlugin)` + `UE_LOG(LogSamplePlugin, Log, TEXT("SamplePlugin started"));` in `StartupModule()`

**P5a — Pre-stage validation** (binding):

**Precondition (Critic amendment #4):** `Get-Process UnrealEditor -ErrorAction SilentlyContinue` must return null. If editor is running → exit 13 with prompt "Close UE editor before branch switch."

1. `git -C HostProject/Plugins/SamplePlugin checkout dev`
2. `git -C HostProject/Plugins/SamplePlugin checkout -b exp/m1s1-prestage`
3. Apply real C++ edit (above).
4. `scripts/regenerate.ps1` — must succeed.
5. Compile via `Build.bat HostProjectEditor Win64 Development -Project=...HostProject.uproject` — must exit 0.
6. Open `HostProject.uproject` ; verify `LogSamplePlugin started` in Output Log on PIE start ; capture `.omc/research/ac1-prestage-evidence.png`. Close editor.
7. Reset: `git checkout dev` ; `git branch -D exp/m1s1-prestage` ; `Get-Process UnrealEditor` must be null ; delete `HostProject/Binaries/` + `HostProject/Intermediate/`.
8. **Executed rollback dry-run** (validates AC2 prerequisites): re-create `exp/m1s1-prestage` with edit; tag local `v0.1.0-prestage` ; `git checkout v0.0.1` ; `regenerate.ps1` ; confirm log line absent ; delete local prestage tag ; restore `dev`.

**P5b — `next` demo:**
- Run `next` from host root → manager-agent picks `samp-1` → ralph re-applies edit on `dev` → architect/critic verifier confirms log line → `scripts/sector-commit.ps1` runs → both pushes succeed → "Continue?" prompt.

**ACs touched:** AC1 (full pipeline demo), AC2 (prereqs validated).

**Verification:** P5a screenshot + P5b transcript captured to `.omc/research/ac1-demo-transcript.md`.

---

### P6 — AC2 rollback verification

**Precondition:** P5a executed-rollback-dry-run succeeded.

- After P5b lands and `v0.1.0` tagged on plugin `main`: close UE editor ; `git -C HostProject/Plugins/SamplePlugin checkout v0.0.1` ; delete `HostProject/Binaries/` + `Intermediate/` ; `scripts/regenerate.ps1` ; open editor ; confirm Output Log lacks `LogSamplePlugin`.
- Verify `git -C . status` from host root shows submodule as "modified content" (HEAD moved) but no host commit until explicit pin.
- Restore: close editor ; `git checkout v0.1.0`.

**ACs touched:** AC2.

**Evidence:** `.omc/research/ac2-rollback-evidence.md`.

---

### P7 — AC6 minimum non-coder README stub

**Files:**
- `HostProject/Plugins/SamplePlugin/README.md` (CREATE) — plain-language "What is SamplePlugin?" / "How to enable" / "Quick test (look for LogSamplePlugin)" / link to host repo.
- `HostProject/Plugins/SamplePlugin/SamplePlugin.uplugin` (EDIT — populate `Description` field matching README h1 subtitle).

**ACs touched:** AC6.

**Verification:** UE Plugin Browser shows description; manual non-coder smoke test.

---

## ADR

**Decision:** Single-root `planning/MILESTONES.md`; root-only `CLAUDE.md`; host-root `.beads/` (with explicit principle-violation note); deterministic order-driven manager-agent invoking transactional `scripts/sector-commit.ps1`; FF-only plugin-version promotion; M1.S1 = `LogSamplePlugin` startup log, pre-staged and rollback-validated before the `next` demo.

**Drivers:** AC1 atomicity, brownfield preservation, mixed-audience scaling, single-plugin reality.

**Alternatives considered:** Hybrid MILESTONES (rejected — over-engineered at N=1); per-plugin CLAUDE.md (rejected — drift risk); per-plugin `.beads/` (rejected — no federation, hooks fight submodule); open-coded dual-push prose (rejected — push protocol is non-negotiable, must be in script); cold-first-run AC1 demo (rejected — conflates workflow vs. toolchain bugs); non-FF merge to `main` (rejected — breaks SHA-tag equality).

**Why chosen:** Each decision either reduces scope to current N=1 reality, encodes implicit operational risk into explicit script logic, or pre-validates a critical demo path.

**Consequences:** `sector-commit.ps1` is load-bearing (R6 mitigation: smoke fixture + architect review). FF-only requires `dev`-history discipline (R7: §Branch Discipline doc + deferred pre-push hook). P5a creates "next always succeeds" cargo-cult risk (R8: explicit "bootstrap-only" filename + CLAUDE.md note).

**Follow-ups (deferred to plugin #2):** `scripts/migrate-milestones-hybrid.ps1`, `scripts/migrate-claudemd-perplugin.ps1`, `scripts/import-plugin-bd.ps1`, `dev`-branch pre-push hook.

---

## Executor Constraints (binding amendments — no deviation without new ADR)

1. **(c)-failure recovery:** capture `$preCommitSha = git rev-parse HEAD` BEFORE host commit; on failure-mode-(c) `git reset --hard $preCommitSha`, NEVER `HEAD~1`.
2. **Auto-reset gate:** `git fetch` first; if upstream advanced since `$preCommitSha`, refuse auto-reset and emit exit 12 with `git reflog` recovery hint.
3. **ls-remote:** use `git ls-remote origin refs/heads/dev` and string-compare returned SHA to `$pluginSha`. Never `ls-remote origin <bare-sha>`.
4. **UE editor closed before branch switch:** P5a step 1 and P6 first action MUST `Get-Process UnrealEditor -ErrorAction SilentlyContinue` and abort with exit 13 if non-null.
5. **MILESTONES column 2:** drop `<Plugin>:` prefix from ID column; plugin name lives only in column 3.
6. **Bootstrap filename:** `docs/sectors/M1.S1-bootstrap.md`, not `M1.S1.md`.

---

## Risk Table (final)

| # | Risk | Status | Mitigation |
|---|---|---|---|
| R1 | bd hooks fight submodule boundary | RESOLVED | sector-commit.ps1 enforces `bd close` after host push; hooksPath workaround documented |
| R2 | PowerShell scripts break from non-host cwd | OPEN | `Push-Location` host root + `Test-Path 'HostProject/HostProject.uproject'` guard |
| R3 | SHA pin / plugin push race | RESOLVED | Mandatory `ls-remote refs/heads/dev` SHA-equality check before host commit |
| R4 | UE5 Live Coding caches old binaries | OPEN | AC2 runbook deletes `Binaries/`+`Intermediate/`; P5a pre-validates procedure; editor-closed precondition |
| R5 | Two MILESTONES drift | DOWNGRADED | N/A at N=1; migration runbook addresses at N≥2 |
| R6 | sector-commit.ps1 load-bearing | NEW | Smoke fixture in `.omc/research/sector-commit-fixture/`; architect review (<200 lines) |
| R7 | FF-only requires dev discipline | NEW | §Branch Discipline doc + plugin-version.ps1 divergence error + deferred pre-push hook |
| R8 | P5a cargo-cult | NEW | `-bootstrap` filename suffix + explicit CLAUDE.md note: "future sectors run `next` cold" |

---

## Handoff to Autopilot

This plan replaces autopilot Phase 0 (Expansion) and Phase 1 (Planning). Autopilot starts at **Phase 2 (Execution)** with:
- Phase order: P1 → P2 → P3 → P4 → P5a → P5b → P6 → P7
- Gating: each phase must pass its Verification before next phase runs
- Verifier: architect agent for `docs/VERSIONING.md`, `sector-commit.ps1`, P5b transcript
- Push protocol: `scripts/sector-commit.ps1` for sector commits; standard `git push` for scaffolding commits (P1-P4, P7)
- Acceptance: AC1-AC6 from spec, all six binding amendments enforced
