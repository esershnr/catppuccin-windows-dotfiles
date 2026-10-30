<#
.SYNOPSIS
    Backs up / restores the terminal setup (PowerShell, CMD/Clink, Git Bash,
    Windows Terminal, oh-my-posh, fastfetch) to / from this repo.

.DESCRIPTION
    Copy strategy (like flowlauncher/ and openrgb/), not symlinks: symlinks failed
    on Windows. Tracked files, repo side -> machine side:

        WindowsPowerShell\Microsoft.PowerShell_profile.ps1 -> ~\Documents\WindowsPowerShell\
        ohmyposh\*.omp.json                                -> ~\.config\ohmyposh\
        fastfetch\config.jsonc, ascii.txt                  -> ~\.config\fastfetch\
        settings.json                                      -> Windows Terminal LocalState\
        CMD\fastfetch.lua                                  -> %LOCALAPPDATA%\clink\
        bash\.bashrc, .bash_profile, .minttyrc             -> ~\

    fastfetch\config.jsonc keeps a "<user name>" placeholder in the repo
    (C:/Users/<placeholder>/.config/...). -Backup writes the placeholder back,
    -Restore fills in the current user name.

    -Restore also configures Clink when it is installed: quiet autorun, oh-my-posh
    as the prompt, and the mauve theme path. Programs and fonts are NOT installed
    here, see terminal\README.md ("Format sonrasi hizli kurulum").

.PARAMETER Backup
    Copy the live files on this machine INTO the repo. Run before committing.

.PARAMETER Restore
    Copy the repo files ONTO this machine (overwrites). Supports -WhatIf.

.EXAMPLE
    .\sync.ps1 -Backup
    .\sync.ps1 -Restore -WhatIf
    .\sync.ps1 -Restore
#>
[CmdletBinding(DefaultParameterSetName = 'None', SupportsShouldProcess)]
param(
    [Parameter(ParameterSetName = 'Backup',  Mandatory)] [switch] $Backup,
    [Parameter(ParameterSetName = 'Restore', Mandatory)] [switch] $Restore
)

$ErrorActionPreference = 'Stop'

$WtState = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState'

# fastfetch placeholder, built from code points so this file stays ASCII-only
# (Windows PowerShell 5.1 misreads BOM-less UTF-8).
$Placeholder = '<kullan{0}c{0}_ad{0}>' -f [char]0x131

# Repo path (relative to this script) -> live path. Transform marks the files
# whose user name is swapped for the placeholder.
$Map = @(
    @{ Repo = 'WindowsPowerShell\Microsoft.PowerShell_profile.ps1'; Live = Join-Path $HOME 'Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1' }
    @{ Repo = 'ohmyposh\esershnr-mauve.omp.json'; Live = Join-Path $HOME '.config\ohmyposh\esershnr-mauve.omp.json' }
    @{ Repo = 'ohmyposh\esershnr.omp.json';       Live = Join-Path $HOME '.config\ohmyposh\esershnr.omp.json' }
    @{ Repo = 'fastfetch\config.jsonc'; Live = Join-Path $HOME '.config\fastfetch\config.jsonc'; Transform = $true }
    @{ Repo = 'fastfetch\ascii.txt';    Live = Join-Path $HOME '.config\fastfetch\ascii.txt' }
    @{ Repo = 'settings.json';          Live = Join-Path $WtState 'settings.json' }
    @{ Repo = 'CMD\fastfetch.lua';      Live = Join-Path $env:LOCALAPPDATA 'clink\fastfetch.lua' }
    @{ Repo = 'bash\.bashrc';       Live = Join-Path $HOME '.bashrc' }
    @{ Repo = 'bash\.bash_profile'; Live = Join-Path $HOME '.bash_profile' }
    @{ Repo = 'bash\.minttyrc';     Live = Join-Path $HOME '.minttyrc' }
)

function Copy-One {
    param([string] $From, [string] $To, [bool] $Transform, [string] $Mode)
    if (-not (Test-Path $From)) { Write-Warning "skip (missing): $From"; return }
    if (-not $PSCmdlet.ShouldProcess($To, 'write')) { return }
    New-Item -ItemType Directory -Force -Path (Split-Path $To) | Out-Null
    if ($Transform) {
        $text = [IO.File]::ReadAllText($From)
        $user = [regex]::Escape($env:USERNAME)
        if ($Mode -eq 'Backup') { $text = $text -replace "C:/Users/$user/", "C:/Users/$Placeholder/" }
        else { $text = $text -replace 'C:/Users/<[^>]+>/', "C:/Users/$($env:USERNAME)/" }
        [IO.File]::WriteAllText($To, $text, (New-Object Text.UTF8Encoding $false))
    }
    else {
        Copy-Item $From $To -Force
    }
    Write-Host "  $To" -ForegroundColor Green
}

function Set-ClinkConfig {
    $clink = Get-Command clink -ErrorAction SilentlyContinue
    if (-not $clink) {
        $fallback = Join-Path ${env:ProgramFiles(x86)} 'clink\clink_x64.exe'
        if (Test-Path $fallback) { $clink = $fallback } else { Write-Warning 'Clink not found, skipping its config.'; return }
    }
    else { $clink = $clink.Source }
    $theme = Join-Path $HOME '.config\ohmyposh\esershnr-mauve.omp.json'
    if (-not $PSCmdlet.ShouldProcess('Clink', 'autorun --quiet, oh-my-posh prompt, theme')) { return }
    & $clink autorun uninstall | Out-Null
    & $clink autorun install -- --quiet | Out-Null
    & $clink config prompt use oh-my-posh | Out-Null
    & $clink set ohmyposh.theme $theme | Out-Null
    Write-Host '  Clink: quiet autorun, oh-my-posh prompt, mauve theme' -ForegroundColor Green
}

if ($PSCmdlet.ParameterSetName -eq 'None') {
    Write-Host 'Usage: .\sync.ps1 -Backup    (machine -> repo)'
    Write-Host '       .\sync.ps1 -Restore   (repo -> machine, overwrites; -WhatIf to preview)'
    return
}

if ($Backup) {
    Write-Host 'Backup: machine -> repo' -ForegroundColor Cyan
    foreach ($m in $Map) {
        Copy-One -From $m.Live -To (Join-Path $PSScriptRoot $m.Repo) -Transform ([bool]$m.Transform) -Mode 'Backup'
    }
    Write-Host "`nDone. Review 'git diff' in terminal/ and commit." -ForegroundColor Cyan
    return
}

if ($Restore) {
    Write-Host 'Restore: repo -> machine' -ForegroundColor Cyan
    foreach ($m in $Map) {
        Copy-One -From (Join-Path $PSScriptRoot $m.Repo) -To $m.Live -Transform ([bool]$m.Transform) -Mode 'Restore'
    }
    Set-ClinkConfig
    Write-Host "`nDone. Close all terminals and open fresh ones (Git Bash window too)." -ForegroundColor Cyan
    return
}
