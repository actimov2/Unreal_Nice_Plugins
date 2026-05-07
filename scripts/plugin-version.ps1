<#
.SYNOPSIS
    FF-only SemVer tag promotion for a plugin submodule.

.DESCRIPTION
    Promotes the plugin's `dev` branch to `main` via fast-forward merge
    only, computes the next SemVer from the most recent tag plus the
    requested bump, applies an annotated tag at the dev-tip SHA, then
    pushes both `main` (with tags) and `dev`.

    On stdout the script prints the new tip SHA so callers can chain.

.PARAMETER Plugin
    Plugin name (matches HostProject/Plugins/<name> directory).

.PARAMETER Bump
    SemVer component to bump: patch | minor | major.

.PARAMETER DryRun
    Print the plan; perform no git mutations.

.EXAMPLE
    scripts/plugin-version.ps1 -Plugin SamplePlugin -Bump minor

.NOTES
    Exits:
      0   success (writes new SHA to stdout)
      20  precondition failure (path-guard, divergence, missing tag base)

    See docs/VERSIONING.md §SemVer Tagging and §Branch Discipline.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $Plugin,

    [Parameter(Mandatory = $true)]
    [ValidateSet('patch','minor','major')]
    [string] $Bump,

    [switch] $DryRun
)

$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# Path-guard
# ---------------------------------------------------------------------------
if (-not (Test-Path 'HostProject/HostProject.uproject')) {
    throw "plugin-version.ps1 must be run from the host repo root (HostProject/HostProject.uproject not found in cwd '$PWD')."
}

$pluginPath = "HostProject/Plugins/$Plugin"
if (-not (Test-Path $pluginPath)) {
    Write-Error "Plugin directory not found: $pluginPath"
    exit 20
}

function Bump-SemVer {
    param([string] $Current, [string] $Component)
    $stripped = $Current.TrimStart('v')
    $parts = $stripped.Split('.')
    if ($parts.Count -ne 3) {
        throw "Cannot parse SemVer from '$Current'. Expected vX.Y.Z."
    }
    $maj = [int]$parts[0]; $min = [int]$parts[1]; $pat = [int]$parts[2]
    switch ($Component) {
        'patch' { $pat += 1 }
        'minor' { $min += 1; $pat = 0 }
        'major' { $maj += 1; $min = 0; $pat = 0 }
    }
    return "v$maj.$min.$pat"
}

# ---------------------------------------------------------------------------
# Resolve dev SHA before the merge so the tag points at the same commit
# as the dev tip (FF-only guarantees main.tip == dev.tip after merge).
# ---------------------------------------------------------------------------
$pluginStatus = git -C $pluginPath status --porcelain
if ($pluginStatus) {
    Write-Error "Plugin tree is dirty:`n$pluginStatus"
    exit 20
}

$devSha = (git -C $pluginPath rev-parse dev).Trim()
if (-not $devSha) {
    Write-Error "Cannot resolve 'dev' SHA in $pluginPath."
    exit 20
}

# ---------------------------------------------------------------------------
# Checkout main and FF-merge dev.
# ---------------------------------------------------------------------------
& git -C $pluginPath checkout main
if ($LASTEXITCODE -ne 0) {
    Write-Error "git -C $pluginPath checkout main failed."
    exit 20
}

if ($DryRun) {
    Write-Host "[DryRun] Would: git -C $pluginPath merge --ff-only dev (devSha=$devSha)"
} else {
    & git -C $pluginPath merge --ff-only dev
    if ($LASTEXITCODE -ne 0) {
        Write-Error "main has diverged from dev for plugin '$Plugin' — see docs/VERSIONING.md §Branch Discipline."
        exit 20
    }
}

# ---------------------------------------------------------------------------
# Compute next tag.
# ---------------------------------------------------------------------------
$currentTag = (git -C $pluginPath describe --tags --abbrev=0 main 2>$null)
if (-not $currentTag) {
    Write-Error "No existing tag on main for plugin '$Plugin'. Establish a v0.0.0 baseline first."
    exit 20
}
$currentTag = $currentTag.Trim()
$nextVer = Bump-SemVer -Current $currentTag -Component $Bump
Write-Host "Plugin '$Plugin': $currentTag -> $nextVer (devSha=$devSha)"

if ($DryRun) {
    Write-Host "[DryRun] Would: git -C $pluginPath tag -a $nextVer $devSha -m '$Plugin $nextVer'"
    Write-Host "[DryRun] Would: git -C $pluginPath push origin main --follow-tags"
    Write-Host "[DryRun] Would: git -C $pluginPath push origin dev"
    Write-Output $devSha
    exit 0
}

# ---------------------------------------------------------------------------
# Tag + push.
# ---------------------------------------------------------------------------
& git -C $pluginPath tag -a $nextVer $devSha -m "$Plugin $nextVer"
if ($LASTEXITCODE -ne 0) { Write-Error "git tag failed."; exit 20 }

& git -C $pluginPath push origin main --follow-tags
if ($LASTEXITCODE -ne 0) { Write-Error "git push origin main --follow-tags failed."; exit 20 }

& git -C $pluginPath push origin dev
if ($LASTEXITCODE -ne 0) { Write-Error "git push origin dev failed."; exit 20 }

# Stdout: new SHA for caller chaining.
Write-Output $devSha
exit 0
