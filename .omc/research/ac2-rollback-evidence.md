# AC2 Rollback Evidence — M1.S2

Date: 2026-05-07
Sector: M1.S2
Bead: Unreal_Nice_Plugins-rff
Plugin: SamplePlugin

## Tag Promotion

`scripts/plugin-version.ps1 -Plugin SamplePlugin -Bump minor`:

```
Switched to branch 'main'
Updating e97369c..e33ae3d
Fast-forward (5 files, +55/-34)
Plugin 'SamplePlugin': v0.0.1 -> v0.1.0 (devSha=e33ae3d)
To https://github.com/actimov2/SamplePlugin.git
   e97369c..e33ae3d  main -> main
 * [new tag]         v0.1.0 -> v0.1.0
```

Tag list after promotion:
- `v0.0.1` -> `e97369c` (baseline)
- `v0.1.0` -> `e33ae3d` (M1.S1)

## Rollback Demo (AC2)

1. **Checkout baseline**:
   ```
   git -C HostProject/Plugins/SamplePlugin checkout v0.0.1
   ```
   HEAD detached at `e97369c`. `grep -c LogSamplePlugin SamplePlugin.cpp` -> 0 (category removed from source).

2. **Regenerate + rebuild**:
   - `regenerate.ps1`: exit 0 (`Result: Succeeded`, 7.92s).
   - `Build.bat HostProjectEditor Win64 Development`: exit 0
     (compile + link + DLL written, 10.71s).

3. **Editor verification**:
   User opened `HostProject.uproject`. Output Log filter `LogSamplePlugin` -> **empty** (zero matches), confirming the category is absent at v0.0.1. Screenshot delivered in-conversation.

4. **Restore**:
   ```
   git -C HostProject/Plugins/SamplePlugin checkout dev
   ```
   HEAD = `e33ae3d` (matches v0.1.0 tag). `grep -c LogSamplePlugin SamplePlugin.cpp` -> 2 (DECLARE + DEFINE restored).
   Rebuilt DLL at dev tip; editor next open will show `LogSamplePlugin started` again.

## Host Repo Invariant

The host repo's submodule pointer was unchanged throughout this sector
(still pinned to `e33ae3d` from the M1.S1 sector commit). Rollback in the
plugin submodule does NOT mutate host state — host pin remains the source
of truth.

## ACs Touched

- **AC2** (rollback demo) — verified end-to-end.
- **AC4** (versioning convention) — FF-only promotion + annotated tag at
  dev tip exercised.

## Script Fixes Landed Alongside

`scripts/plugin-version.ps1` PS 5.1 compatibility:
- Replaced `§` (U+00A7) and `—` (U+2014) in comments/error string with
  ASCII (UTF-8 without BOM was being misread as CP1252, breaking the
  string literal terminator and cascading parser errors).
- Switched `$ErrorActionPreference` from `Stop` to `Continue`; script
  already checks `$LASTEXITCODE` per call.

## Side Notes

- Push of `dev` failed with a stale `dev.lock` ref in
  `.git/modules/HostProject/Plugins/SamplePlugin/refs/remotes/origin/`.
  Manually removed; dev SHA was unchanged so `Everything up-to-date`
  is the correct end state. File a follow-up if this recurs.
