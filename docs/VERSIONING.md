# Versioning

Non-destructive plugin versioning model for `Unreal_Nice_Plugins`. This
document is the source of truth; `CLAUDE.md` carries only a one-paragraph
summary and links here.

## Branch Model

Each plugin submodule maintains three classes of branches:

- **`main`** — stable. Holds annotated SemVer tags (`v0.1.0`, `v0.1.1`, …).
  FF-only from `dev`. Never force-pushed. Tag SHA == branch tip SHA after
  promotion.
- **`dev`** — active work. The host repo pins SHAs from this branch via
  the submodule pointer.
- **`exp/<topic>`** — short-lived experiment branches (e.g.
  `exp/m1s1-prestage`). Gated by ralph + architect-verifier before merging
  back into `dev`.

The host repo (`Unreal_Nice_Plugins`) pins **SHAs only** — never branch
refs. The submodule pointer in any host commit must be reachable on the
plugin's `origin/dev` (or `origin/main`) at the time the host commit is
created.

## SemVer Tagging

Tags are annotated and applied by `scripts/plugin-version.ps1`. The script:

1. Resolves the current `dev` SHA.
2. `git -C <plugin> checkout main`
3. `git -C <plugin> merge --ff-only dev` — divergence aborts with exit 20.
4. Computes the next semver from `git describe --tags --abbrev=0 main`
   plus the requested bump (`patch|minor|major`).
5. `git -C <plugin> tag -a <ver> <devSha> -m "<Plugin> <ver>"`
6. `git -C <plugin> push origin main --follow-tags`
7. `git -C <plugin> push origin dev`

The FF-only constraint guarantees that `tag.SHA == main.tip.SHA`, which is
required for clean rollback to a tag without forcing the editor to
recompile dev-branch-only code.

## SHA Pinning Contract

A host commit that updates `HostProject/Plugins/<name>` is a **pin**. The
contract:

1. The new pin SHA must be reachable on `origin/dev` (or `origin/main`) of
   the plugin **before** the host commit lands. `scripts/sector-commit.ps1`
   enforces this with `git ls-remote origin refs/heads/dev` and a string
   compare.
2. Pin commits use the message form
   `pin: <Plugin>@<sha> (sector <M.S>, bd:<id>)` for grep-ability.
3. Floating refs (branch names, tags resolved at clone time) are never
   used. Submodule entries always carry concrete SHAs.

## Branch Discipline

- Never rebase `dev` after the most-recent `v*` tag without a coordinated
  reset of `main`. FF-only promotion will refuse a diverged `dev`, and
  `scripts/plugin-version.ps1` will exit 20 with a message pointing here.
- Never force-push `main` or `dev`. `exp/<topic>` is the only space where
  history rewrites are tolerated, and only before the branch has been
  consumed by another agent.
- `exp/<topic>` branches are deleted after their sector lands on `dev`.
- A future deferred follow-up will add a server-side pre-push hook that
  refuses non-FF pushes on `dev`.

## Rollback Runbook (AC2)

Rolling back a plugin to an older tag is a routine operation. The order
matters because UE5's Live Coding cache will load stale binaries if the
editor is open during the checkout.

1. **Close the editor.** `Get-Process UnrealEditor -ErrorAction SilentlyContinue`
   must return null. Do not proceed otherwise.
2. **Checkout the tag inside the submodule.**
   `git -C HostProject/Plugins/<name> checkout <tag>` (e.g. `v0.0.1`).
3. **Delete stale build artifacts.**
   - `Remove-Item -Recurse -Force HostProject/Binaries`
   - `Remove-Item -Recurse -Force HostProject/Intermediate`
4. **Regenerate project files.** `scripts/regenerate.ps1`
5. **Open the editor.** Double-click `HostProject/HostProject.uproject`. On
   first open it will recompile against the older plugin source (5–15 min
   cold). Confirm the older behavior in the editor (e.g. older log text
   absent / present).
6. **Restore.** Close the editor. `git -C HostProject/Plugins/<name> checkout
   <newer-tag-or-dev>`. Repeat steps 3 → 5 to return to current state.

> **Note:** The host repo will show the submodule as "modified content"
> after step 2 — this is expected. The host pin is **not** mutated until
> someone explicitly commits the submodule pointer change. Rollback is
> non-destructive at the host level.

## Future Migrations

These migrations are intentionally deferred until the plugin count
crosses a concrete threshold. The trigger query is the same in every
case:

```powershell
$pluginCount = (Get-ChildItem HostProject/Plugins -Directory | Measure-Object).Count
```

| Trigger | Migration | To-be-authored script |
|---|---|---|
| `$pluginCount -ge 2` | Split `MILESTONES.md` into root meta + per-plugin files. | `scripts/migrate-milestones-hybrid.ps1` |
| `$pluginCount -ge 2` | Re-introduce per-plugin `CLAUDE.md` for plugin-specific conventions. | `scripts/migrate-claudemd-perplugin.ps1` |
| `$pluginCount -ge 2` | Adopt `.beads-plugin/` import pattern so each plugin owns its bd graph. | `scripts/import-plugin-bd.ps1` |

Each migration script is a follow-up; do not invoke them at N=1.
