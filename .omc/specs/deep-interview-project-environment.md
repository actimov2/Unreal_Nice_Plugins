# Deep Interview Spec: Project Environment for Unreal_Nice_Plugins

## Metadata
- Interview ID: di-unreal-env-2026-05-07
- Rounds: 6
- Final Ambiguity Score: 17%
- Type: brownfield
- Generated: 2026-05-07
- Threshold: 0.20
- Status: PASSED

## Clarity Breakdown
| Dimension | Score | Weight | Weighted |
|---|---|---|---|
| Goal | 0.92 | 0.35 | 0.322 |
| Constraints | 0.85 | 0.25 | 0.213 |
| Criteria | 0.85 | 0.25 | 0.213 |
| Context | 0.55 | 0.15 | 0.083 |
| **Total Clarity** | | | **0.831** |
| **Ambiguity** | | | **0.169** |

## Goal

Stand up a project environment for `Unreal_Nice_Plugins` (UE5.6+ plugin monorepo) whose **spine** is integrating the live-telemetry-overlay workflow vibe, and whose **pillar** is a non-destructive plugin versioning model. Team install polish and non-coder docs are deferred future milestones, not gates for this initiative.

## Pillars (priority order)

1. **Workflow Integration (SPINE, in scope now)** — clone live-telemetry's full workflow:
   - Sector milestone system (`MILESTONES.md` with M1.S1 → MX.SY ordering per plugin)
   - Manager-agent pattern triggered by `start` / `next`
   - Ralph loop per sector + architect/critic verifier before completion
   - `bd` (beads) external issue tracker (replaces TodoWrite/notepad for sector tracking)
   - Mandatory push-or-not-done session-close protocol with handoff prompt
2. **Non-Destructive Versioning (PILLAR, in scope now)** — per-plugin submodule branch model:
   - `main` branch = stable; semver tags (`v1.0.0`, `v1.1.0`, …) live here
   - `dev` branch = active work
   - `exp/<topic>` branches for risky experiments; ralph-verifier gates `exp → dev`
   - HostProject pins SHAs (never floating refs)
   - Rollback = `git checkout <tag>` inside the plugin submodule
3. **Team Install (DEFERRED)** — reserved as late milestone (M-late). Mixed audience: near-term known consumers + eventual public release. Design install scaffolding to scale outward later, but do **not** invest now beyond what already exists (`SETUP.md`, `scripts/`).
4. **Non-Coder Docs (DEFERRED, with minimum stub)** — minimum stub: per-plugin `README.md` rendered in UE Plugin Browser. Full in-editor tutorial deferred.

## Constraints

- UE 5.6+, Windows 10/11, Visual Studio 2022, PowerShell as primary scripting shell.
- Existing repo state preserved: do not delete `SETUP.md`, `scripts/new-plugin.ps1`, `scripts/add-plugin.ps1`, `scripts/regenerate.ps1`, `.vscode/tasks.json`, or current submodule (`HostProject/Plugins/SamplePlugin`).
- `bd` (beads) CLI added as external dependency; `.beads/` folder committed; document install in `CLAUDE.md`.
- Engineering-tone `CLAUDE.md` (root) — not user-friendly Thai mixed prose like current README; pure engineering-style instructions for Claude Code.
- Audience model: **Mixed** (near-term known consumers + future public release). Design now for known group; install/docs scale later.
- Skills committed as core dependencies (referenced from `CLAUDE.md`):
  - `oh-my-claudecode:ralph` + `oh-my-claudecode:verify` (spine executor)
  - `oh-my-claudecode:deep-interview` → `oh-my-claudecode:ralplan` → `oh-my-claudecode:autopilot` (planning chain)
  - `oh-my-claudecode:external-context` + `document-specialist` agent (UE5 docs lookup — addresses "technical support" need)
  - `oh-my-claudecode:team` + `oh-my-claudecode:ultrawork` (multi-plugin parallel execution, used selectively)

## Non-Goals (this initiative)

- No teammate-onboarding polish beyond what `SETUP.md` already provides.
- No in-editor tutorial widget (UE UMG tutorial blueprint) — only README stub.
- No CI/CD, no Marketplace packaging, no auto-build of `.upack` artifacts.
- No worktree-per-experiment infrastructure (rejected R3 — fights UE5 single-`.uproject` model).
- No replacement of existing PowerShell scripts; we add to them, not rewrite.

## Acceptance Criteria

- [ ] **AC1 (Pillar 1 spine demo):** Typing `next` in Claude inside repo root: reads a real `planning/MILESTONES.md` → finds next incomplete sector → spawns ralph with architect/critic verifier → on success, sector commit lands on the affected plugin's `dev` branch → `bd close <ticket>` runs → `git push` succeeds for both host repo and plugin submodule → user sees "Continue to next sector?" prompt.
- [ ] **AC2 (Pillar 2 rollback demo):** With at least one semver tag on `main` of `SamplePlugin`, running `git checkout v0.1.0` inside the submodule (followed by `regenerate.ps1` + UE editor open) launches the editor with the older plugin behavior. HostProject's pinned SHA still reflects the previous head (i.e., rollback inside submodule does not mutate host pin until explicitly committed).
- [ ] **AC3 (Workflow files exist):** `planning/MILESTONES.md`, `planning/TASK_ASSIGNMENTS.md`, `.beads/` initialized, `CLAUDE.md` (engineering-tone, with manager-agent prompt + skill registry + push protocol), and at minimum one populated sector ready for AC1.
- [ ] **AC4 (Versioning convention codified):** `docs/WORKFLOW.md` (or new `docs/VERSIONING.md`) documents `main`/`dev`/`exp/*` branch model, semver tagging rules, and how HostProject pins SHAs. Verified by an architect agent reviewing the doc.
- [ ] **AC5 (Skills documented):** `CLAUDE.md` includes a "Committed Skills" section listing the 4 skill clusters (ralph+verify; deep-interview→ralplan→autopilot; external-context+document-specialist; team/ultrawork) with one-line purpose each.
- [ ] **AC6 (Minimum non-coder stub):** `HostProject/Plugins/SamplePlugin/README.md` renders meaningfully in UE Plugin Browser description field; non-coder reader knows what the plugin does and how to enable it. (Full in-editor tutorial deferred.)

## Assumptions Exposed & Resolved

| Assumption | Challenge | Resolution |
|---|---|---|
| "Workflow integration" is one thing | Decomposed into 5 mechanisms (R2) | All 5 adopted; each is independently configurable |
| "Non-destructive" implied worktrees | Worktrees fight UE5 single-`.uproject` model (R3 contrarian) | Rejected worktrees; chose branch-model + exp branches |
| "Team install" is current pain | No teammates currently pull repo (R4 contrarian) | Audience = mixed; team install deferred to later milestone |
| All 4 mechanisms must ship day-1 | Simplifier R6 challenged scope | All 4 confirmed core, no descoping; docs/install descoped instead |
| Skills are nice-to-have | R6 forced commitment | 4 skill clusters committed as documented dependencies |

## Technical Context

**Existing scaffold (preserved):**
- `HostProject/HostProject.uproject` + `Source/` + `Config/`
- `HostProject/Plugins/SamplePlugin/` (git submodule → `actimov2/SamplePlugin` private)
- `scripts/new-plugin.ps1`, `scripts/add-plugin.ps1`, `scripts/regenerate.ps1`
- `.vscode/tasks.json`, `.clang-format`, `.editorconfig`, `.gitignore`
- `README.md` (Thai-mixed, user-facing) + `SETUP.md` (Thai, user-facing) — keep, do not engineering-ize these

**Reference workflow (live-telemetry-overlay):**
- `CLAUDE.md` engineering-tone with manager-agent block, sector order, beads integration block, mandatory push protocol
- Sector convention M{milestone}.S{sector}; commits atomic per sector
- `bd prime`, `bd ready`, `bd close` as task-tracking commands
- `planning/MILESTONES.md` + `planning/TASK_ASSIGNMENTS.md` as source-of-truth files

**Mapping to UE5 plugin monorepo (NEW design work for this initiative):**
- One `MILESTONES.md` may need to be per-plugin (live `HostProject/Plugins/<Plugin>/planning/`) plus a top-level meta `MILESTONES.md` for cross-plugin work — open question for ralplan to decide.
- Plugin submodules need their own `bd` instances or share host-repo `bd` — open question for ralplan.
- Manager-agent must know how to detect WHICH plugin's sector is next (host-level coordination).

## Ontology (Key Entities)

| Entity | Type | Fields | Relationships |
|---|---|---|---|
| WorkflowIntegration | core domain (spine) | mechanisms[], pillar=1 | composed of SectorMilestone, ManagerAgent, RalphLoop, BeadsTracker, SessionCloseProtocol |
| NonDestructiveVersioning | core domain (pillar) | branchModel, tagScheme | uses MainBranch, DevBranch, ExpBranch, SemverTag, SHAPin, VerifierGate |
| TeamInstall | deferred goal | audience=mixed | supports KnownConsumer, PublicRelease |
| NonCoderDocs | deferred goal (stub now) | readmeStub | supports KnownConsumer |
| SectorMilestone | mechanism | id (M.S), criteria | tracked in MILESTONES.md |
| ManagerAgent | mechanism | trigger=start\|next | invokes RalphLoop |
| RalphLoop | mechanism | verifier | gates dev merges |
| ArchitectVerifier | mechanism | role=quality-gate | child of RalphLoop |
| BeadsTracker | mechanism | cli=bd | replaces TodoWrite |
| SessionCloseProtocol | mechanism | rule=push-or-not-done | terminal step |
| MainBranch | git ref | per-plugin | holds SemverTag |
| DevBranch | git ref | per-plugin | merge target for ExpBranch |
| ExpBranch | git ref | exp/<topic> | gated by VerifierGate |
| SemverTag | label | vX.Y.Z | on MainBranch |
| SHAPin | reference | host pins plugin SHA | held by HostProject |
| KnownConsumer | audience | ~1–2 people, ~1mo | near-term |
| PublicRelease | audience | future, broad | scaling-target |
| LayeredCriteria | meta | per-pillar gates | shapes acceptance |
| RalphCore / VerifyCore | committed skill | required for spine | core dependency |
| PlanningChain | committed skill | deep-interview→ralplan→autopilot | core dependency |
| DocsLookup | committed skill | external-context + document-specialist | core dependency |
| ParallelExec | committed skill | team/ultrawork | core dependency, used selectively |

## Ontology Convergence

| Round | Entity Count | New | Changed | Stable | Stability |
|---|---|---|---|---|---|
| 1 | 6 | 6 | – | – | N/A |
| 2 | 11 | 6 | 0 | 5 | ~62% |
| 3 | 17 | 6 | 0 | 11 | ~70% |
| 4 | 19 | 2 | 0 | 17 | ~85% |
| 5 | 22 | 3 | 0 | 19 | ~88% |
| 6 | 27 | 5 | 0 | 22 | ~92% |

Domain model converged: tier-1 nouns (`WorkflowIntegration`, `NonDestructiveVersioning`, `TeamInstall`, `NonCoderDocs`) stable across all 6 rounds; new entities are children of existing tier-1 nouns.

## Open Questions for Ralplan

These are intentionally unresolved — they're design decisions better made by Planner+Architect+Critic consensus, not user interview:

1. **Per-plugin vs. host-level `MILESTONES.md`** — should each plugin submodule own its sectors, or does the host repo own a meta-MILESTONES that delegates?
2. **`bd` scope** — one `.beads/` at host root tracking all plugins, or per-plugin `.beads/`?
3. **Manager-agent plugin-detection logic** — how does `next` decide which plugin's sector is current when multiple are active?
4. **CLAUDE.md hierarchy** — root CLAUDE.md (engineering tone, this initiative) + per-plugin CLAUDE.md (plugin-specific) vs. single root file?
5. **Initial sector content for AC1 demo** — what's the smallest real sector on SamplePlugin that exercises the full pipeline?
