# M1.S3 Evidence — regenerate.ps1 Idempotency

Date: 2026-05-07
Sector: M1.S3
Bead: Unreal_Nice_Plugins-c4u
Plugin: host (no submodule changes)

## Pre-state

- Editor closed (`tasklist | grep UnrealEditor` -> empty).
- Host pin = `6b3f9a2` (M1.S1 pin still in place).
- Submodule on `dev` at `e33ae3d` = v0.1.0.

## Procedure

1. **Cleaned host build artifacts**:
   ```
   rm -rf HostProject/Binaries HostProject/Intermediate HostProject/HostProject.sln
   ```
   No stale `*.sln` at host root (none ever existed there; UBT places SLN
   inside `HostProject/`).

2. **First regenerate**:
   ```
   powershell -File scripts/regenerate.ps1 > .omc/research/m1s3-regenerate-log.txt 2>&1
   ```
   Exit 0. Tail:
   ```
   Result: Succeeded
   Total execution time: 8.25 seconds
   [OK] Done. Open HostProject.sln in Visual Studio.
   ```

3. **Toolchain-wired check**:
   - `HostProject.sln` regenerated.
   - SLN itself contains no `SamplePlugin` literal (UBT puts module refs in
     the `HostProject.vcxproj` referenced from the SLN, not in the SLN).
   - `grep -c SamplePlugin HostProject/Intermediate/ProjectFiles/HostProject.vcxproj`
     -> **8 matches**. Plugin module is wired into the build graph.

4. **Idempotency check**:
   ```
   cp HostProject/HostProject.sln /tmp/host-sln-1.sln
   powershell -File scripts/regenerate.ps1 > .omc/research/m1s3-regenerate-log-2.txt 2>&1
   diff -q HostProject/HostProject.sln /tmp/host-sln-1.sln
   ```
   Exit 0; `diff` reports no difference. **SLN IDEMPOTENT** confirmed.

## ACs Touched

- **AC3** ✅ — workflow files exist and toolchain is wired end-to-end.

## Sector Spec Discrepancy (filed)

`docs/sectors/M1.S3.md` DoD step 4 says:

> `HostProject.sln` is regenerated and contains the `SamplePlugin` module
> target (`Select-String -Path HostProject.sln -Pattern 'SamplePlugin'`
> returns at least one match).

This is inaccurate for UBT-generated solutions. The plugin is referenced
from `HostProject.vcxproj`, not the `.sln` directly. Followup:
`Unreal_Nice_Plugins-XXX` (filed alongside this commit) updates the
sector spec to grep `*.vcxproj` instead.

## Notes

- This sector did NOT call `sector-commit.ps1`; no host pin change.
- M1 milestone is complete after this sector lands. M2+ will introduce
  next-plugin scaffolding via `scripts/new-plugin.ps1`.
