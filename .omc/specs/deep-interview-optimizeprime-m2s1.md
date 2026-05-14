# Deep Interview Spec: optimizePrime — Scene Heaviness Analyzer (UE5)

> **Sector:** M2.S1 (v0.1.0 vertical slice)
> **Mirrored from:** `C:\Users\Windows-10\.claude\plans\pluging-zazzy-acorn.md`
> **Naming convention:** matches `.omc/specs/deep-interview-project-environment.md`

## Context

`optimizePrime` is a new UE5 plugin to be added to the `Unreal_Nice_Plugins` host
repo as the second plugin (alongside `SamplePlugin`). Its purpose is to help
3D artists, tech artists, and tech directors identify and fix the causes of
"heavy scenes" in Virtual Production, Broadcast, and Game projects — scenes
where FPS drops because of high-vertex meshes, non-Nanite-eligible meshes,
expensive Shadow Depth / Prepass / Base pass cost, RT geometry pool overflow,
and texture streaming pool overflow.

The interview clarified that the plugin grows in five tagged phases. v0.1.0
is a deliberately small **vertical slice** that proves the end-to-end
architecture (Slate panel → analyzer service → UMG report widget) using only
the simplest analyzer (mesh vertex count). Subsequent sectors widen
coverage one heaviness category per sector, then add diagnostic actions in
M2.S6+, then add safe-fix toggles in M3.S1+.

This spec covers **M2.S1 only** (the v0.1.0 sector). M2.S2–S5 are sketched
as roadmap for context but their detailed sector docs come later.

## Metadata

| Field | Value |
|---|---|
| Interview ID | deep-interview-optimizePrime-v1 |
| Sector | M2.S1 |
| Plugin Tag | v0.1.0 |
| Rounds | 5 |
| Final Ambiguity Score | **16.5%** |
| Threshold | 20% |
| Type | brownfield (host repo exists; new plugin submodule) |
| Generated | 2026-05-08 |
| Status | PASSED (under threshold) |

## Clarity Breakdown

| Dimension | Score | Weight | Weighted |
|---|---|---|---|
| Goal Clarity | 0.95 | 0.35 | 0.333 |
| Constraint Clarity | 0.85 | 0.25 | 0.213 |
| Success Criteria | 0.65 | 0.25 | 0.163 |
| Context Clarity | 0.85 | 0.15 | 0.128 |
| **Total Clarity** | | | **0.835** |
| **Ambiguity** | | | **0.165 (16.5%)** |

## Goal

Build `optimizePrime`, a UE 5.6 editor plugin that analyzes the open editor
scene and surfaces its heaviness causes via a Slate-anchored panel + UMG
report widget, with a phased roadmap toward an artist-friendly safe-fix
suite.

**v0.1.0 (M2.S1) goal:** Ship a working vertical slice — clicking "Scan
Scene" in the OptimizePrime panel produces a UMG-rendered report listing the
top-10 heaviest static meshes in the current editor world (by vertex count).
This proves the architecture (Slate ↔ analyzer service ↔ UMG widget) and
the host repo's submodule + sector-commit workflow for the new plugin.

## Constraints

- **Engine:** UE 5.6 (matches host `HostProject.uproject`)
- **Host repo workflow:** Plugin lives at `HostProject/Plugins/optimizePrime/`
  as a new git submodule with `main` / `dev` / `exp/*` branches
- **UI surface:** Hybrid — Slate panel (engine-API anchor + invocation) +
  UMG Editor Utility Widget (visualization layer)
- **Scan cadence:** Manual button only in v1 (`Scan Scene`); no live
  monitoring, no auto-rescan in v0.1.0
- **Target user:** Both Artist (default) and Tech Artist / Tech Director
  via a mode toggle (Artist mode = plain language + icons + color severity;
  Advanced mode = exposes raw stats and jargon)
- **Sector size:** M2.S1 must be **atomic** — scaffold + Slate panel + UMG
  shell + ONE category (mesh vertex count) end-to-end, nothing more
- **"Safe" is a north star value** (user emphasized twice during interview):
  v1 is read-only; future fix features must be undo-tracked + dry-run
- **Module type:** Editor-only (mirrors `SamplePlugin.uplugin`: Type=Editor,
  LoadingPhase=Default) — DEFAULT, ack at sector review if hybrid needed
- **Build deps (Phase 1):** `Core, CoreUObject, Engine, Slate, SlateCore,
  UnrealEd, ToolMenus, Projects, EditorFramework, UMG, UMGEditor, Blutility,
  EditorScriptingUtilities` — DEFAULT list

## Non-Goals (v0.1.0 explicit exclusions)

- Auto-fixing anything (no buttons that mutate scene/assets)
- Live / background monitoring (no per-frame ticks)
- Runtime (PIE / packaged build) analysis — Editor world only
- Categories beyond mesh vertex count (Nanite eligibility, render-pass cost,
  RT geometry pool, texture streaming pool, output-log warning interpretation
  are all M2.S2 → M2.S5)
- Diagnostic actions (select-in-viewport, jump-to-asset, CSV export) —
  those are M2.S6+
- Skeletal mesh / particle / Niagara analysis (Phase 1 = static meshes only)
- Cross-level analysis (only the currently-open editor world)

## Acceptance Criteria (M2.S1, v0.1.0)

- **AC1** — `HostProject/Plugins/optimizePrime/` exists as a tracked git
  submodule with its own remote, branches `main` and `dev`, and tag `v0.1.0`
  on `main` (FF-only from `dev` per `docs/VERSIONING.md`)
- **AC2** — `optimizePrime.uplugin` declares one Editor module
  `OptimizePrime` (LoadingPhase=Default), with the Build.cs deps listed
  under Constraints
- **AC3** — `scripts/regenerate.ps1` regenerates the .sln cleanly with
  the new plugin present (no errors); editor compiles and opens
- **AC4** — A new menu item `Window → OptimizePrime` appears in the
  UE Editor and opens a docked Slate tab titled "OptimizePrime"
- **AC5** — The Slate tab contains: a `Scan Scene` button, a `Mode`
  toggle (Artist / Advanced — visual difference is sufficient for v1, full
  jargon-vs-plain content variation can be M2.S2 polish), and an embedded
  UMG report widget area
- **AC6** — Clicking `Scan Scene` enumerates all `AStaticMeshActor`
  instances in the current editor world, computes total triangle (or
  vertex) count per actor, and sends a `FOptimizePrimeReport` to the UMG
  widget
- **AC7** — The UMG widget renders a list of the **top-10 heaviest**
  static mesh actors (descending by vertex count), each row showing actor
  label, mesh asset name, vertex count, and a color-coded severity badge
  (green/yellow/red) based on configurable thresholds (DEFAULT: 50k / 250k
  vertices)
- **AC8** — Plugin emits one `LogOptimizePrime` info line on module
  startup so a smoke test is grep-able in `Saved/Logs/HostProject.log`
- **AC9** — `scripts/sector-commit.ps1 -Plugin optimizePrime
  -SectorId M2.S1 -BdId <bd-id>` completes with exit code 0 (plugin push
  + host pin commit + bd close)
- **AC10** — `docs/sectors/M2.S1.md` exists with sections matching
  the existing M1.S2 format (Plugin / DoD / File edits / Verification /
  Tag Bump / ACs Touched / Notes) and `planning/MILESTONES.md` row for
  M2.S1 is marked `[x]` after sector-commit succeeds

## Roadmap (post-M2.S1, sketched only)

| Sector | Tag | Theme |
|---|---|---|
| M2.S2 | v0.2.0 | Add **Nanite eligibility analyzer** (translucent material, deformation, WPO, etc. as Nanite-blocking reasons) |
| M2.S3 | v0.3.0 | Add **render-pass cost analyzer** (Shadow Depth / Prepass / Base pass via stat unit + GPU profiler) |
| M2.S4 | v0.4.0 | Add **texture streaming pool + RT geometry pool** stats with threshold warnings |
| M2.S5 | v0.5.0 | Add **output-log warning interpreter** (parse + categorize + suggestion knowledge base) |
| M2.S6+ | v0.6.0+ | **Phase 2 — Diagnostic Actions:** select-in-viewport, jump-to-asset, copy-stats, CSV export |
| M3.S1+ | v1.0.0+ | **Phase 3 — Safe-fix toggles** per category (dry-run, undo-tracked) |

## Assumptions Exposed & Resolved

| Assumption | Challenge / Probe | Resolution |
|---|---|---|
| "v1 = full optimization suite" | Round 1 ontology question — what IS v1? | v1 = Analyzer + Diagnostic Actions (read-only); fix suite is phased to M3 |
| "All 5 heaviness categories in v1" | Round 3 sub-scope question | Vertical slice: 1 category in M2.S1, 4 more sectors deepen one-per-sector |
| "Plain Slate panel is enough" | Round 2 surface question | Hybrid Slate + UMG — Slate for engine-API access, UMG for artist-friendly visualization |
| "Live monitor like Stat Unit" | Round 5 cadence question | Manual button only in v1 — predictable, no frame-budget hit |
| "Artist-only UX" | Round 5 persona question | Both Artist and TA via mode toggle |

## Technical Context (Host Repo)

- **Host root:** `e:\[Claude_Project]\Unreal_Nice_Plugins`
- **UE version:** 5.6 (`HostProject/HostProject.uproject` EngineAssociation = 5.6)
- **Reference plugin template:** `HostProject/Plugins/SamplePlugin/` (Editor
  module, Type=Editor, LoadingPhase=Default, Slate-based with ToolMenus)
- **Sector workflow files:**
  - `planning/MILESTONES.md` — needs new row for M2.S1 (and M2.S2–S5
    optionally as `[ ]` placeholders)
  - `planning/TASK_ASSIGNMENTS.md` — needs ownership entry
  - `docs/sectors/M2.S1.md` — new file, follows M1.S2 format
- **Scripts:**
  - `scripts/new-plugin.ps1` (or `add-plugin.ps1`) — investigate first;
    likely scaffolds plugin + submodule init
  - `scripts/regenerate.ps1` — runs UE5.6 build batch to refresh .sln
  - `scripts/sector-commit.ps1` — transactional plugin push + host pin
    + bd close (DO NOT bypass)
  - `scripts/plugin-version.ps1` — FF-only tag promotion main ← dev
- **Beads (bd) tracker:** Create issue with labels
  `plugin:optimizePrime`, `sector:M2.S1`, `ac:AC1..AC10` before coding
  (per CLAUDE.md). Use `bd create` then `bd update <id> --claim`.
- **Push protocol:** `core.hooksPath` swap is automated by sector-commit.ps1

## Ontology (Key Entities — final round)

| Entity | Type | Fields | Relationships |
|---|---|---|---|
| OptimizePrime (plugin) | core domain | name, version, modules | contains AnalyzerService, AnalyzerPanel, ReportWidget |
| AnalyzerService | core domain | categoryProviders[], scanWorld() | produces SceneHeavinessReport |
| SceneHeavinessReport | core domain | timestamp, perCategoryRows[], topN | consumed by ReportWidget |
| CategoryProvider | architecture pattern | id, label, scan(world) → rows[] | implemented per heaviness category |
| MeshVertexProvider (M2.S1) | concrete provider | scan() returns top-N mesh rows | implements CategoryProvider |
| AnalyzerPanel | supporting (UI) | Slate tab, ScanButton, ModeToggle | invokes AnalyzerService, hosts ReportWidget |
| ReportWidget | supporting (UI) | UMG widget, severity rendering | renders SceneHeavinessReport |
| UserModeToggle | supporting | mode ∈ {Artist, Advanced} | drives ReportWidget rendering style |
| ScanTrigger | supporting | manualButton (v1) | future: levelLoad, periodicTimer |
| DiagnosticAction (deferred) | supporting | label, perform() | M2.S6+ |
| Warning (deferred) | supporting | severity, sourceLog, fixRecipe | M2.S5 |

## Ontology Convergence

| Round | Entity Count | New | Changed | Stable | Stability |
|---|---|---|---|---|---|
| 1 | 5 | 5 | - | - | N/A |
| 2 | 7 | 2 (AnalyzerPanel, ReportWidget) | 0 | 5 | 71% |
| 3 | 7 | 0 | 0 | 7 | 100% |
| 4 | 8 | 1 (CategoryProvider) | 0 | 7 | 88% |
| 5 | 9–11 | 2 (UserModeToggle, ScanTrigger; +MeshVertexProvider as concrete) | 0 | 8 | ~89% |

The model converged by round 3 with stable supporting additions only —
no entity was removed or renamed across rounds. The dominant pattern
that emerged was `CategoryProvider` as the extension point, which keeps
M2.S2–S5 architecturally cheap (each new category = one new provider).

## Critical Files to be Created / Modified (M2.S1)

**New files (inside the new submodule):**
- `HostProject/Plugins/optimizePrime/optimizePrime.uplugin`
- `HostProject/Plugins/optimizePrime/Source/OptimizePrime/OptimizePrime.Build.cs`
- `HostProject/Plugins/optimizePrime/Source/OptimizePrime/Public/OptimizePrime.h`
- `HostProject/Plugins/optimizePrime/Source/OptimizePrime/Private/OptimizePrime.cpp` (module + LogOptimizePrime + ToolMenu hook)
- `HostProject/Plugins/optimizePrime/Source/OptimizePrime/Private/AnalyzerService.{h,cpp}`
- `HostProject/Plugins/optimizePrime/Source/OptimizePrime/Private/Providers/MeshVertexProvider.{h,cpp}`
- `HostProject/Plugins/optimizePrime/Source/OptimizePrime/Private/UI/SOptimizePrimePanel.{h,cpp}` (Slate)
- `HostProject/Plugins/optimizePrime/Content/EUW_OptimizePrimeReport.uasset` (UMG Editor Utility Widget — author from editor)

**Modified files (host repo):**
- `planning/MILESTONES.md` — add M2.S1 row
- `planning/TASK_ASSIGNMENTS.md` — claim entry
- `docs/sectors/M2.S1.md` — new sector doc (mirrors M1.S2 format)

**Reused conventions / patterns (do NOT reinvent):**
- `HostProject/Plugins/SamplePlugin/Source/SamplePlugin/Private/SamplePlugin.cpp` — module Startup/Shutdown + ToolMenus pattern
- `scripts/sector-commit.ps1` — only sanctioned push path
- `scripts/regenerate.ps1` — only sanctioned .sln regen path
- `docs/sectors/M1.S2.md` — sector doc structure template

## Verification (end-to-end)

1. **Submodule sanity:** `git -C HostProject/Plugins/optimizePrime status`
   shows clean tree on `dev` after sector ralph; `git submodule status`
   from host root shows the new pin.
2. **Regenerate:** `scripts/regenerate.ps1` exits 0; `HostProject.sln`
   contains an `optimizePrime` project.
3. **Compile + open:** Double-click `HostProject.uproject`, accept rebuild
   prompt; editor opens without errors. Check `Saved/Logs/HostProject.log`
   for `LogOptimizePrime` startup line (AC8).
4. **UI smoke test:** `Window → OptimizePrime` opens the docked Slate tab
   (AC4). The tab shows `Scan Scene` button, mode toggle, and embedded
   UMG widget area (AC5).
5. **Functional test:** Open a level with ≥10 `AStaticMeshActor`s; click
   `Scan Scene`; verify the UMG widget shows top-10 sorted by vertex
   count with severity badges (AC6, AC7). Test in an empty level → widget
   shows "no static meshes found" gracefully.
6. **Sector commit:** Run
   `scripts/sector-commit.ps1 -Plugin optimizePrime -SectorId M2.S1 -BdId <id>`
   from host root. Exit code must be 0. Verify on remote that both pushes
   landed (plugin `dev` + host branch). Verify `planning/MILESTONES.md`
   marks M2.S1 `[x]` after the host commit.
7. **Tag bump:** From inside the plugin submodule on `main` after
   FF-merge from `dev`, run `scripts/plugin-version.ps1 -Tag v0.1.0`;
   tag exists and is pushed.

## Open Items (DEFAULTs to confirm at sector-doc review, NOT blockers)

| # | Default | Override if… |
|---|---|---|
| 1 | Top-10 by vertex count | …user prefers top-N where N is configurable, or threshold-based (`> Xk verts`) |
| 2 | Severity bands: 50k / 250k vertices | …user has hardware/profile-specific thresholds in mind |
| 3 | Module type: Editor-only (matches SamplePlugin) | …a Runtime-side stat collector is wanted later (would need module split) |
| 4 | Mode toggle visual-only in v0.1.0 | …user wants full plain-vs-jargon content variation in M2.S1 (would slightly enlarge sector) |
| 5 | Triangle vs vertex count metric — pick **vertex** count for M2.S1 (matches the user's wording in the original prompt: "verticies เยอะมาก") | …user prefers tris (more standard for GPU cost reasoning) |
| 6 | UMG widget authored from editor (`EUW_OptimizePrimeReport.uasset`) and shipped in `Content/` | …user prefers C++-defined widget with no `.uasset` (purer code, harder to iterate) |

---

> **Next step:** ralplan consensus refine (Planner / Architect / Critic) →
> output to `.omc/plans/consensus-optimizeprime-m2s1.md`.
