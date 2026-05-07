<#
.SYNOPSIS
  Create a new UE5 plugin from the SamplePlugin template and wire it into this monorepo as a private GitHub repo + git submodule.

.DESCRIPTION
  Workflow:
    1. Copy HostProject/Plugins/SamplePlugin/ to a temp folder, renamed to <Name>
    2. Rename all SamplePlugin → Name references in code, files, .uplugin
    3. git init the temp folder, initial commit
    4. Create a PRIVATE repo on GitHub via `gh` CLI
    5. Push the plugin to GitHub
    6. Remove temp folder, add it back as a submodule under HostProject/Plugins/<Name>
    7. Commit .gitmodules in the host repo

  Requires: git, gh (GitHub CLI), authenticated as actimov2.

.PARAMETER Name
  PascalCase plugin name. Will be used as folder name, module name, GitHub repo name.

.PARAMETER Description
  Short description for the .uplugin and GitHub repo.

.PARAMETER Public
  If set, the GitHub repo is created as public instead of private.

.EXAMPLE
  .\scripts\new-plugin.ps1 -Name MyAwesomePlugin -Description "Does something cool"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[A-Z][A-Za-z0-9]+$')]
    [string]$Name,

    [Parameter()]
    [string]$Description = "A new Unreal Engine plugin.",

    [Parameter()]
    [switch]$Public
)

$ErrorActionPreference = 'Stop'
$RepoRoot = (Resolve-Path "$PSScriptRoot\..").Path
$Template = Join-Path $RepoRoot "HostProject\Plugins\SamplePlugin"
$PluginsDir = Join-Path $RepoRoot "HostProject\Plugins"
$TargetDir = Join-Path $PluginsDir $Name
$GitHubUser = "actimov2"

# --- preflight ---
Write-Host "==> Pre-flight checks" -ForegroundColor Cyan

if (-not (Test-Path $Template)) {
    throw "Template not found at $Template. Did you delete SamplePlugin?"
}
if (Test-Path $TargetDir) {
    throw "Folder already exists: $TargetDir"
}
foreach ($cmd in @('git', 'gh')) {
    if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
        throw "$cmd not found in PATH. Install it first."
    }
}

$ghStatus = gh auth status 2>&1
if ($LASTEXITCODE -ne 0) {
    throw "gh CLI not authenticated. Run: gh auth login"
}

# --- Step 1: copy template to temp ---
$Temp = Join-Path $env:TEMP "uep_new_$Name`_$(Get-Random)"
Write-Host "==> Copying template to $Temp" -ForegroundColor Cyan
Copy-Item -Path $Template -Destination $Temp -Recurse
# clean any stray build output the template might have
Get-ChildItem -Path $Temp -Recurse -Force -Directory `
    | Where-Object { $_.Name -in 'Binaries','Intermediate','Build','DerivedDataCache','Saved','.vs','.git' } `
    | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

# --- Step 2: rename SamplePlugin -> $Name in file contents and filenames ---
Write-Host "==> Renaming SamplePlugin -> $Name" -ForegroundColor Cyan

# rename files
Get-ChildItem -Path $Temp -Recurse -File `
    | Where-Object { $_.Name -like '*SamplePlugin*' } `
    | ForEach-Object {
        $newName = $_.Name -replace 'SamplePlugin', $Name
        Rename-Item -Path $_.FullName -NewName $newName
    }

# rename folders (deepest first to avoid path invalidation)
Get-ChildItem -Path $Temp -Recurse -Directory `
    | Where-Object { $_.Name -like '*SamplePlugin*' } `
    | Sort-Object -Property { $_.FullName.Length } -Descending `
    | ForEach-Object {
        $newName = $_.Name -replace 'SamplePlugin', $Name
        Rename-Item -Path $_.FullName -NewName $newName
    }

# replace contents
$textExt = @('.cpp','.h','.cs','.uplugin','.md','.txt','.json','.ini')
Get-ChildItem -Path $Temp -Recurse -File `
    | Where-Object { $textExt -contains $_.Extension } `
    | ForEach-Object {
        $content = Get-Content $_.FullName -Raw
        $content = $content -replace 'SamplePlugin', $Name
        # update description in the new .uplugin
        if ($_.Name -like '*.uplugin') {
            $content = $content -replace '"Description"\s*:\s*".*?"', "`"Description`": `"$Description`""
            $content = $content -replace '"FriendlyName"\s*:\s*".*?"',
                "`"FriendlyName`": `"$Name`""
        }
        Set-Content -Path $_.FullName -Value $content -NoNewline
    }

# --- Step 3: git init + initial commit ---
Write-Host "==> Initializing git repo in $Temp" -ForegroundColor Cyan
Push-Location $Temp
try {
    git init -b main 2>&1 | Out-Null
    git add -A
    git -c user.name="$GitHubUser" -c user.email="$GitHubUser@users.noreply.github.com" `
        commit -m "Initial commit: $Name plugin scaffolded from SamplePlugin template" | Out-Null
} finally {
    Pop-Location
}

# --- Step 4: create GitHub repo ---
$visibility = if ($Public) { '--public' } else { '--private' }
Write-Host "==> Creating GitHub repo $GitHubUser/$Name ($visibility)" -ForegroundColor Cyan
gh repo create "$GitHubUser/$Name" $visibility --description $Description --source $Temp --push
if ($LASTEXITCODE -ne 0) {
    throw "gh repo create failed."
}

$RepoUrl = "https://github.com/$GitHubUser/$Name.git"

# --- Step 5: cleanup temp, add as submodule in host ---
Write-Host "==> Removing temp folder" -ForegroundColor Cyan
Remove-Item -Path $Temp -Recurse -Force

Write-Host "==> Adding $Name as submodule" -ForegroundColor Cyan
Push-Location $RepoRoot
try {
    git submodule add $RepoUrl "HostProject/Plugins/$Name"
    git submodule update --init --recursive "HostProject/Plugins/$Name"
    git add .gitmodules "HostProject/Plugins/$Name"
    git commit -m "Add $Name plugin as submodule" | Out-Null
} finally {
    Pop-Location
}

Write-Host ""
Write-Host "✓ Done!" -ForegroundColor Green
Write-Host "  Plugin:    HostProject\Plugins\$Name" -ForegroundColor Green
Write-Host "  GitHub:    $RepoUrl" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Right-click HostProject\HostProject.uproject -> Generate Visual Studio project files"
Write-Host "  2. Open HostProject.uproject -> UE Editor will prompt to build"
Write-Host "  3. Add `"$Name`" to HostProject.uproject `"Plugins`" array if you want it enabled by default"
