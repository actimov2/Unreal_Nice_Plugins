# Consensus Plan: OptimizePrime — Scene Heaviness Analyzer (M2.S1, v0.1.0)

- **Source spec:** `.omc/specs/deep-interview-optimizeprime-m2s1.md` (deep-interview, ambiguity 16.5%, 5 rounds)
- **Reference style:** mirrors `.omc/plans/consensus-project-environment.md`
- **Consensus mode:** ralplan SHORT, Planner draft (Architect / Critic to iterate)
- **Iteration:** 2 (revised after Architect REQUEST_REVISION + Critic ITERATE)
- **Verdict:** DRAFT — pending Architect re-review + Critic re-review
- **Generated:** 2026-05-08

---

## CHANGELOG (iteration 1 → iteration 2)

1. Plugin renamed `optimizePrime` → `OptimizePrime` (PascalCase) per script ValidatePattern; user-binding decision.
2. New explicit **P0** phase added: bd issue + branch reservation (extracted from old P5 prose).
3. Dropped `ICategoryProvider` interface — `FMeshVertexProvider` is free-standing in M2.S1.
4. Dropped UMG `.uasset` — pure-C++ `SHeavinessReportList` Slate widget; `CanContainContent: false`.
5. Dropped `UDeveloperSettings` / `Config/DefaultEditor.ini` — `static constexpr` thresholds in `MeshVertexProvider.cpp`.
6. Build.cs trimmed to 10 deps (was 14): removed `UMG, UMGEditor, Blutility, EditorScriptingUtilities, DeveloperSettings`.
7. ADR adds **bootstrap-exception subsection**: M2.S1 lands TWO host commits (`.gitmodules` from `new-plugin.ps1` + pin from `sector-commit.ps1`).
8. Q2 / Q3 / Q6 decisions inverted; ADR alternatives updated.
9. P3 `MeshVertexProvider.cpp` row explicitly null-guards `GetRenderData()` AND `LODResources.Num() > 0` (R-final).
10. Phase-gating sentence rewritten: P2-P4 verification bundled into P6; only P0/P1/P5/P6 have intrinsic gates.
11. Risk table collapsed (R1, R2, R3, R8 either obviated by rename / drop-UMG / drop-interface, or reduced to one verification step).
12. Sector-doc self-sufficiency checklist added to P5 (ralph reads `docs/sectors/M2.S1.md` ONLY).

---

## RALPLAN-DR Summary

### Principles

1. **Vertical slice over breadth** — M2.S1 ships ONE category end-to-end; widen later sectors, never this one.
2. **Mirror SamplePlugin** — module layout, Build.cs style, ToolMenus pattern, `CanContainContent: false` are templates, not invitations to redesign.
3. **Sanctioned scripts only** — `new-plugin.ps1` scaffolds the submodule; `regenerate.ps1` refreshes the .sln; `sector-commit.ps1` lands the dual push. No open-coded git submodule add, no manual host pin commit.
4. **Safe by default** — read-only analyzer; no scene mutation; UI surface is inert until `Scan Scene` is clicked. "Safe" is the explicit user value (twice in the interview).
5. **No speculative seams** — abstractions arrive when the second concrete impl arrives. Interfaces, settings classes, and UMG assets enter in M2.S2 polish, not M2.S1.

### Decision Drivers

1. **AC9 atomicity** — one plugin commit on `dev` (from P5) + one host pin commit (from `sector-commit.ps1`), both pushed. `new-plugin.ps1` lands an additional one-time `.gitmodules` host commit during P1; bootstrap exception documented in ADR.
2. **Ralph-purity** — every step is executable by a non-interactive ralph run except the single editor-smoke gate in P6. No editor-in-the-loop for asset authoring, settings editing, or UI iteration.
3. **Brownfield reality** — SamplePlugin is the live template. Pattern divergences (Window menu vs toolbar, `CanContainContent`) are explicit and minimal.

### Decisions

| # | Question | Choice | Rationale |
|---|---|---|---|
| Q1 | Plugin name | **`OptimizePrime` (PascalCase)** | `new-plugin.ps1` line 33 `ValidatePattern '^[A-Z][A-Za-z0-9]+$'` rejects camelCase. Original spec wording `optimizePrime` was a casual reference; PascalCase is the script-compatible form. One-time naming deviation flagged here. |
| Q2 | `ICategoryProvider` abstraction in v0.1.0 | **Drop** — `FMeshVertexProvider` is a free-standing class; `FAnalyzerService::ScanWorld()` calls `MeshProvider->Scan(...)` directly | Single-impl interface is speculative seam. M2.S2 mechanically introduces the interface when the second category arrives (Nanite). Saves ~40 LOC and one header in M2.S1. |
| Q3 | UMG widget storage | **Drop UMG entirely** — pure-C++ `SHeavinessReportList` (Slate `SListView<TSharedPtr<FHeavinessRow>>`); `CanContainContent: false` (matches SamplePlugin precedent) | UMG `.uasset` cannot be ralph-authored — forces editor-in-the-loop step. Pure Slate keeps M2.S1 ralph-pure. UMG migration is M2.S2 polish when the widget grows beyond a list. |
| Q4 | Module type | **Editor-only single module `OptimizePrime`** (mirrors SamplePlugin: Type=Editor, LoadingPhase=Default) | M2.S1 is editor-world only; runtime stat collection is not on the M2 roadmap. Refactor trigger: M3+ Runtime collector. |
| Q5 | Vertex vs triangle metric | **Vertex count** in M2.S1 (matches user's wording: "verticies เยอะมาก") | Switching the metric is a 1-line change in `FMeshVertexProvider::Scan()`. Honor user's domain language now; document tris as a follow-up. |
| Q6 | Severity defaults | **`static constexpr int32 SeverityYellow = 50000; static constexpr int32 SeverityRed = 250000;`** in `MeshVertexProvider.cpp` (or private `Severity.h`) | `UDeveloperSettings` is speculative — only one threshold pair to configure. Promote to `UDeveloperSettings` in M2.S2 when Nanite analyzer adds its own thresholds. Saves `Config/DefaultEditor.ini`, settings UClass, and `DeveloperSettings` Build.cs dep. |
| Q7 | Slate ↔ widget bridging contract | **`FOptimizePrimeReport` USTRUCT** (timestamp, `TArray<FHeavinessRow>`) passed by const-ref into `SHeavinessReportList::SetReport()` | Concrete, testable, no delegate plumbing. POD struct works whether the renderer is Slate (now) or UMG (M2.S2 polish). |
| Q8 | Mode toggle (Artist/Advanced) in v0.1.0 | **Visual-only** (badge sizes / column visibility); full plain-vs-jargon copy variation deferred to M2.S2 polish | Spec Open Item #4 default. Keeps sector atomic. |

---

## Implementation Plan

> **Phase-gating sentence (revised):** P0, P1, P5, P6 each have their own verification gate. **P2-P4 are code-only edits whose verification is bundled into P6 editor smoke** (compile + open + Scan-button smoke test); ralph proceeds through P2-P4 sequentially without intermediate gates. P1-P5 happen on a single ralph run inside `HostProject/Plugins/OptimizePrime/` on branch `dev`. P6 is the host-side sector commit + tag bump.

> **Phase order:** P0 → P1 → P2 → P3 → P4 → P5 → P6.

---

### P0 — bd issue + branch reservation

**Goal:** A bd issue exists and is claimed before any file is touched, so all subsequent commits can reference its id.

**Steps:**

```powershell
bd create "M2.S1: OptimizePrime vertical slice" `
  --label plugin:OptimizePrime --label sector:M2.S1 `
  --label ac:AC1 --label ac:AC2 --label ac:AC3 --label ac:AC4 `
  --label ac:AC5 --label ac:AC6 --label ac:AC7 --label ac:AC8 `
  --label ac:AC9 --label ac:AC10
bd update <id> --claim
```

The returned id (e.g. `op-1`) is the `<bd-id>` passed to `sector-commit.ps1` in P6. **Persist this id in the sector doc (P5)** so a re-run of the sector can reference it without re-creating.

**ACs touched:** none directly; precondition for AC9.

**Verification:**
- `bd show <id>` returns the claimed issue.
- `bd ready` no longer surfaces the issue (it's in-progress).

---

### P1 — Submodule scaffolding (driver: `new-plugin.ps1`)

**Goal:** A new GitHub repo `actimov2/OptimizePrime` exists, is added as a submodule under `HostProject/Plugins/OptimizePrime/`, has `main` + `dev` branches, and contains a SamplePlugin-shaped skeleton renamed to `OptimizePrime`.

**Driver script:** `scripts/new-plugin.ps1 -Name OptimizePrime -Description "Scene heaviness analyzer for VP / Broadcast / Game scenes (Slate panel + analyzer service)."`

**What the script does (verified by reading `new-plugin.ps1:33` ValidatePattern + lines 105 / 144-147):**

1. Validates `Name` matches `^[A-Z][A-Za-z0-9]+$` — `OptimizePrime` passes.
2. Copies `HostProject/Plugins/SamplePlugin/` to a temp folder named `OptimizePrime`.
3. Renames every `SamplePlugin` token (filename / folder / file content via line-105 `-replace 'SamplePlugin', $Name`) to `OptimizePrime`. Because both are PascalCase, every token becomes correct: `FSamplePluginModule` → `FOptimizePrimeModule`, `LogSamplePlugin` → `LogOptimizePrime`, `IMPLEMENT_MODULE(FSamplePluginModule, SamplePlugin)` → `IMPLEMENT_MODULE(FOptimizePrimeModule, OptimizePrime)`. **No casing fixup needed.**
4. `git init -b main` + initial commit + creates a private GitHub repo via `gh` + pushes (line 130).
5. `git submodule add` + commits `.gitmodules` and the submodule entry on the host (lines 144-147 — this is the **bootstrap-exception host commit**, see ADR).

**Manual edits after `new-plugin.ps1` (EDIT/DELETE inside the new submodule, on a freshly-created `dev` branch):**

| Action | Path | Reason |
|---|---|---|
| EDIT | `OptimizePrime.uplugin` | Confirm `Modules[0].Name = "OptimizePrime"` (script produces this automatically); confirm `CanContainContent: false` (already `false` in template — keep); set `Category: "Editor"`, `FriendlyName: "OptimizePrime"` (script sets this), `Description: "Scene heaviness analyzer..."`, `VersionName: "0.1.0"`. |
| EDIT | `Source/OptimizePrime/OptimizePrime.Build.cs` | Final 10 deps as enumerated: `PublicDependencyModuleNames = { "Core" }` (1); `PrivateDependencyModuleNames = { "CoreUObject", "Engine", "Slate", "SlateCore", "UnrealEd", "ToolMenus", "Projects", "EditorFramework", "InputCore" }` (9). SamplePlugin currently ships 9 deps (Core + the 8 private modules above except `InputCore`); ralph adds `InputCore` (+1) to total 10 — required for `FSlateApplication` interactions in P2. Diff against SamplePlugin's `Build.cs` and reconcile to this exact list — explicitly **no** `UMG`, `UMGEditor`, `Blutility`, `EditorScriptingUtilities`, or `DeveloperSettings`. |
| EDIT | `Source/OptimizePrime/Public/OptimizePrime.h` | Strip SamplePlugin-specific declarations: keep `DECLARE_LOG_CATEGORY_EXTERN(LogOptimizePrime, Log, All);`. Replace `FOptimizePrimeModule` body with: `StartupModule()`, `ShutdownModule()`, `RegisterMenus()` (toolbar registration), `OnToolbarButtonClicked()` (opens the Slate tab), `TUniquePtr<class FAnalyzerService> AnalyzerService;` member. Drop `PluginCommands` if unused; keep if reusing the toolbar `FUICommandList` pattern. |
| EDIT | `Source/OptimizePrime/Private/OptimizePrime.cpp` | Keep `DEFINE_LOG_CATEGORY(LogOptimizePrime)` and the `UE_LOG(LogOptimizePrime, Log, TEXT("LogOptimizePrime started"))` (script already produced these via rename). Replace `OnToolbarButtonClicked` body: instead of opening a `FMessageDialog`, invoke `FGlobalTabmanager::Get()->TryInvokeTab(FName("OptimizePrimePanel"))`. P4 wires the actual tab spawner. `IMPLEMENT_MODULE(FOptimizePrimeModule, OptimizePrime)` (script-produced). |
| KEEP | `Source/OptimizePrime/Private/OptimizePrimeCommands.{h,cpp}` (script-renamed from `SamplePluginCommands`) | Reuse the existing `FOptimizePrimeCommands::SayHelloCommand` pattern as the toolbar UICommand; rename `SayHelloCommand` → `OpenPanelCommand` and update its label/tooltip via `LOCTEXT`. |

**Submodule branch setup (after the script finishes):**

```powershell
Push-Location HostProject/Plugins/OptimizePrime
git checkout -b dev
Pop-Location
```

**Bootstrap-exception note:** `new-plugin.ps1` lines 144-147 create a host commit (`.gitmodules` + submodule entry) that is independent of the M2.S1 pin commit `sector-commit.ps1` will create in P6. M2.S1 therefore lands TWO host commits as a one-time bootstrap exception (mirrors the M1.S1-bootstrap precedent in `docs/sectors/M1.S1-bootstrap.md`). All future sectors against `OptimizePrime` land one host commit per sector.

**ACs touched:** AC1 (submodule + branches), AC2 (.uplugin shape), AC8 (LogOptimizePrime line preserved through rename).

**Verification (gate before P2):**
- `git -C HostProject/Plugins/OptimizePrime branch --list` shows `main` and `dev`.
- `git -C HostProject/Plugins/OptimizePrime remote -v` shows `https://github.com/actimov2/OptimizePrime.git`.
- `OptimizePrime.uplugin` parses (JSON-valid) and `Modules[0].Name == "OptimizePrime"`.
- Token-replacement spot-check: `Select-String "FOptimizePrimeModule" Source/OptimizePrime/Private/OptimizePrime.cpp` returns ≥1 match; `Select-String "LogOptimizePrime" Source/OptimizePrime/Private/OptimizePrime.cpp` returns ≥1 match; `Select-String "IMPLEMENT_MODULE\(FOptimizePrimeModule, OptimizePrime\)" Source/OptimizePrime/Private/OptimizePrime.cpp` returns 1 match. (Replaces former R1/R8 verification.)

---

### P2 — Slate panel + Slate report list (UI surface, pure C++)

**Goal:** A docked Slate tab `OptimizePrime` exists with a `Scan Scene` button, an Artist/Advanced mode toggle, and an embedded `SHeavinessReportList`. **No UMG, no `.uasset`.**

**Files (CREATE inside the new submodule):**

| Action | Path | Reason |
|---|---|---|
| CREATE | `Source/OptimizePrime/Private/UI/SOptimizePrimePanel.h` | Slate widget `SOptimizePrimePanel : public SCompoundWidget`. Slot args: `_OnScanRequested` delegate, `_InitialMode`. Children: `SButton` (label "Scan Scene", `OnClicked` → broadcast `_OnScanRequested`), `SCheckBox` mode toggle (Artist/Advanced), `SBorder` host containing `SHeavinessReportList`. |
| CREATE | `Source/OptimizePrime/Private/UI/SOptimizePrimePanel.cpp` | `Construct()` builds the layout (vertical box: top row = button + toggle, body = list border). `SetReport(const FOptimizePrimeReport&)` forwards rows to the embedded `SHeavinessReportList`. `SetMode(EOptimizePrimeMode)` toggles badge/column visibility on the list. |
| CREATE | `Source/OptimizePrime/Private/UI/SHeavinessReportList.h` | `SHeavinessReportList : public SCompoundWidget`. Internal `SListView<TSharedPtr<FHeavinessRow>>`. Public: `SetRows(const TArray<FHeavinessRow>&)`, `SetMode(EOptimizePrimeMode)`. |
| CREATE | `Source/OptimizePrime/Private/UI/SHeavinessReportList.cpp` | `Construct()` builds the `SListView` with `OnGenerateRow` returning a `STableRow` whose contents are 4 `STextBlock`s (label / asset / vertex count / severity badge `STextBlock` colored via `FSlateColor` from `Row->Severity`). Empty-state: when `Rows.Num() == 0`, render a centered `STextBlock` "No static meshes found". |
| CREATE | `Source/OptimizePrime/Public/Report/OptimizePrimeReport.h` | `enum class EHeavinessSeverity : uint8 { Green, Yellow, Red };` `enum class EOptimizePrimeMode : uint8 { Artist, Advanced };` `USTRUCT(BlueprintType) FHeavinessRow { FString ActorLabel; FString MeshAssetName; int32 VertexCount; EHeavinessSeverity Severity; };` `USTRUCT(BlueprintType) FOptimizePrimeReport { FDateTime Timestamp; TArray<FHeavinessRow> Rows; };`. Public so future M2.S2 widgets / Blueprints can consume. |

**ACs touched:** AC4 (tab in toolbar invocation path), AC5 (button + toggle + list area).

**Verification:** bundled into P6 editor smoke (no intrinsic gate).

---

### P3 — AnalyzerService + MeshVertexProvider (vertical slice core)

**Goal:** A pure-C++ analyzer service that, given a `UWorld*`, enumerates `AStaticMeshActor`s, computes vertex counts, sorts descending, classifies severity, and returns the top-10 as a `FOptimizePrimeReport`.

**Files (CREATE inside the new submodule):**

| Action | Path | Reason |
|---|---|---|
| CREATE | `Source/OptimizePrime/Private/Analyzer/AnalyzerService.h` | `class FAnalyzerService { public: explicit FAnalyzerService(); FOptimizePrimeReport ScanWorld(UWorld* World, int32 TopN = 10) const; private: TUniquePtr<class FMeshVertexProvider> MeshProvider; };`. **No `ICategoryProvider` interface** (Q2). |
| CREATE | `Source/OptimizePrime/Private/Analyzer/AnalyzerService.cpp` | Constructor instantiates `MeshProvider`. `ScanWorld()` calls `MeshProvider->Scan(World, OutRows)` directly, sorts `OutRows` by `VertexCount` descending, slices to `TopN`, stamps `Timestamp = FDateTime::UtcNow()`, returns the report. Severity already classified by the provider. |
| CREATE | `Source/OptimizePrime/Private/Analyzer/MeshVertexProvider.h` | `class FMeshVertexProvider { public: void Scan(UWorld* World, TArray<FHeavinessRow>& OutRows) const; };`. Free-standing class; no base. |
| CREATE | `Source/OptimizePrime/Private/Analyzer/MeshVertexProvider.cpp` | `static constexpr int32 SeverityYellow = 50000;` `static constexpr int32 SeverityRed = 250000;` (Q6). `Scan()` uses `TActorIterator<AStaticMeshActor>(World)`; for each actor: `UStaticMeshComponent* SMC = Actor->GetStaticMeshComponent()`; `if (!SMC) continue;` `UStaticMesh* SM = SMC->GetStaticMesh(); if (!SM) continue;` **Vertex-count derivation MUST guard both `RenderData == nullptr` AND `LODResources.Num() > 0`** (R-final): `const FStaticMeshRenderData* RD = SM->GetRenderData(); if (!RD || RD->LODResources.Num() == 0) continue;` `int32 VertexCount = RD->LODResources[0].GetNumVertices();` Classify severity: `Green` if `< SeverityYellow`, `Yellow` if `< SeverityRed`, else `Red`. Push `FHeavinessRow{Actor->GetActorLabel(), SM->GetName(), VertexCount, Severity}`. Skipped actors logged at `Verbose`. |

**Empty-world handling:** `AnalyzerService::ScanWorld` returns an empty `Rows` array if no actors found; `SHeavinessReportList` empty-state renders "No static meshes found" (per spec Verification step 5).

**ACs touched:** AC6 (enumerate + compute + report), AC7 (severity).

**Verification:** bundled into P6 editor smoke (no intrinsic gate).

---

### P4 — Wiring (toolbar button → tab → service → list)

**Goal:** Clicking the toolbar button (or the to-be-added Window menu entry) opens the docked tab; clicking `Scan Scene` triggers the service; the resulting report flows into the Slate list. `LogOptimizePrime started` appears in `Saved/Logs/HostProject.log` on editor open.

**Files (EDIT inside the new submodule):**

| Action | Path | Reason |
|---|---|---|
| EDIT | `Source/OptimizePrime/Private/OptimizePrime.cpp` | In `StartupModule`: instantiate `AnalyzerService = MakeUnique<FAnalyzerService>()`. After `UToolMenus::RegisterStartupCallback`, register a Slate tab spawner via `FGlobalTabmanager::Get()->RegisterNomadTabSpawner(FName("OptimizePrimePanel"), FOnSpawnTab::CreateRaw(this, &FOptimizePrimeModule::SpawnPanel))` with `.SetDisplayName(LOCTEXT("OptimizePrimeTabTitle", "OptimizePrime"))`. `SpawnPanel` returns a `SDockTab` containing `SNew(SOptimizePrimePanel).OnScanRequested_Lambda([this](){ if (UWorld* W = GEditor ? GEditor->GetEditorWorldContext().World() : nullptr) { Panel->SetReport(AnalyzerService->ScanWorld(W)); } })`. The toolbar button (already wired in P1) calls `FGlobalTabmanager::Get()->TryInvokeTab(FName("OptimizePrimePanel"))`. **`UE_LOG(LogOptimizePrime, Log, TEXT("LogOptimizePrime started"))` runs at the very top of `StartupModule` so it lands even if tab is never opened.** |
| EDIT | `Source/OptimizePrime/Public/OptimizePrime.h` | Add forward decls: `class FAnalyzerService;` `class SOptimizePrimePanel;` `class SDockTab;` `class FSpawnTabArgs;`. Add members: `TUniquePtr<FAnalyzerService> AnalyzerService;` `TSharedPtr<SOptimizePrimePanel> Panel;`. Add method: `TSharedRef<SDockTab> SpawnPanel(const FSpawnTabArgs& Args);`. |

**Failure-mode contracts:**

- `GEditor->GetEditorWorldContext().World()` returns null in headless contexts: button no-ops and logs at `Warning`. Sector deems this acceptable for v0.1.0.

**ACs touched:** AC4, AC5, AC6, AC7, AC8.

**Verification:** bundled into P6 editor smoke (no intrinsic gate).

---

### P5 — Sector doc, MILESTONES row, plugin commit on `dev`

**Goal:** All host-repo metadata is in place, and the plugin submodule has ONE clean commit on `dev` containing all of P1-P4.

**Files (CREATE / EDIT in the host repo, NOT in the submodule):**

| Action | Path | Reason |
|---|---|---|
| CREATE | `docs/sectors/M2.S1.md` | **Self-sufficient sector doc** — ralph reads this file ONLY. Required sections (mirror M1.S2 format): **Plugin** (= `OptimizePrime`), **Preconditions** (P0 bd issue claimed; M1.S2 landed; `Get-Process UnrealEditor` returns null; `gh auth status` ok). **Definition of Done** (the 10 ACs distilled into 6 numbered items). **Verification** (the 7 numbered steps from spec §Verification, restated inline). **Tag Bump** (FF-only `dev → main` then `scripts/plugin-version.ps1 -Plugin OptimizePrime -Bump minor` → `v0.1.0`). **ACs Touched** (AC1-AC10). **Notes** (cross-link spec; bootstrap-exception note; bd-id). **Inlined for self-sufficiency (Critic #6):** (a) full file table from P1-P4 with action / path / reason; (b) Build.cs final dep list (10 deps); (c) severity defaults `static constexpr int32 SeverityYellow = 50000; SeverityRed = 250000;`; (d) USTRUCT field definitions for `FHeavinessRow` / `FOptimizePrimeReport` / `EHeavinessSeverity` / `EOptimizePrimeMode`; (e) the P6 verification steps verbatim; (f) the P0 `bd create` block + claimed bd-id; (g) the `MeshVertexProvider::Scan` null-guard snippet inlined as a code block — exact text: `const FStaticMeshRenderData* RD = SM->GetRenderData(); if (!RD || RD->LODResources.Num() == 0) { continue; }` (highest-risk single line in P3; ralph must not omit). |
| EDIT | `planning/MILESTONES.md` | Add row: `\| [ ] \| M2.S1 \| OptimizePrime \| Vertical slice: scaffold + Slate panel + Slate list + MeshVertexProvider \| op-1 \| docs/sectors/M2.S1.md \|`. Optionally add `[ ]` placeholders for M2.S2-M2.S5 with no detail file yet. |
| EDIT | `planning/TASK_ASSIGNMENTS.md` | Add ownership entry for M2.S1. |

**Plugin-side commit (inside the submodule, on `dev`):**

```powershell
Push-Location HostProject/Plugins/OptimizePrime
git add -A
git commit -m "M2.S1: vertical slice — Slate panel + Slate list + MeshVertexProvider"
Pop-Location
```

This is the single atomic plugin commit that the host pin will reference.

**ACs touched:** AC10 (sector doc + MILESTONES row exist).

**Verification (gate before P6):**
- `Test-Path docs/sectors/M2.S1.md`.
- `Select-String M2.S1 planning/MILESTONES.md` returns one match.
- `git -C HostProject/Plugins/OptimizePrime log -1 --oneline` shows the M2.S1 commit on `dev`.
- Sector-doc self-sufficiency check: `Select-String "SeverityYellow = 50000" docs/sectors/M2.S1.md` returns ≥1 match (proves thresholds are inlined); `Select-String "FHeavinessRow" docs/sectors/M2.S1.md` returns ≥1 match (proves USTRUCT defs are inlined); `Select-String "LODResources.Num\(\) == 0" docs/sectors/M2.S1.md` returns ≥1 match (proves the `MeshVertexProvider::Scan` null-guard snippet is inlined per item-g).

---

### P6 — Verification + sector-commit + tag bump

**Goal:** End-to-end editor verification (the bundled gate for P2-P4), then the dual push + tag.

**Steps (in order):**

1. **Regenerate:** `scripts/regenerate.ps1` from host root. Must exit 0. `HostProject.sln` contains an `OptimizePrime` project. (AC3)
2. **Compile + open:** Double-click `HostProject.uproject`; accept the rebuild prompt. Editor opens. Grep `Saved/Logs/HostProject.log` for `LogOptimizePrime started`. (AC8)
3. **UI smoke (AC4, AC5):** Click the toolbar button registered by `OptimizePrime`; the docked tab `OptimizePrime` opens. Tab shows `Scan Scene` button, Artist/Advanced toggle, and the empty `SHeavinessReportList` ("No static meshes found").
4. **Functional (AC6, AC7):** Open `Minimal_Default` (or any level with ≥10 `AStaticMeshActor`s; spawn cubes if needed). Click `Scan Scene`. List renders top-10 sorted descending with severity badges. Toggle Artist/Advanced; verify visual difference. Test in `Empty_Default` → "No static meshes found" empty state.
5. **Capture evidence:** screenshot of the populated panel + screenshot of the empty-state panel → `.omc/research/m2s1-evidence/`. Tail of `HostProject.log` showing `LogOptimizePrime started` → same folder.
6. **Close editor.** `Get-Process UnrealEditor -ErrorAction SilentlyContinue` MUST return null before P6.7.
7. **Sector commit (AC9):**
   ```powershell
   scripts/sector-commit.ps1 -Plugin OptimizePrime -SectorId M2.S1 -BdId op-1
   ```
   Exit code MUST be 0. The script handles the bd-hooks swap, plugin-side `git push origin dev`, ls-remote SHA verification, host-side pin commit, host-side `git push`, `bd close op-1`, and the "Continue?" prompt.
8. **MILESTONES update:** `sector-commit.ps1` (or follow-up commit) flips the M2.S1 row from `[ ]` to `[x]`. (AC10)
9. **Tag bump (AC1 tag requirement, post-sector):**
   ```powershell
   scripts/plugin-version.ps1 -Plugin OptimizePrime -Bump minor
   ```
   FF-merges `dev → main` inside the submodule and tags `v0.1.0`, pushing both. Verify `git -C HostProject/Plugins/OptimizePrime tag --list` shows `v0.1.0`.

**ACs touched:** AC1 (tag), AC3 (regenerate), AC4-AC8 (interactive), AC9 (sector-commit exit 0), AC10 (MILESTONES `[x]`).

**Verification evidence:** `.omc/research/m2s1-evidence/{populated.png, empty.png, log-tail.txt, sector-commit-transcript.txt, tag-list.txt}`.

---

## Risk Table (collapsed)

| # | Risk | Status | Mitigation |
|---|---|---|---|
| R-final | `GetRenderData()` returns null OR `LODResources` is empty for a `UStaticMesh` | OPEN | `MeshVertexProvider::Scan()` MUST guard `RenderData == nullptr` AND `LODResources.Num() > 0` (skip + log Verbose). Codified in P3 file table and inlined in sector doc. |
| R-bootstrap | M2.S1 lands TWO host commits (`.gitmodules` from `new-plugin.ps1` + pin from `sector-commit.ps1`) — apparent violation of "one host commit per sector" | RESOLVED | ADR bootstrap-exception subsection documents this as one-time per plugin, mirroring M1.S1-bootstrap precedent. Future sectors land one host commit. |
| R-gh-auth | `gh auth` not present on the operator's machine | OPEN | `new-plugin.ps1` preflight throws with a clear message. Sector doc precondition lists `gh auth status` must succeed. |
| R-editor-running | UE editor running during sector-commit corrupts the build | RESOLVED | P6 step 6 explicitly closes the editor and asserts the process is gone before invoking `sector-commit.ps1`. |
| R-script-recovery | Submodule push lands but host pin push fails | RESOLVED (out of scope) | `sector-commit.ps1` (host-script, not this plan's responsibility) handles failure-mode-(c) via `$preCommitSha` reset. Plan must not open-code git. |

> **Risks dropped from iteration 1:** R1 (lowercase module name) — obviated by PascalCase rename. R2 (UMG `.uasset` ralph-authoring) — obviated by dropping UMG. R3 (CategoryProvider YAGNI) — obviated by dropping the interface. R4 (`CanContainContent: true` cooking) — obviated by keeping `false`. R8 (operator skips PascalCase fixup) — obviated by ValidatePattern + script-produced PascalCase tokens (verified by P1 grep checks).

---

## ADR

**Decision:** Ship `OptimizePrime` v0.1.0 as a single Editor-only module mirroring SamplePlugin's shape exactly (10 deps, `CanContainContent: false`, toolbar-button invocation pattern). The vertical slice is a free-standing `FMeshVertexProvider` directly owned by `FAnalyzerService` (no abstract interface), feeding a pure-C++ `SHeavinessReportList` Slate widget via a `FOptimizePrimeReport` USTRUCT contract. Severity thresholds are `static constexpr` in `MeshVertexProvider.cpp`. Submodule scaffolding goes through `scripts/new-plugin.ps1` (which also produces a one-time bootstrap-exception host commit for `.gitmodules`); the M2.S1 dual push goes through `scripts/sector-commit.ps1`; the tag bump goes through `scripts/plugin-version.ps1`. No script is open-coded.

**Drivers:** AC9 atomic-commit constraint; SamplePlugin-precedent fidelity; ralph-purity (no editor-in-the-loop authoring); "Safe" north-star value (read-only).

### Bootstrap exception to one-host-commit-per-sector

`new-plugin.ps1` lines 144-147 create a host commit (`git commit -m "Add OptimizePrime plugin as submodule"` covering `.gitmodules` + the new submodule entry). `sector-commit.ps1` later creates a second host commit (the SHA pin update with sector-tagged message). M2.S1 therefore lands TWO host commits. This is a one-time bootstrap exception per new plugin, aligned with the M1.S1-bootstrap precedent in `docs/sectors/M1.S1-bootstrap.md`. All future sectors against `OptimizePrime` (M2.S2 onward) land one host commit per sector.

### Alternatives considered

- **`ICategoryProvider` interface in M2.S1** — rejected: speculative single-impl interface; introduces a header with no second consumer. Mechanically reintroduce in M2.S2 when Nanite eligibility analyzer arrives.
- **UMG `.uasset` Editor Utility Widget shipped in `Content/`** — rejected: cannot be ralph-authored (forces editor-in-the-loop step that breaks atomicity). Pure-C++ `SHeavinessReportList` ships now; UMG migration belongs to M2.S2 polish if the widget grows beyond a flat list.
- **`UDeveloperSettings` for severity thresholds** — rejected: speculative for a single threshold pair. `static constexpr` now; promote to `UDeveloperSettings` in M2.S2 when Nanite analyzer adds its own configurable thresholds (collapsing both into one settings class).
- **`Config/DefaultEditor.ini` baseline** — rejected: only meaningful with `UDeveloperSettings`; obviated by the `static constexpr` decision above.
- **C++-defined widget instead of `.uasset`** — accepted (this is the chosen path; listed here as the inverse of the rejected UMG alternative).
- **Editor + Runtime module split** — rejected: premature; M2 has no Runtime work; trigger documented for M3+.
- **Triangle count metric** — rejected for M2.S1: user's domain language was "verticies"; tris is a follow-up, 1-line change.
- **Manual `git submodule add`** — rejected: `new-plugin.ps1` already does template + GitHub repo + `.gitmodules` atomically; manual path re-implements and risks drift.
- **Window-menu invocation instead of toolbar button** — rejected: SamplePlugin uses toolbar via ToolMenus extension points (`LevelEditor.LevelEditorToolBar.AssetsToolBar` etc.); diverging is unjustified noise. Toolbar button opens the docked tab via `FGlobalTabmanager::TryInvokeTab`.
- **Full Artist/Advanced copy variation in M2.S1** — rejected: visual-only is sufficient per spec Open Item #4; M2.S2 polish absorbs full variation.

### Why chosen

Each decision either honors the M2.S1 atomicity constraint, mirrors a verified SamplePlugin pattern, or removes a speculative seam. The thinner slice is ~600 LOC and fully ralph-completable except for the single P6 editor smoke test.

### Consequences (positive)

- Ralph-pure pipeline: no editor-in-the-loop authoring step; the only manual step is the P6 editor smoke (which is verification, not construction).
- 10-dep Build.cs matches SamplePlugin precedent exactly + 1 (well, equal) — no surprise dependencies.
- `FOptimizePrimeReport` USTRUCT remains the durable contract; swapping `SHeavinessReportList` for a UMG widget in M2.S2 is a renderer swap, not an architectural rewrite.
- `static constexpr` thresholds are trivially auditable from the source file alone.

### Consequences (negative)

- M2.S2 must mechanically extract `ICategoryProvider` when adding `FNaniteEligibilityProvider` (this is the planned trigger, not a regression).
- M2.S2 must promote `static constexpr` thresholds to `UDeveloperSettings` when Nanite analyzer needs its own configurable thresholds.
- M2.S1 lands TWO host commits (bootstrap exception above) — operator must understand this is by design, not a workflow bug.
- Public-facing plugin name = `OptimizePrime` (PascalCase); original spec wording "optimizePrime" was a casual reference. One-time naming reconciliation.

### Follow-ups (deferred)

- M2.S2: extract `ICategoryProvider` interface; add `FNaniteEligibilityProvider`; promote severity thresholds to `UDeveloperSettings` (creates `Config/DefaultEditor.ini`).
- M2.S2 polish: migrate `SHeavinessReportList` → UMG `URaportWidgetBase` Editor Utility Widget if the widget grows beyond a flat list (would flip `CanContainContent` to `true`).
- M2.S3+: revisit triangle-vs-vertex metric with empirical GPU-cost data.
- M3.S1+: Editor + Runtime module split (when Runtime stat collector lands).
- Improve `new-plugin.ps1` to optionally accept a `-DevBranch` switch that creates `dev` automatically (host-script change, not a plugin sector).

---

## Open Questions

- [ ] **GitHub repo name confirmed as `actimov2/OptimizePrime`?** (binding: PascalCase plugin name implies PascalCase repo name; `new-plugin.ps1` line 130 creates `gh repo create $GitHubUser/$Name`. User decision recorded; flag here for explicit confirmation before P1 runs.)
- [ ] **Sector doc inlines a copy of the P3 severity-classification helper?** (Decision: yes, inline as plain code block so ralph never has to read `MeshVertexProvider.cpp` to apply it correctly. Confirm with reviewer.)

These are persisted to `.omc/plans/open-questions.md` per Planner protocol.

---

## Handoff to ralph + architect-verifier

This plan replaces autopilot Phase 0 (Expansion) and Phase 1 (Planning). Per CLAUDE.md, M2.S1 executes via **ralph + architect-verifier**, not autopilot.

- **Phase order:** P0 → P1 → P2 → P3 → P4 → P5 → P6.
- **Gating:** P0, P1, P5, P6 each have intrinsic verification. P2-P4 are bundled into the P6 editor smoke (compile + open + scan).
- **Ralph reads `docs/sectors/M2.S1.md` ONLY** — that file inlines the full P1-P4 file table, Build.cs deps, severity constexprs, USTRUCT defs, P6 verification steps, and the P0 bd block.
- **Verifier:** `architect-verifier` reviews the Build.cs deps (10), the absence of `ICategoryProvider` (intentional), the `FOptimizePrimeReport` USTRUCT contract, the `MeshVertexProvider` null-guards, and the `OptimizePrime.cpp` `StartupModule` wiring before P5's plugin commit lands on `dev`.
- **Push protocol:** `scripts/sector-commit.ps1` for the dual push (P6.7); `scripts/plugin-version.ps1` for the tag bump (P6.9). No open-coded git.
- **Acceptance:** AC1-AC10 from the spec, all Q1-Q8 decisions enforced.
- **Atomicity contract:** ONE plugin commit on `dev` (the M2.S1 commit from P5), ONE M2.S1 host pin commit (created by `sector-commit.ps1` in P6.7). PLUS one bootstrap-exception host commit from P1's `new-plugin.ps1` (`.gitmodules` + submodule entry) — see ADR.
