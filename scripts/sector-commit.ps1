<#
.SYNOPSIS
    Transactional sector commit + SHA pin for a plugin submodule.

.DESCRIPTION
    Pushes the current plugin `dev` HEAD to origin, verifies the push via
    ls-remote, then commits and pushes the host-repo submodule pointer
    update. Closes the associated bd issue only after both pushes land.

    Failure-mode handling (binding amendments from consensus plan):
      - Plugin push failure        -> exit 10 (no host changes)
      - ls-remote SHA mismatch     -> exit 11 (no host changes)
      - Host push failure, clean   -> exit 12 (host commit auto-reset to $preCommitSha)
      - Host push failure, manual  -> exit 13 (manual remediation; remote advanced
                                              OR partial-success state)
      - Precondition failure       -> exit 20

.PARAMETER Plugin
    Plugin name (matches HostProject/Plugins/<name> directory).

.PARAMETER SectorId
    Sector ID in the form M{milestone}.S{sector} (e.g. M1.S1).

.PARAMETER BdId
    Beads issue id to close on success (e.g. samp-1).

.PARAMETER DryRun
    Print the plan; perform no git mutations.

.EXAMPLE
    scripts/sector-commit.ps1 -Plugin SamplePlugin -SectorId M1.S1 -BdId samp-1

.NOTES
    Must be run from the host repo root (path-guard enforces this).
    See docs/VERSIONING.md and CLAUDE.md (Push-or-Not-Done Protocol).
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $Plugin,

    [Parameter(Mandatory = $true)]
    [ValidatePattern('^M\d+\.S\d+$')]
    [string] $SectorId,

    [Parameter(Mandatory = $true)]
    [string] $BdId,

    [switch] $DryRun
)

$ErrorActionPreference = 'Continue'  # script checks $LASTEXITCODE explicitly; git writes progress to stderr.

# ---------------------------------------------------------------------------
# Path-guard (R2 mitigation): refuse to run anywhere other than host root.
# ---------------------------------------------------------------------------
if (-not (Test-Path 'HostProject/HostProject.uproject')) {
    throw "sector-commit.ps1 must be run from the host repo root (HostProject/HostProject.uproject not found in cwd '$PWD')."
}

$pluginPath = "HostProject/Plugins/$Plugin"
if (-not (Test-Path $pluginPath)) {
    Write-Error "Plugin directory not found: $pluginPath"
    exit 20
}

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------
$timestamp = (Get-Date -Format 'yyyyMMdd-HHmmss')
# Use absolute paths via .NET API; PS 5.1 -LiteralPath misresolves relative
# paths when cwd contains '[' or ']' (treats them as wildcards even with -Literal).
$logDir    = [System.IO.Path]::GetFullPath((Join-Path $PWD.ProviderPath '.omc/logs'))
if (-not [System.IO.Directory]::Exists($logDir)) { [System.IO.Directory]::CreateDirectory($logDir) | Out-Null }
$logPath = Join-Path $logDir "sector-commit-$timestamp.log"

function Write-Log {
    param([string] $Message, [string] $Level = 'INFO')
    $line = "[{0}] [{1}] {2}" -f (Get-Date -Format 's'), $Level, $Message
    Write-Host $line
    [System.IO.File]::AppendAllText($logPath, $line + [Environment]::NewLine)
}

Write-Log "sector-commit start: Plugin=$Plugin SectorId=$SectorId BdId=$BdId DryRun=$DryRun"

# ---------------------------------------------------------------------------
# Preconditions
# ---------------------------------------------------------------------------
$pluginStatus = git -C $pluginPath status --porcelain
if ($pluginStatus) {
    Write-Log "Plugin tree is dirty:`n$pluginStatus" 'ERROR'
    exit 20
}

$pluginBranch = (git -C $pluginPath rev-parse --abbrev-ref HEAD).Trim()
if ($pluginBranch -ne 'dev') {
    Write-Log "Plugin must be on 'dev' branch (currently '$pluginBranch')." 'ERROR'
    exit 20
}

# ---------------------------------------------------------------------------
# Step 1 — capture plugin HEAD SHA
# ---------------------------------------------------------------------------
$pluginSha = (git -C $pluginPath rev-parse HEAD).Trim()
Write-Log "pluginSha = $pluginSha"

if ($DryRun) {
    Write-Log "[DryRun] Would: push $Plugin/dev, verify ls-remote, capture host preCommitSha, commit pin, push host, bd close $BdId."
    Write-Log "sector-commit end (dry-run)"
    exit 0
}

# ---------------------------------------------------------------------------
# Step 2 — push plugin/dev
# ---------------------------------------------------------------------------
Write-Log "Pushing $Plugin/dev to origin..."
& git -C $pluginPath push origin dev 2>&1 | ForEach-Object { Write-Log "$_" 'CMD' }
if ($LASTEXITCODE -ne 0) {
    Write-Log "Plugin push failed (exit $LASTEXITCODE). Host repo untouched." 'ERROR'
    exit 10
}

# ---------------------------------------------------------------------------
# Step 3 — verify push via ls-remote (Critic amendment #3)
# ---------------------------------------------------------------------------
$lsRemote  = git -C $pluginPath ls-remote origin refs/heads/dev
$remoteSha = ($lsRemote -split '\s+' | Select-Object -First 1).Trim()
Write-Log "remoteSha = $remoteSha (expected $pluginSha)"
if ($remoteSha -ne $pluginSha) {
    Write-Log "ls-remote mismatch: remote=$remoteSha local=$pluginSha. Host repo untouched." 'ERROR'
    exit 11
}

# ---------------------------------------------------------------------------
# Step 4 — capture host pre-commit SHA (Critic amendment #1)
# ---------------------------------------------------------------------------
$preCommitSha = (git rev-parse HEAD).Trim()
Write-Log "host preCommitSha = $preCommitSha"

# ---------------------------------------------------------------------------
# Step 5 — host commit (pin update). Swap hooksPath around the commit so
#         bd hooks do not interfere.
# ---------------------------------------------------------------------------
$prevHooksPath = (git config --get core.hooksPath) 2>$null
git config core.hooksPath .git/hooks | Out-Null
try {
    & git add $pluginPath 2>&1 | ForEach-Object { Write-Log "$_" 'CMD' }
    if ($LASTEXITCODE -ne 0) {
        Write-Log "git add failed (exit $LASTEXITCODE)." 'ERROR'
        exit 20
    }

    $msg = "pin: $Plugin@$pluginSha (sector $SectorId, bd:$BdId)"
    & git commit -m $msg 2>&1 | ForEach-Object { Write-Log "$_" 'CMD' }
    if ($LASTEXITCODE -ne 0) {
        Write-Log "git commit failed (exit $LASTEXITCODE). Likely no submodule pointer change to record." 'ERROR'
        exit 20
    }

    $hostBranch = (git rev-parse --abbrev-ref HEAD).Trim()
    Write-Log "Pushing host/$hostBranch to origin..."
    & git push origin $hostBranch 2>&1 | ForEach-Object { Write-Log "$_" 'CMD' }
    $pushExit = $LASTEXITCODE

    if ($pushExit -ne 0) {
        Write-Log "Host push failed (exit $pushExit). Begin failure-mode-(c) handling." 'WARN'

        # Critic amendment #2: fetch first; if upstream advanced since
        # $preCommitSha, refuse auto-reset.
        & git fetch 2>&1 | ForEach-Object { Write-Log "$_" 'CMD' }
        $upstream = (git rev-parse "$hostBranch@{u}" 2>$null).Trim()
        Write-Log "upstream=$upstream preCommitSha=$preCommitSha"

        # If upstream is not an ancestor of preCommitSha, the remote moved
        # forward since we captured preCommitSha. Refuse auto-reset.
        $isAncestor = $false
        if ($upstream) {
            & git merge-base --is-ancestor $upstream $preCommitSha 2>$null
            if ($LASTEXITCODE -eq 0) { $isAncestor = $true }
        }

        # Detect partial success: the remote ref already equals our local
        # commit (push reported failure but the ref landed). Treat as 13.
        $localTip = (git rev-parse HEAD).Trim()
        if ($upstream -eq $localTip) {
            Write-Log "Remote ref equals local tip; partial-success on host push." 'ERROR'
            Write-Log "Manual remediation required: verify remote state, then run 'bd close $BdId' manually." 'ERROR'
            exit 13
        }

        if ($upstream -and -not $isAncestor) {
            Write-Log "Remote advanced past preCommitSha ($preCommitSha). Auto-reset refused." 'ERROR'
            Write-Log "Manual recovery: 'git reflog'; reset to $preCommitSha after reconciling, then re-run." 'ERROR'
            exit 12
        }

        # Clean recovery: reset hard to preCommitSha (NEVER HEAD~1).
        Write-Log "Clean recovery: git reset --hard $preCommitSha"
        & git reset --hard $preCommitSha 2>&1 | ForEach-Object { Write-Log "$_" 'CMD' }
        exit 12
    }
}
finally {
    if ($prevHooksPath) {
        git config core.hooksPath $prevHooksPath | Out-Null
    } else {
        git config --unset core.hooksPath | Out-Null
    }
}

# ---------------------------------------------------------------------------
# Step 6 — close bd issue (only after both pushes succeeded)
# ---------------------------------------------------------------------------
Write-Log "Closing bd issue $BdId..."
& bd close $BdId 2>&1 | ForEach-Object { Write-Log "$_" 'CMD' }
if ($LASTEXITCODE -ne 0) {
    Write-Log "bd close failed (exit $LASTEXITCODE). Host commit landed; resolve manually." 'WARN'
    # Both pushes succeeded; surface as non-fatal warning.
}

Write-Log "sector-commit complete. Continue to next sector?"
exit 0
