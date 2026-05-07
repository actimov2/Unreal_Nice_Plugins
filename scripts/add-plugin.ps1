<#
.SYNOPSIS
  Add an existing plugin repo as a git submodule under HostProject/Plugins/.

.PARAMETER Url
  Git URL of the plugin repo (HTTPS or SSH).

.PARAMETER Name
  Folder name to use under HostProject/Plugins/ (defaults to repo name).

.EXAMPLE
  .\scripts\add-plugin.ps1 -Url https://github.com/actimov2/MyPlugin.git
  .\scripts\add-plugin.ps1 -Url git@github.com:actimov2/MyPlugin.git -Name MyPluginCustomFolder
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Url,

    [Parameter()]
    [string]$Name
)

$ErrorActionPreference = 'Stop'
$RepoRoot = (Resolve-Path "$PSScriptRoot\..").Path

if (-not $Name) {
    if ($Url -match '/([^/]+?)(\.git)?$') {
        $Name = $Matches[1]
    } else {
        throw "Could not infer name from URL. Pass -Name explicitly."
    }
}

$Target = "HostProject/Plugins/$Name"
$AbsTarget = Join-Path $RepoRoot $Target
if (Test-Path $AbsTarget) {
    throw "Folder already exists: $AbsTarget"
}

Push-Location $RepoRoot
try {
    Write-Host "==> Adding submodule: $Url -> $Target" -ForegroundColor Cyan
    git submodule add $Url $Target
    git submodule update --init --recursive $Target
    git add .gitmodules $Target
    git commit -m "Add $Name plugin as submodule"
} finally {
    Pop-Location
}

Write-Host ""
Write-Host "✓ Submodule added. Don't forget to:" -ForegroundColor Green
Write-Host "  - Add `"$Name`" to HostProject.uproject's `"Plugins`" array if you want it enabled by default"
Write-Host "  - Regenerate VS project files"
