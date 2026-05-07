<#
.SYNOPSIS
  Regenerate Visual Studio project files for HostProject.

.DESCRIPTION
  Equivalent to right-clicking the .uproject and choosing
  "Generate Visual Studio project files", but from the command line.

  Reads UE_ROOT from environment or accepts -EnginePath.

.PARAMETER EnginePath
  Path to UE installation (e.g. C:\Program Files\Epic Games\UE_5.6).
  Defaults to $env:UE_ROOT.
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$EnginePath = $env:UE_ROOT
)

$ErrorActionPreference = 'Stop'
$RepoRoot = (Resolve-Path -LiteralPath "$PSScriptRoot\..").Path
$UProject = Join-Path $RepoRoot "HostProject\HostProject.uproject"

if (-not $EnginePath -or -not (Test-Path $EnginePath)) {
    throw @"
Engine path not set. Either:
  1. Set environment variable UE_ROOT to your UE 5.6 install (e.g. C:\Program Files\Epic Games\UE_5.6)
  2. Pass -EnginePath explicitly
"@
}

$BuildBat = Join-Path $EnginePath "Engine\Build\BatchFiles\Build.bat"
if (-not (Test-Path $BuildBat)) {
    throw "Build.bat not found at $BuildBat. Is UE_ROOT pointing to the right place?"
}

Write-Host "==> Regenerating project files for HostProject" -ForegroundColor Cyan
& $BuildBat -projectfiles "-project=$UProject" -game -rocket -progress

if ($LASTEXITCODE -ne 0) {
    throw "Build.bat exited with code $LASTEXITCODE"
}

Write-Host "✓ Done. Open HostProject.sln in Visual Studio." -ForegroundColor Green
