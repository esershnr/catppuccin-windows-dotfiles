<#
.SYNOPSIS
    Backs up / restores Flow Launcher settings to this repo.

.DESCRIPTION
    Flow Launcher (portable) keeps its config under a version-bumping folder:

        <root>\FlowLauncher\app-<version>\UserData\Settings\

    On every app update that path moves to the new app-<version>, which is why
    symlinking these files does not survive updates - so this module uses copy
    (like terminal/ and openrgb/), not link/.

    Only the files worth versioning are tracked - the rest (plugin binaries,
    cache, logs, per-machine window geometry churn) is left alone:

        Settings\Settings.json
            hotkey, theme, startup, per-plugin enable/disable + action keywords
        Settings\Plugins\Flow.Launcher.Plugin.Explorer\Settings.json
            Quick Access links + Everything as index/path/content engine
        Settings\Plugins\Flow.Launcher.Plugin.Program\Settings.json
            Program Sources (C:\Tools\Apps portable-exe scan)

    Note: Settings.json carries some noisy fields (ActivateTimes, window
    coordinates, ReleaseNotesVersion). Expect a little diff noise on -Backup;
    just review 'git diff' before committing.

.PARAMETER Backup
    Copy the live settings on this machine INTO the repo. Run before committing
    after you change anything in the Flow Launcher settings window.

.PARAMETER Restore
    Copy the repo settings ONTO this machine. Flow Launcher rewrites these files
    on exit, so it must be closed first - the script refuses to run while
    Flow.Launcher is alive unless -Force is given.

.PARAMETER FlowLauncherRoot
    Portable install root. Default: C:\Tools\Apps\Flow-Launcher-Portable

.EXAMPLE
    .\sync.ps1 -Backup
    .\sync.ps1 -Restore
#>
[CmdletBinding(DefaultParameterSetName = 'None')]
param(
    [Parameter(ParameterSetName = 'Backup',  Mandatory)] [switch] $Backup,
    [Parameter(ParameterSetName = 'Restore', Mandatory)] [switch] $Restore,
    [switch] $Force,
    [string] $FlowLauncherRoot = 'C:\Tools\Apps\Flow-Launcher-Portable'
)

$ErrorActionPreference = 'Stop'

$RepoSettings = Join-Path $PSScriptRoot 'UserData\Settings'

# Files tracked, relative to the Settings\ dir on both sides.
$Tracked = @(
    'Settings.json'
    'Plugins\Flow.Launcher.Plugin.Explorer\Settings.json'
    'Plugins\Flow.Launcher.Plugin.Program\Settings.json'
)

function Resolve-LiveSettings {
    $base = Join-Path $FlowLauncherRoot 'FlowLauncher'
    $hit = Get-ChildItem -Path $base -Directory -Filter 'app-*' -ErrorAction SilentlyContinue |
        ForEach-Object {
            $s = Join-Path $_.FullName 'UserData\Settings'
            if (Test-Path (Join-Path $s 'Settings.json')) {
                [pscustomobject]@{ Path = $s; Version = ($_.Name -replace '^app-', '') }
            }
        } |
        Sort-Object { try { [version]$_.Version } catch { [version]'0.0.0' } } -Descending |
        Select-Object -First 1
    if (-not $hit) { throw "No Flow Launcher settings found under '$base\app-*\UserData\Settings'." }
    $hit.Path
}

function Copy-Set {
    param([string] $FromRoot, [string] $ToRoot)
    foreach ($rel in $Tracked) {
        $src = Join-Path $FromRoot $rel
        if (-not (Test-Path $src)) { Write-Warning "skip (missing): $rel"; continue }
        $dst = Join-Path $ToRoot $rel
        New-Item -ItemType Directory -Force -Path (Split-Path $dst) | Out-Null
        Copy-Item $src $dst -Force
        Write-Host "  $rel" -ForegroundColor Green
    }
}

if ($PSCmdlet.ParameterSetName -eq 'None') {
    Write-Host "Usage: .\sync.ps1 -Backup    (machine -> repo)"
    Write-Host "       .\sync.ps1 -Restore   (repo -> machine; close Flow Launcher first)"
    return
}

$Live = Resolve-LiveSettings

if ($Backup) {
    Write-Host "Backup: $Live -> repo" -ForegroundColor Cyan
    Copy-Set -FromRoot $Live -ToRoot $RepoSettings
    Write-Host "`nDone. Review 'git diff' in flowlauncher/ and commit." -ForegroundColor Cyan
    return
}

if ($Restore) {
    $proc = Get-Process -Name 'Flow.Launcher' -ErrorAction SilentlyContinue
    if ($proc -and -not $Force) {
        throw "Flow Launcher is running - it will overwrite restored files on exit. Close it and retry (or pass -Force)."
    }
    Write-Host "Restore: repo -> $Live" -ForegroundColor Cyan
    Copy-Set -FromRoot $RepoSettings -ToRoot $Live
    Write-Host "`nDone. Start Flow Launcher." -ForegroundColor Cyan
    return
}
