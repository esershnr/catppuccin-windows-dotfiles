<#
.SYNOPSIS
    Backs up / restores the full Windhawk state (mods + every setting) to this repo.

.DESCRIPTION
    Windhawk keeps no single config file. Everything lives in three places:

      1. HKLM\SOFTWARE\Windhawk  ....  which mods are enabled/disabled and EVERY
                                        mod setting (the styler YAML blobs included).
      2. %ProgramData%\Windhawk\ModsSource\*.wh.cpp  ....  the mod source. Keeping a
                                        copy lets a fresh box recompile offline and
                                        preserves any locally edited / custom mods.
      3. %ProgramData%\Windhawk\userprofile.json  ....  the installed-mod list and
                                        version pins Windhawk reconciles against.

      4. %ProgramData%\Windhawk\Engine\Mods\{32,64}\*.dll  ....  the compiled mods.
                                        Each mod's registry entry names its DLL
                                        (LibraryFileName). Windhawk does NOT rebuild
                                        them from ModsSource on service start (seen
                                        on a clean VM, 2026-10-30): without the DLLs
                                        every mod sits inactive until it is updated
                                        or reinstalled by hand. So they are tracked.

      Most mod DLLs also import the C++ runtime as libc++.whl / libunwind.whl from
      the same Engine\Mods\{32,64} folder. Windhawk does not ship those there: the
      UI copies them from Compiler\<target>\bin (libc++.dll -> libc++.whl) only when
      its editor extension starts, i.e. when the full UI is opened. A box that only
      ever ran the tray never gets them, and every such mod fails to load with
      0x8007007E (seen on the test VM, 2026-10-30). Restore copies them the same way,
      from the installed compiler, so they always match the installed Windhawk.

    This is the method from ramensoftware/windhawk#195 / discussions#155, still
    current on Windhawk 1.7.3 (2026).

.PARAMETER Backup
    Capture the live state on this machine INTO the repo:
      windhawk/settings/windhawk.reg   (reg export of HKLM\SOFTWARE\Windhawk)
      windhawk/ModsSource/*.wh.cpp
      windhawk/userprofile.json
      windhawk/Engine/Mods/{32,64}/*.dll
    Run this before committing after you change mods in the Windhawk UI.

.PARAMETER Restore
    Apply the repo state ONTO this machine: copy ModsSource, userprofile.json, the
    compiled mod DLLs and the mods' C++ runtime (from the installed Windhawk compiler)
    into %ProgramData%\Windhawk, import the .reg, then restart the
    Windhawk service so it reloads. Self-elevates (one UAC prompt) - importing into
    HKLM and restarting a service both need admin.

.EXAMPLE
    .\sync.ps1 -Backup
    .\sync.ps1 -Restore
#>
[CmdletBinding(DefaultParameterSetName = 'None')]
param(
    [Parameter(ParameterSetName = 'Backup',  Mandatory)] [switch] $Backup,
    [Parameter(ParameterSetName = 'Restore', Mandatory)] [switch] $Restore
)

$ErrorActionPreference = 'Stop'

$RepoDir      = $PSScriptRoot
$RegFile      = Join-Path $RepoDir 'settings\windhawk.reg'
$RepoModsSrc  = Join-Path $RepoDir 'ModsSource'
$RepoProfile  = Join-Path $RepoDir 'userprofile.json'
$RepoDlls     = Join-Path $RepoDir 'Engine\Mods'

$AppData      = Join-Path $env:ProgramData 'Windhawk'
$LiveModsSrc  = Join-Path $AppData 'ModsSource'
$LiveProfile  = Join-Path $AppData 'userprofile.json'
$LiveDlls     = Join-Path $AppData 'Engine\Mods'
$RegKey       = 'HKLM\SOFTWARE\Windhawk'
$ServiceName  = 'Windhawk'

function Test-Admin {
    ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
        ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# reg.exe writes its "success" line to stderr; under $ErrorActionPreference='Stop'
# PowerShell would turn that into a terminating error and abort the run. Go through
# cmd so only a real non-zero exit code counts as failure.
function Invoke-Reg {
    param([Parameter(Mandatory)][string[]] $RegArgs)
    $quoted = $RegArgs | ForEach-Object { if ($_ -match '\s') { "`"$_`"" } else { $_ } }
    $out = cmd /c "reg $($quoted -join ' ') 2>&1"
    if ($LASTEXITCODE -ne 0) { throw "reg $($RegArgs -join ' ') failed ($LASTEXITCODE): $out" }
}

if ($PSCmdlet.ParameterSetName -eq 'None') {
    Write-Host "Usage: .\sync.ps1 -Backup   (machine -> repo)"
    Write-Host "       .\sync.ps1 -Restore  (repo -> machine, elevates)"
    return
}

# ---------------------------------------------------------------- BACKUP --------
if ($Backup) {
    if (-not (Test-Path $AppData)) { throw "Windhawk not found at '$AppData'." }

    New-Item -ItemType Directory -Force -Path (Split-Path $RegFile) | Out-Null

    # reg export needs an elevated token to read all of HKLM\SOFTWARE\Windhawk.
    if (-not (Test-Admin)) {
        Write-Host "Elevation required for reg export - re-launching as admin..." -ForegroundColor Yellow
        Start-Process powershell -Verb RunAs -ArgumentList @(
            '-NoProfile','-ExecutionPolicy','Bypass','-File',"`"$PSCommandPath`"",'-Backup')
        return
    }

    Invoke-Reg @('export', $RegKey, $RegFile, '/y')
    Write-Host "Exported $RegKey -> settings\windhawk.reg" -ForegroundColor Green

    if (Test-Path $RepoModsSrc) { Remove-Item $RepoModsSrc -Recurse -Force }
    New-Item -ItemType Directory -Force -Path $RepoModsSrc | Out-Null
    Copy-Item (Join-Path $LiveModsSrc '*.wh.cpp') $RepoModsSrc -Force
    $n = (Get-ChildItem $RepoModsSrc -Filter *.wh.cpp).Count
    Write-Host "Copied $n mod source file(s) -> ModsSource\" -ForegroundColor Green

    Copy-Item $LiveProfile $RepoProfile -Force
    Write-Host "Copied userprofile.json -> repo" -ForegroundColor Green

    # Mirror the compiled mods, so DLLs of removed / updated mods do not linger.
    if (Test-Path $RepoDlls) { Remove-Item $RepoDlls -Recurse -Force }
    foreach ($arch in '32', '64') {
        $from = Join-Path $LiveDlls $arch
        if (-not (Test-Path $from)) { continue }
        $to = Join-Path $RepoDlls $arch
        New-Item -ItemType Directory -Force -Path $to | Out-Null
        Copy-Item (Join-Path $from '*.dll') $to -Force
    }
    $n = @(Get-ChildItem $RepoDlls -Recurse -Filter *.dll -ErrorAction SilentlyContinue).Count
    Write-Host "Copied $n compiled mod DLL(s) -> Engine\Mods\" -ForegroundColor Green

    Write-Host ""
    Write-Host "Done. Review 'git diff' in windhawk/ and commit." -ForegroundColor Cyan
    return
}

# --------------------------------------------------------------- RESTORE --------
if ($Restore) {
    foreach ($p in @($RegFile, $RepoModsSrc, $RepoProfile)) {
        if (-not (Test-Path $p)) { throw "Missing '$p'. Run '.\sync.ps1 -Backup' on a configured box first." }
    }

    if (-not (Test-Admin)) {
        Write-Host "Elevation required (HKLM import + service restart) - re-launching as admin..." -ForegroundColor Yellow
        Start-Process powershell -Verb RunAs -ArgumentList @(
            '-NoProfile','-ExecutionPolicy','Bypass','-File',"`"$PSCommandPath`"",'-Restore')
        return
    }

    if (-not (Test-Path $AppData)) {
        throw "Windhawk not installed ('$AppData' missing). Install Windhawk first: winget install RamenSoftware.Windhawk"
    }

    New-Item -ItemType Directory -Force -Path $LiveModsSrc | Out-Null
    Copy-Item (Join-Path $RepoModsSrc '*.wh.cpp') $LiveModsSrc -Force
    Write-Host "Copied mod sources -> $LiveModsSrc" -ForegroundColor Green

    Copy-Item $RepoProfile $LiveProfile -Force
    Write-Host "Copied userprofile.json -> $LiveProfile" -ForegroundColor Green

    # Compiled mods. A DLL name carries the mod version and a build id, so a file that
    # already exists is the same build; skip it (it may be loaded and locked).
    if (Test-Path $RepoDlls) {
        $n = 0
        foreach ($arch in '32', '64') {
            $from = Join-Path $RepoDlls $arch
            if (-not (Test-Path $from)) { continue }
            $to = Join-Path $LiveDlls $arch
            New-Item -ItemType Directory -Force -Path $to | Out-Null
            Get-ChildItem $from -Filter *.dll | Where-Object { -not (Test-Path (Join-Path $to $_.Name)) } |
                ForEach-Object { Copy-Item $_.FullName $to; $n++ }
        }
        Write-Host "Copied $n compiled mod DLL(s) -> $LiveDlls" -ForegroundColor Green
    }
    else { Write-Warning "No Engine\Mods in the repo: mods stay inactive until updated in the Windhawk UI." }

    # The mods' C++ runtime, copied the way the Windhawk UI does it (copyCompilerLibs in
    # UI\resources\app\extensions\windhawk\dist\extension.js). Without it every mod that
    # imports libc++.whl fails with 0x8007007E until the full UI is opened once.
    $svcImage = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\$ServiceName").ImagePath
    $InstallDir = Split-Path ($svcImage -replace '^"([^"]+)".*$', '$1')
    $compilerRel = 'Compiler'
    $ini = Join-Path $InstallDir 'windhawk.ini'
    if (Test-Path $ini) {
        $line = Get-Content $ini | Where-Object { $_ -match '^\s*CompilerPath\s*=' } | Select-Object -First 1
        if ($line) { $compilerRel = ($line -split '=', 2)[1].Trim() }
    }
    $CompilerDir = [Environment]::ExpandEnvironmentVariables($compilerRel)
    if (-not [IO.Path]::IsPathRooted($CompilerDir)) { $CompilerDir = Join-Path $InstallDir $CompilerDir }
    $n = 0
    foreach ($t in @(@{ Target = 'i686-w64-mingw32'; Arch = '32' }, @{ Target = 'x86_64-w64-mingw32'; Arch = '64' })) {
        $from = Join-Path $CompilerDir "$($t.Target)\bin"
        if (-not (Test-Path $from)) { Write-Warning "No compiler libs at '$from'."; continue }
        $to = Join-Path $LiveDlls $t.Arch
        New-Item -ItemType Directory -Force -Path $to | Out-Null
        foreach ($pair in @(@('libc++.dll', 'libc++.whl'), @('libunwind.dll', 'libunwind.whl'), @('windhawk-mod-shim.dll', 'windhawk-mod-shim.dll'))) {
            $src = Join-Path $from $pair[0]
            $dst = Join-Path $to $pair[1]
            if (-not (Test-Path $src)) { Write-Warning "Missing '$src'."; continue }
            # Same rule as the UI: copy when missing or the timestamp differs. Copy-Item keeps
            # the timestamp, so the UI will not copy them again. A loaded file is locked; keep it.
            if ((Test-Path $dst) -and (Get-Item $dst).LastWriteTimeUtc -eq (Get-Item $src).LastWriteTimeUtc) { continue }
            try { Copy-Item $src $dst -Force; $n++ }
            catch { if (Test-Path $dst) { Write-Warning "'$dst' is in use, kept the existing one." } else { throw } }
        }
    }
    Write-Host "Copied $n mod runtime file(s) (libc++.whl, libunwind.whl, mod shim) -> $LiveDlls" -ForegroundColor Green

    Invoke-Reg @('import', $RegFile)
    Write-Host "Imported settings\windhawk.reg -> $RegKey" -ForegroundColor Green

    Write-Host "Restarting the $ServiceName service (reloads mods)..." -ForegroundColor Yellow
    # A single Restart-Service right after a fresh install failed on the test VM ("Failed to
    # start service"), leaving every mod unloaded even after a reboot. Stop, wait for it to
    # settle, then start with a few retries and check it really runs.
    Stop-Service -Name $ServiceName -Force -ErrorAction SilentlyContinue
    (Get-Service -Name $ServiceName).WaitForStatus('Stopped', [TimeSpan]::FromSeconds(30))
    $started = $false
    foreach ($try in 1..4) {
        try { Start-Service -Name $ServiceName -ErrorAction Stop; $started = $true; break }
        catch { Write-Warning "Start attempt $try failed: $($_.Exception.Message)"; Start-Sleep -Seconds (5 * $try) }
    }
    if (-not $started -or (Get-Service -Name $ServiceName).Status -ne 'Running') {
        throw "Windhawk service did not start. Reboot, then run '.\sync.ps1 -Restore' again."
    }
    Write-Host "Service restarted." -ForegroundColor Green

    Write-Host ""
    Write-Host "Restore complete. Open the Windhawk UI to confirm each mod is loaded." -ForegroundColor Cyan
    return
}
