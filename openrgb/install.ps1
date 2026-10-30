<#
.SYNOPSIS
    Sets up OpenRGB to replace ASUS Armoury Crate on this box: a scheduled task
    that applies the "Green" profile on logon, plus suspend/resume lighting profiles
    so the RAM RGB turns off in sleep and comes back on wake.

.DESCRIPTION
    ASUS Armoury Crate was removed in favour of OpenRGB. Two things Armoury Crate did
    for free that OpenRGB needs help with:

    1. Persist lighting across a power cycle. On cold boot the motherboard / Aura DDR4
       firmware reverts to its factory Rainbow effect, so OpenRGB has to re-push the
       profile every boot. OpenRGB's own "Start At Login" only drops a plain shortcut
       in the Startup folder, which runs UNELEVATED - not enough to drive the Aura
       DDR4 modules over SMBus / PawnIO (an unelevated launch returns 0x800702E4
       ELEVATION_REQUIRED and the RAM stays Rainbow). This script registers a
       Scheduled Task with RunLevel Highest instead, so OpenRGB starts elevated and
       silently (no UAC prompt) a few seconds after logon.

    2. Turn lighting off on sleep. DIMM slots keep power in S3 for self-refresh, and
       the ENE DRAM controller holds its last colour, so the RAM RGB stays lit in
       sleep unless something explicitly blanks it. This script points OpenRGB's
       suspend/resume autoload profiles at an all-black "OFF" profile on suspend and
       back to "Green" on resume (written into %APPDATA%\OpenRGB\OpenRGB.json). The
       resident tray instance from the logon task catches the Windows power events.

    The script self-elevates (one UAC prompt) to register the task.

.PARAMETER DelaySeconds
    Seconds to wait after logon before launching OpenRGB. Default 5. Give the SMBus a
    moment to settle on cold boot; raise to 10-15 if the RAM occasionally stays
    Rainbow (see README).

.PARAMETER OpenRGBExe
    Full path to OpenRGB.exe. Defaults to the portable location under C:\Tools.

.PARAMETER ResumeProfile
    Profile applied on logon and on resume from sleep. Default "Green".

.PARAMETER SuspendProfile
    Profile applied on suspend (all-black = lights off). Default "OFF".

.PARAMETER Uninstall
    Remove the scheduled task and exit. Leaves profiles and OpenRGB.json untouched.

.EXAMPLE
    .\install.ps1
    .\install.ps1 -DelaySeconds 12
    .\install.ps1 -Uninstall
#>
[CmdletBinding()]
param(
    [int]    $DelaySeconds   = 5,
    [string] $OpenRGBExe     = "C:\Tools\Apps\OpenRGB\OpenRGB Windows 64-bit\OpenRGB.exe",
    [string] $ResumeProfile  = "Green",
    [string] $SuspendProfile = "OFF",
    [switch] $Uninstall
)

$ErrorActionPreference = 'Stop'
$TaskName    = 'OpenRGB Green Profile'
$StartupLnk  = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Startup\OpenRGB.lnk'
$SettingsJson = Join-Path $env:APPDATA 'OpenRGB\OpenRGB.json'
$Profiles    = @($ResumeProfile, $SuspendProfile) | Select-Object -Unique

function Test-Admin {
    ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
        ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# --- self-elevate: registering a RunLevel-Highest task needs an admin token ---
if (-not (Test-Admin)) {
    Write-Host "Elevation required - re-launching as administrator..." -ForegroundColor Yellow
    $fwd = @('-NoProfile','-ExecutionPolicy','Bypass','-File',"`"$PSCommandPath`"",
             '-DelaySeconds',$DelaySeconds,'-OpenRGBExe',"`"$OpenRGBExe`"",
             '-ResumeProfile',"`"$ResumeProfile`"",'-SuspendProfile',"`"$SuspendProfile`"")
    if ($Uninstall) { $fwd += '-Uninstall' }
    Start-Process powershell -Verb RunAs -ArgumentList $fwd
    return
}

if ($Uninstall) {
    if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
        Write-Host "Removed scheduled task '$TaskName'." -ForegroundColor Green
    } else {
        Write-Host "Scheduled task '$TaskName' not found - nothing to do."
    }
    Write-Host "Note: OpenRGB's own 'Start At Login', the profile files and the"
    Write-Host "      suspend/resume settings in OpenRGB.json were left in place."
    return
}

if (-not (Test-Path $OpenRGBExe)) {
    throw "OpenRGB.exe not found at '$OpenRGBExe'. Pass -OpenRGBExe with the correct path."
}

# --- 1. make sure the profiles exist where OpenRGB looks for them ---
New-Item -ItemType Directory -Force -Path (Split-Path $SettingsJson) | Out-Null
foreach ($p in $Profiles) {
    $src = Join-Path $PSScriptRoot "$p.orp"
    $dst = Join-Path $env:APPDATA "OpenRGB\$p.orp"
    if (Test-Path $src) {
        Copy-Item $src $dst -Force
        Write-Host "Copied $p.orp -> $dst" -ForegroundColor Green
    } else {
        Write-Warning "$p.orp not found next to this script; skipping (create it in OpenRGB and re-run)."
    }
}

# --- 2. register the scheduled task (logon + delay, elevated, single instance) ---
$action  = New-ScheduledTaskAction -Execute $OpenRGBExe -Argument "--startminimized --profile `"$ResumeProfile`""
$trigger = New-ScheduledTaskTrigger -AtLogOn -User "$env:USERDOMAIN\$env:USERNAME"
$trigger.Delay = ('PT{0}S' -f [int]$DelaySeconds)
$principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" `
                -LogonType Interactive -RunLevel Highest
$settings  = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries `
                -StartWhenAvailable -ExecutionTimeLimit ([TimeSpan]::Zero) -MultipleInstances IgnoreNew

Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger `
    -Principal $principal -Settings $settings -Force `
    -Description "Applies the OpenRGB '$ResumeProfile' profile ${DelaySeconds}s after logon (elevated; delay lets SMBus/ENE DRAM settle on cold boot)." | Out-Null
Write-Host "Registered scheduled task '$TaskName' (logon +${DelaySeconds}s, RunLevel Highest)." -ForegroundColor Green

# --- 3. point OpenRGB's suspend/resume autoload profiles at OFF / Green ---
#     DIMM RGB keeps power in S3 and the ENE DRAM controller holds its last colour,
#     so without a suspend profile the RAM stays lit in sleep.
#     Patched as raw text: OpenRGB.json holds a detector list with case-colliding
#     keys that ConvertFrom-Json chokes on, so we can't round-trip the object.
$autoloadBlock = @(
    '"autoload_profiles": {'
    '    "suspend_profile": {'
    '        "enabled": true,'
    "        `"name`": `"$SuspendProfile`""
    '    },'
    '    "resume_profile": {'
    '        "enabled": true,'
    "        `"name`": `"$ResumeProfile`""
    '    },'
    '    "exit_profile": {'
    '        "enabled": false,'
    "        `"name`": `"$ResumeProfile`""
    '    }'
    '}'
)
$rx = '(?s)(?<ind>[ \t]*)"autoload_profiles"\s*:\s*\{.*?\r?\n\k<ind>\},'
if (Test-Path $SettingsJson) {
    $raw = Get-Content $SettingsJson -Raw
    if ($raw -match $rx) {
        $ind   = $matches['ind']
        $block = (($autoloadBlock | ForEach-Object { $ind + $_ }) -join "`n") + ','
        $new   = [regex]::Replace($raw, $rx,
                    [System.Text.RegularExpressions.MatchEvaluator]{ param($m) $block })
        Set-Content $SettingsJson $new -Encoding UTF8 -NoNewline
        Write-Host "Set suspend->'$SuspendProfile' / resume->'$ResumeProfile' in OpenRGB.json." -ForegroundColor Green
    } else {
        Write-Warning "Could not find 'autoload_profiles' in OpenRGB.json - set it by hand:"
        Write-Warning "  OpenRGB -> Settings -> 'Set profile on suspend' = $SuspendProfile, '...on resume' = $ResumeProfile"
    }
} else {
    Write-Warning "OpenRGB.json not found - run OpenRGB once, then re-run this script (or copy the bundled OpenRGB.json)."
}

# --- 4. drop OpenRGB's own Startup shortcut so the two don't race ---
if (Test-Path $StartupLnk) {
    Remove-Item $StartupLnk -Force
    Write-Host "Removed OpenRGB's own Startup shortcut." -ForegroundColor Green
}

# Only ask for the manual step when 'Start At Login' is really on. The bundled OpenRGB.json
# ships it off; read as raw text for the same reason as the patch above.
$autoStartOn = $true
if (Test-Path $SettingsJson) {
    $autoStartOn = (Get-Content $SettingsJson -Raw) -match '"AutoStart"\s*:\s*\{[^}]*"enabled"\s*:\s*true'
}
if ($autoStartOn) {
    Write-Host ""
    Write-Host "One manual step left:" -ForegroundColor Cyan
    Write-Host "  Open OpenRGB -> Settings tab -> UNCHECK 'Start At Login'"
    Write-Host "  (or set AutoStart.enabled = false in %APPDATA%\OpenRGB\OpenRGB.json)."
    Write-Host "  Otherwise OpenRGB re-creates the Startup shortcut and both fire on boot."
}
Write-Host ""
Write-Host "Restart OpenRGB once so it picks up the new OpenRGB.json, then:"
Write-Host "  - test logon:  Start-ScheduledTask -TaskName '$TaskName'"
Write-Host "  - test sleep:  put the PC to sleep; RAM RGB should go dark, then return on wake."
