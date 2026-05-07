# AC1 Pre-stage Evidence (P5a)

**Date:** 2026-05-07
**Branch:** `exp/m1s1-prestage` (deleted after verification)
**Sector:** M1.S1 — Add LogSamplePlugin startup log

## Verification

- ✅ `scripts/regenerate.ps1` exited 0 (10.83s) after Resolve-Path → -LiteralPath fix for bracket-containing path
- ✅ Live Coding compile succeeded (Module.SamplePlugin.cpp built clean)
- ✅ Cold rebuild after deleting `Plugins/SamplePlugin/Binaries` + `Intermediate` succeeded
- ✅ Output Log shows: `LogSamplePlugin: LogSamplePlugin started`
  - Confirmed by user-provided screenshot (Output Log filter "LogSamplePlugin")

## Edits applied (on exp/m1s1-prestage)

1. `Source/SamplePlugin/Public/SamplePlugin.h:12` — `DECLARE_LOG_CATEGORY_EXTERN(LogSamplePlugin, Log, All);`
2. `Source/SamplePlugin/Private/SamplePlugin.cpp:12` — `DEFINE_LOG_CATEGORY(LogSamplePlugin);`
3. `Source/SamplePlugin/Private/SamplePlugin.cpp:16` — `UE_LOG(LogSamplePlugin, Log, TEXT("LogSamplePlugin started"));` (first line of `StartupModule()`)

## Conclusion

Toolchain proven: regenerate.ps1 → build → editor → log line all work end-to-end.
The `next` cold demo (P5b) cannot fail due to environmental/toolchain bugs — any failure indicates a workflow defect.

## Side-effects fixed during P5a

- `scripts/regenerate.ps1` — `Resolve-Path` → `Resolve-Path -LiteralPath` so the script works in paths containing `[` `]`. Same fix likely needed in `add-plugin.ps1` and `new-plugin.ps1` (deferred).

## Branch state after P5a

- `exp/m1s1-prestage` — deleted
- Working tree on `dev` — clean (edits discarded)
- `HostProject/Binaries/`, `HostProject/Intermediate/`, `HostProject/Plugins/SamplePlugin/Binaries/`, `HostProject/Plugins/SamplePlugin/Intermediate/` — all deleted
