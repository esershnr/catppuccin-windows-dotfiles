<#
.SYNOPSIS
    One-shot setup for a fresh Windows 11: installs every program through winget
    (default locations, no portable assumptions) and puts the repo configs in place.

.DESCRIPTION
    Order: winget check -> font -> programs -> configs. Already installed programs
    are skipped. Nothing is guessed: after each install the script looks for the
    files it needs, and reports FAIL / MANUAL when it cannot find them. A summary
    table is printed at the end and the whole run is logged.

    Run from the repo checkout (read-only is fine, the repo is never written):

        powershell -ExecutionPolicy Bypass -File .\bootstrap\install.ps1
        powershell -ExecutionPolicy Bypass -File .\bootstrap\install.ps1 -Only terminal,yasb
        powershell -ExecutionPolicy Bypass -File .\bootstrap\install.ps1 -DryRun

    Source file is ASCII-only on purpose (Windows PowerShell 5.1 misreads BOM-less UTF-8).

    Without -Only or -All a checkbox menu opens (arrows / Space / Enter): every step is
    ticked, untick the ones you do not want this time (komorebi, OpenRGB...).

.PARAMETER Only
    Run only the named steps (see $Steps below), no menu.

.PARAMETER All
    Run every step, no menu (unattended runs).

.PARAMETER DryRun
    Print what would happen, install and copy nothing.

.PARAMETER LogDir
    Where the log file goes. Default: %TEMP%.
#>
[CmdletBinding()]
param(
    [string[]] $Only,
    [switch]   $DryRun,
    [switch]   $All,
    [string]   $LogDir = $env:TEMP,
    [string]   $SourceUser = 'esershnr',
    [int]      $InstallTimeoutSec = 600
)

$ErrorActionPreference = 'Continue'
# "-Only a,b" arrives as one string when called through powershell.exe -File
if ($Only) { $Only = @($Only -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }) }
$Repo = Split-Path -Parent $PSScriptRoot
$Results = New-Object System.Collections.Generic.List[object]

New-Item -ItemType Directory -Force -Path $LogDir | Out-Null
$Log = Join-Path $LogDir ("bootstrap-{0:yyyyMMdd-HHmmss}.log" -f (Get-Date))
Start-Transcript -Path $Log | Out-Null

function Add-Result($Step, $State, $Note) {
    $Results.Add([pscustomobject]@{ Step = $Step; State = $State; Note = $Note })
    $color = @{ OK = 'Green'; SKIP = 'DarkGray'; FAIL = 'Red'; MANUAL = 'Yellow' }[$State]
    Write-Host ("  [{0}] {1}  {2}" -f $State, $Step, $Note) -ForegroundColor $color
}

function Update-SessionPath {
    $m = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $u = [Environment]::GetEnvironmentVariable('Path', 'User')
    $env:Path = "$m;$u"
}

function Test-Admin {
    ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole('Administrators')
}

function Find-Winget {
    $cmd = Get-Command winget.exe -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($cmd) { return $cmd.Source }
    $alias = Join-Path $env:LOCALAPPDATA 'Microsoft\WindowsApps\winget.exe'
    if (Test-Path $alias) { return $alias }
    $pkg = Get-AppxPackage -Name Microsoft.DesktopAppInstaller -ErrorAction SilentlyContinue |
        Sort-Object Version -Descending | Select-Object -First 1
    if ($pkg) {
        $exe = Join-Path $pkg.InstallLocation 'winget.exe'
        if (Test-Path $exe) { return $exe }
    }
    return $null
}

# Sets $script:Winget to the full path of winget.exe, or $null. Fresh Windows Sandbox
# ships without it; the repair below is the route Microsoft documents for Sandbox.
# A winget.exe that exists is not enough: Sandbox can ship an old App Installer whose
# every install fails. Probe with one real query and print what it says.
function Test-Winget {
    param([string] $Exe)
    if (-not $Exe) { return $false }
    $ver = (& $Exe --version 2>&1 | Out-String).Trim()
    $out = & $Exe search --id Git.Git --exact --source winget --accept-source-agreements --disable-interactivity 2>&1 | Out-String
    $ok = ($LASTEXITCODE -eq 0)
    Write-Host ("winget {0} at {1}: probe {2}" -f $ver, $Exe, $(if ($ok) { 'OK' } else { "FAILED ($LASTEXITCODE)" }))
    if (-not $ok) { Write-Host ($out.Trim() -split "`n" | Select-Object -Last 6 | Out-String) -ForegroundColor DarkYellow }
    return $ok
}

function Ensure-Winget {
    $script:Winget = Find-Winget
    if ($script:Winget -and ($DryRun -or (Test-Winget $script:Winget))) { return }
    $script:Winget = $null
    Write-Host 'winget missing or broken, installing it through Microsoft.WinGet.Client...' -ForegroundColor Yellow
    if ($DryRun) { return }
    $ProgressPreference = 'SilentlyContinue'
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Install-PackageProvider -Name NuGet -Force -ErrorAction Stop | Out-Null
        Install-Module -Name Microsoft.WinGet.Client -Force -Repository PSGallery -ErrorAction Stop | Out-Null
        Import-Module Microsoft.WinGet.Client -ErrorAction Stop
        Repair-WinGetPackageManager -AllUsers -Latest -ErrorAction Stop | Out-Null
    }
    catch { Write-Host "winget repair failed: $($_.Exception.Message)" -ForegroundColor Red }
    Update-SessionPath
    $script:Winget = Find-Winget
    if ($script:Winget) { & $script:Winget source reset --force 2>&1 | Out-Null }
    if (-not (Test-Winget $script:Winget)) { $script:Winget = $null }
}

# Runs winget as its own process with output going to temp files, and waits for that
# process only. Piping its output (| Out-String) hung on komorebi: the installer starts a
# background program that inherits the pipe and keeps it open forever.
function Invoke-WingetInstall {
    param([string] $Id)
    $outFile = [IO.Path]::GetTempFileName()
    $errFile = [IO.Path]::GetTempFileName()
    $argList = "install --id $Id --exact --source winget --no-upgrade --silent --accept-package-agreements --accept-source-agreements --disable-interactivity"
    $p = Start-Process -FilePath $script:Winget -ArgumentList $argList -NoNewWindow -PassThru `
        -RedirectStandardOutput $outFile -RedirectStandardError $errFile
    $null = $p.Handle   # cache the handle so ExitCode is readable after exit
    $timedOut = -not $p.WaitForExit($InstallTimeoutSec * 1000)
    if ($timedOut) { Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue }
    $text = (Get-Content $outFile, $errFile -Raw -ErrorAction SilentlyContinue) -join "`n"
    Remove-Item $outFile, $errFile -Force -ErrorAction SilentlyContinue
    [pscustomobject]@{ TimedOut = $timedOut; Code = $(if ($timedOut) { $null } else { $p.ExitCode }); Text = "$text" }
}

function Install-App {
    param([string] $Id)
    if ($DryRun) {
        & $script:Winget list --id $Id --exact --source winget --accept-source-agreements --disable-interactivity 2>&1 | Out-Null
        $state = if ($LASTEXITCODE -eq 0) { 'already installed' } else { 'would install' }
        Add-Result "winget $Id" 'SKIP' "dry run: $state"
        return $true
    }
    # No "winget list" pre-check: on a fresh VM the first list call stalled for minutes.
    # "install --no-upgrade" answers in under a second for an installed package
    # (exit 0x8A150061) and never upgrades it.
    $sw = [Diagnostics.Stopwatch]::StartNew()
    $r = Invoke-WingetInstall $Id
    $secs = [int]$sw.Elapsed.TotalSeconds
    Update-SessionPath
    if ($r.TimedOut) {
        # It may still have installed (the komorebi case); ask winget instead of assuming.
        & $script:Winget list --id $Id --exact --source winget 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) { Add-Result "winget $Id" 'OK' "installed in ${secs}s (winget timed out)"; return $true }
        Add-Result "winget $Id" 'FAIL' "timed out after ${secs}s"
        return $false
    }
    if ($r.Code -eq 0) { Add-Result "winget $Id" 'OK' "installed in ${secs}s"; return $true }
    if (('{0:X8}' -f $r.Code) -eq '8A150061') { Add-Result "winget $Id" 'SKIP' 'already installed'; return $true }
    $last = ($r.Text.Trim() -split "`n" | Where-Object { $_.Trim() } | Select-Object -Last 1)
    Add-Result "winget $Id" 'FAIL' ("exit 0x{0:X8} after {1}s: {2}" -f $r.Code, $secs, "$last".Trim())
    return $false
}

function Find-First {
    param([string[]] $Candidates)
    foreach ($c in $Candidates) {
        $hit = Get-Item -Path $c -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($hit) { return $hit.FullName }
    }
    return $null
}

# Some configs carry the source machine's user folder (C:\Users\<SourceUser>) or the
# <kullanici_adi> placeholder. Rewrite both to this machine's $HOME in the copied
# text files only; the repo is never touched. A BOM is kept as it was.
$TextExt = '.nss', '.json', '.jsonc', '.yaml', '.yml', '.css', '.conf', '.lua', '.xml', '.txt', '.ps1', '.ini'
$PlaceholderUser = '<kullan{0}c{0}_ad{0}>' -f [char]0x131

function Repair-UserPaths {
    param([string] $Path)
    $files = if (Test-Path $Path -PathType Container) { Get-ChildItem $Path -Recurse -File } else { Get-Item $Path }
    $back = $HOME.Replace('$', '$$')
    $fwd  = ($HOME -replace '\\', '/').Replace('$', '$$')
    $user = [regex]::Escape($SourceUser)
    $ph   = [regex]::Escape($PlaceholderUser)
    foreach ($f in $files) {
        if ($f.Extension -notin $TextExt) { continue }
        $bytes = [IO.File]::ReadAllBytes($f.FullName)
        $bom = $bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF
        $text = [IO.File]::ReadAllText($f.FullName)
        $new = $text -replace "(?i)C:\\Users\\$user(?=[\\'`"]|$)", $back
        $new = $new  -replace "(?i)C:/Users/$user(?=[/'`"]|$)", $fwd
        $new = $new  -replace "C:\\Users\\$ph", $back
        $new = $new  -replace "C:/Users/$ph", $fwd
        if ($new -ne $text) {
            [IO.File]::WriteAllText($f.FullName, $new, (New-Object Text.UTF8Encoding $bom))
            Write-Host "    user path fixed: $($f.FullName)" -ForegroundColor DarkCyan
        }
    }
}

function Copy-Config {
    param([string] $Step, [string] $From, [string] $To)
    if (-not (Test-Path $From)) { Add-Result $Step 'FAIL' "missing in repo: $From"; return }
    if ($DryRun) { Add-Result $Step 'SKIP' "dry run -> $To"; return }
    try {
        if (Test-Path $From -PathType Container) {
            # Copy the folder's contents: copying the folder onto an existing one (Nilesoft's
            # installer creates imports\ and icons\) nests it as imports\imports.
            New-Item -ItemType Directory -Force -Path $To | Out-Null
            Copy-Item (Join-Path $From '*') $To -Recurse -Force
        }
        else {
            New-Item -ItemType Directory -Force -Path (Split-Path $To) | Out-Null
            Copy-Item $From $To -Force
        }
        Repair-UserPaths $To
        Add-Result $Step 'OK' $To
    }
    catch { Add-Result $Step 'FAIL' $_.Exception.Message }
}

function Run-Script {
    param([string] $Step, [string] $Path, [string[]] $ScriptArgs)
    if (-not (Test-Path $Path)) { Add-Result $Step 'FAIL' "missing: $Path"; return }
    if ($DryRun) { Add-Result $Step 'SKIP' "dry run: $Path $($ScriptArgs -join ' ')"; return }
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $Path @ScriptArgs
    if ($LASTEXITCODE -eq 0) { Add-Result $Step 'OK' (Split-Path $Path -Leaf) }
    else { Add-Result $Step 'FAIL' ("exit code {0}" -f $LASTEXITCODE) }
}

# ---- steps ---------------------------------------------------------------
#
# Three phases, so a program never overwrites a config we just copied:
#   1. install every program (in the order below)
#   2. stop the ones that installers tend to auto-start and that rewrite their
#      own config on exit (Flow Launcher, OpenRGB, Notepad++, yasb, komorebi)
#   3. copy configs (same order)
# Order: font first (icons), Git before anything shell related, Everything before
# Flow Launcher, then plain apps; the steps that need admin or touch the system
# (Nilesoft shell extension, Windhawk injection, OpenRGB scheduled task) go last.
# Windows Terminal is never stopped: this script may be running inside it.

$Steps = [ordered]@{

    windows = @{
        Label  = 'dark mode + mauve accent'
        Apps   = @()
        Config = {
            # Values copied from this PC. The accent colour is what win11-accent-border (Windhawk)
            # paints window borders with; without it they stay Windows blue. Transparency stays off.
            if ($DryRun) { Add-Result 'windows dark mode + accent' 'SKIP' 'dry run'; return }
            try {
                $pers = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'
                $dwm  = 'HKCU:\Software\Microsoft\Windows\DWM'
                $acc  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Accent'
                foreach ($k in $pers, $dwm, $acc) { if (-not (Test-Path $k)) { New-Item -Path $k -Force | Out-Null } }
                $dword = @{
                    $pers = @{ AppsUseLightTheme = 0; SystemUsesLightTheme = 0; EnableTransparency = 0; ColorPrevalence = 0 }
                    $dwm  = @{ AccentColor = 0xfff7a6cb; ColorizationColor = 0xc4cba6f7; ColorizationAfterglow = 0xc4cba6f7
                               EnableWindowColorization = 1; ColorPrevalence = 0 }
                    $acc  = @{ AccentColorMenu = 0xfff7a6cb; StartColorMenu = 0xfff272ac }
                }
                foreach ($k in $dword.Keys) {
                    foreach ($v in $dword[$k].GetEnumerator()) {
                        Set-ItemProperty -Path $k -Name $v.Key -Value ([int] $v.Value) -Type DWord
                    }
                }
                $pal = 'E9D9FBFFD5B8F8FFC8A1F6FFBA8AF4FFAC72F2FF9F5BF0FF8C3AEDFF88179800'
                $bytes = [byte[]] -split ($pal -replace '..', '0x$& ')
                Set-ItemProperty -Path $acc -Name AccentPalette -Value $bytes -Type Binary
                Add-Result 'windows dark mode + accent' 'OK' 'accent #cba6f7, applies fully after sign-out'
            }
            catch { Add-Result 'windows dark mode + accent' 'FAIL' $_.Exception.Message }
        }
    }

    font = @{
        Apps   = @('DEVCOM.JetBrainsMonoNerdFont')
        Config = $null
    }

    terminal = @{
        Apps   = @('Git.Git', 'chrisant996.Clink', 'JanDeDobbeleer.OhMyPosh', 'Fastfetch-cli.Fastfetch', 'Microsoft.WindowsTerminal')
        Config = {
            # Windows PowerShell 5.1 ships PSReadLine 2.0.0; the profile's -PredictionSource and
            # -PredictionViewStyle need 2.1+. Plain Windows may also block the profile script.
            if ($DryRun) { Add-Result 'psreadline + execution policy' 'SKIP' 'dry run' }
            else {
                try {
                    # Run under -ExecutionPolicy Bypass, Set-ExecutionPolicy writes the CurrentUser value
                    # and then throws "overridden by a policy defined at a more specific scope".
                    # Ignore that and check the stored value instead.
                    try { Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force -ErrorAction Stop }
                    catch [System.Security.SecurityException] { }
                    $cu = Get-ExecutionPolicy -Scope CurrentUser
                    if ($cu -ne 'RemoteSigned') { throw "CurrentUser execution policy is '$cu', expected RemoteSigned" }
                    $ProgressPreference = 'SilentlyContinue'
                    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
                    Install-PackageProvider -Name NuGet -Force -Scope CurrentUser -ErrorAction Stop | Out-Null
                    Install-Module -Name PSReadLine -Scope CurrentUser -Force -SkipPublisherCheck -AllowClobber -Repository PSGallery -ErrorAction Stop
                    $v = (Get-Module PSReadLine -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1).Version
                    Add-Result 'psreadline + execution policy' 'OK' "PSReadLine $v, CurrentUser RemoteSigned"
                }
                catch { Add-Result 'psreadline + execution policy' 'FAIL' $_.Exception.Message }
            }
            Run-Script 'config terminal' (Join-Path $Repo 'terminal\sync.ps1') @('-Restore')
            if (-not $DryRun) {
                $profilePath = Join-Path $HOME 'Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1'
                if (Test-Path $profilePath) { Repair-UserPaths $profilePath }
            }
        }
    }

    flowlauncher = @{
        Apps   = @('voidtools.Everything', 'Flow-Launcher.Flow-Launcher')
        Procs  = @('Flow.Launcher')
        Config = {
            # flowlauncher\sync.ps1 is for the portable layout (app-*\UserData). A normal install keeps
            # the same tree under %APPDATA%\FlowLauncher (Settings\, Themes\; seen in the test VM).
            if (-not (Test-Installed 'Flow-Launcher.Flow-Launcher' 'config flowlauncher')) { return }
            $data = Join-Path $env:APPDATA 'FlowLauncher'
            Copy-Config 'config flowlauncher settings' (Join-Path $Repo 'flowlauncher\UserData\Settings') (Join-Path $data 'Settings')
            Get-ChildItem (Join-Path $Repo 'flowlauncher') -Filter '*.xaml' | ForEach-Object {
                Copy-Config "config flowlauncher theme $($_.BaseName)" $_.FullName (Join-Path $data "Themes\$($_.Name)")
            }
            # Flow writes its Run key only when the option is toggled in its UI, so a restored
            # Settings.json alone does not start it at logon. A Run value written here was skipped
            # by Explorer on the test VM (no Shell-Core 9707 event for it), so use a Startup
            # shortcut like yasb. It points at the Squirrel stub, which survives app-* updates.
            $exe = Find-First @("$env:LOCALAPPDATA\FlowLauncher\Flow.Launcher.exe", "$env:LOCALAPPDATA\FlowLauncher\app-*\Flow.Launcher.exe")
            if (-not $exe) { Add-Result 'flowlauncher autostart' 'FAIL' 'Flow.Launcher.exe not found'; return }
            $lnk = Join-Path ([Environment]::GetFolderPath('Startup')) 'Flow Launcher.lnk'
            if ($DryRun) { Add-Result 'flowlauncher autostart' 'SKIP' "dry run: $lnk -> $exe"; return }
            Remove-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name 'Flow.Launcher' -ErrorAction SilentlyContinue
            $sc = (New-Object -ComObject WScript.Shell).CreateShortcut($lnk)
            $sc.TargetPath = $exe
            $sc.WorkingDirectory = Split-Path $exe
            $sc.Save()
            Add-Result 'flowlauncher autostart' 'OK' $lnk
        }
    }

    komorebi = @{
        Apps   = @('LGUG2Z.komorebi')
        Procs  = @('komorebi', 'komorebi-bar')
        Config = {
            foreach ($f in 'komorebi.json', 'applications.json') {
                Copy-Config "config komorebi $f" (Join-Path $Repo "komorebi\$f") (Join-Path $HOME $f)
            }
        }
    }

    yasb = @{
        Apps   = @('AmN.yasb')
        Procs  = @('yasb')
        Config = {
            $dst = Join-Path $HOME '.config\yasb'
            Copy-Config 'config yasb config.yaml' (Join-Path $Repo 'yasb\config.yaml') (Join-Path $dst 'config.yaml')
            Copy-Config 'config yasb styles.css'  (Join-Path $Repo 'yasb\styles.css')  (Join-Path $dst 'styles.css')
            if (-not (Test-Path (Join-Path $dst '.env'))) {
                Add-Result 'config yasb .env' 'MANUAL' 'secrets are not in the repo: fill ~\.config\yasb\.env by hand'
            }
            # The installer does not start yasb at logon (test VM); this PC uses a Startup shortcut.
            if (-not (Test-Installed 'AmN.yasb' 'yasb autostart')) { return }
            $exe = Find-First @("$env:ProgramFiles\YASB\yasb.exe", "$env:ProgramFiles\yasb\yasb.exe",
                                "$env:LOCALAPPDATA\Programs\YASB\yasb.exe", "$env:ProgramFiles\YASB*\yasb.exe")
            if (-not $exe) { Add-Result 'yasb autostart' 'FAIL' 'yasb.exe not found (check winget location)'; return }
            $lnk = Join-Path ([Environment]::GetFolderPath('Startup')) 'YASB.lnk'
            if ($DryRun) { Add-Result 'yasb autostart' 'SKIP' "dry run: $lnk -> $exe"; return }
            $sc = (New-Object -ComObject WScript.Shell).CreateShortcut($lnk)
            $sc.TargetPath = $exe
            $sc.WorkingDirectory = Split-Path $exe
            $sc.Save()
            Add-Result 'yasb autostart' 'OK' $lnk
        }
    }

    mpv = @{
        Apps   = @('shinchiro.mpv')
        Procs  = @('mpv')
        Config = {
            $src = Join-Path $Repo 'mpv\portable_config'
            $dst = Join-Path $env:APPDATA 'mpv'
            if ($DryRun) { Add-Result 'config mpv' 'SKIP' "dry run -> $dst"; return }
            try {
                New-Item -ItemType Directory -Force -Path $dst | Out-Null
                Get-ChildItem $src -Force | Where-Object { $_.Name -notin 'cache', 'watch_later' } |
                    ForEach-Object { Copy-Item $_.FullName $dst -Recurse -Force }
                Repair-UserPaths $dst
                Add-Result 'config mpv' 'OK' $dst
            }
            catch { Add-Result 'config mpv' 'FAIL' $_.Exception.Message }
        }
    }

    notepadpp = @{
        Apps   = @('Notepad++.Notepad++')
        Procs  = @('notepad++')
        Config = {
            Copy-Config 'config notepad++ theme' (Join-Path $Repo 'notepad++\catppuccin-mocha.xml') `
                (Join-Path $env:APPDATA 'Notepad++\themes\catppuccin-mocha.xml')
            # The theme file alone does nothing: dark mode and the selected theme live in config.xml.
            # Merge only the look nodes (notepad++\config-ui.xml); config.xml itself is not tracked.
            # No config.xml yet (never started): the snippet becomes it, Notepad++ fills in the rest.
            $cfg  = Join-Path $env:APPDATA 'Notepad++\config.xml'
            $snip = Join-Path $Repo 'notepad++\config-ui.xml'
            if ($DryRun) { Add-Result 'config notepad++ dark mode' 'SKIP' "dry run -> $cfg"; return }
            try {
                if (-not (Test-Path $cfg)) {
                    New-Item -ItemType Directory -Force -Path (Split-Path $cfg) | Out-Null
                    Copy-Item $snip $cfg
                    Add-Result 'config notepad++ dark mode' 'OK' "created $cfg"
                    return
                }
                $doc = New-Object Xml.XmlDocument; $doc.PreserveWhitespace = $true; $doc.Load($cfg)
                $ui  = New-Object Xml.XmlDocument; $ui.Load($snip)
                $guis = $doc.SelectSingleNode('/NotepadPlus/GUIConfigs')
                if (-not $guis) { throw 'no NotepadPlus/GUIConfigs in config.xml' }
                foreach ($n in $ui.SelectNodes('/NotepadPlus/GUIConfigs/GUIConfig')) {
                    $new = $doc.ImportNode($n, $true)
                    $old = $guis.SelectSingleNode("GUIConfig[@name='$($n.GetAttribute('name'))']")
                    if ($old) { [void] $guis.ReplaceChild($new, $old) } else { [void] $guis.AppendChild($new) }
                }
                $doc.Save($cfg)
                Add-Result 'config notepad++ dark mode' 'OK' "merged into $cfg"
            }
            catch { Add-Result 'config notepad++ dark mode' 'FAIL' $_.Exception.Message }
        }
    }

    ytm = @{
        Apps   = @('Ytmdesktop.Ytmdesktop')
        Config = {
            Add-Result 'config ytm-desktop' 'MANUAL' 'set customCSSPath to the repo mocha.css inside the app'
        }
    }

    nilesoft = @{
        Apps   = @('Nilesoft.Shell')
        Config = {
            if (-not (Test-Installed 'Nilesoft.Shell' 'config nilesoft')) { return }
            $dir = Find-First @("$env:ProgramFiles\Nilesoft Shell", "${env:ProgramFiles(x86)}\Nilesoft Shell", "$env:ProgramFiles\Nilesoft*")
            if (-not $dir) { Add-Result 'config nilesoft' 'FAIL' 'install dir not found (check winget location)'; return }
            if (-not (Test-Admin)) { Add-Result 'config nilesoft' 'FAIL' 'needs an elevated shell'; return }
            foreach ($n in 'shell.nss', 'imports', 'icons') {
                Copy-Config "config nilesoft $n" (Join-Path $Repo "nilesoft-shell\$n") (Join-Path $dir $n)
            }
        }
    }

    windhawk = @{
        Apps   = @('RamenSoftware.Windhawk')
        Config = {
            if (-not (Test-Installed 'RamenSoftware.Windhawk' 'config windhawk')) { return }
            Run-Script 'config windhawk' (Join-Path $Repo 'windhawk\sync.ps1') @('-Restore')
            # No reboot needed: sync.ps1 also puts the mods' C++ runtime (libc++.whl) in place, and
            # the service restart loads every mod. Mods that hook by symbol download them on first
            # load (needs msdl.microsoft.com) and apply when that finishes.
        }
    }

    openrgb = @{
        Apps   = @('OpenRGB.OpenRGB')
        Procs  = @('OpenRGB')
        Config = {
            if (-not (Test-Installed 'OpenRGB.OpenRGB' 'config openrgb')) { return }
            $exe = Find-First @("$env:ProgramFiles\OpenRGB\OpenRGB.exe", "$env:ProgramFiles\OpenRGB*\OpenRGB.exe",
                                "${env:ProgramFiles(x86)}\OpenRGB*\OpenRGB.exe", "$env:LOCALAPPDATA\Programs\OpenRGB*\OpenRGB.exe")
            if (-not $exe) { Add-Result 'config openrgb' 'FAIL' 'OpenRGB.exe not found (check winget location)'; return }
            foreach ($f in 'Green.orp', 'OFF.orp', 'OpenRGB.json') {
                Copy-Config "config openrgb $f" (Join-Path $Repo "openrgb\$f") (Join-Path $env:APPDATA "OpenRGB\$f")
            }
            Run-Script 'openrgb scheduled task' (Join-Path $Repo 'openrgb\install.ps1') @('-OpenRGBExe', $exe)
        }
    }
}

$Installed = @{}

function Test-Installed {
    param([string] $Id, [string] $Step)
    if ($Installed[$Id]) { return $true }
    Add-Result $Step 'SKIP' 'program not installed'
    return $false
}

# ---- step menu -----------------------------------------------------------
# Adapted from experimental\setup.ps1. Returns the chosen step names, or $null on quit.

function Test-InteractiveConsole {
    try { -not [Console]::IsInputRedirected -and -not [Console]::IsOutputRedirected } catch { $false }
}

function Show-StepMenu {
    param([string[]] $Names)

    $label = @{}
    foreach ($n in $Names) {
        $label[$n] = if ($Steps[$n].Label) { $Steps[$n].Label }
                     else { ($Steps[$n].Apps | ForEach-Object { ($_ -split '\.', 2)[-1] }) -join ', ' }
    }

    if (-not (Test-InteractiveConsole)) {
        Write-Host 'Steps:'
        for ($i = 0; $i -lt $Names.Count; $i++) { Write-Host ("  {0,2}) {1,-13} {2}" -f ($i + 1), $Names[$i], $label[$Names[$i]]) }
        $raw = Read-Host 'Selection (e.g. 1,2,5 | all | q)'
        if (-not $raw -or $raw -eq 'q') { return $null }
        if ($raw -eq 'all') { return $Names }
        return @($raw -split ',' | Where-Object { $_.Trim() -match '^\d+$' } |
            ForEach-Object { $Names[[int]$_.Trim() - 1] } | Where-Object { $_ })
    }

    $sel = New-Object 'System.Collections.Generic.HashSet[string]'
    foreach ($n in $Names) { [void] $sel.Add($n) }
    $cursor = 0
    $rows   = $Names.Count + 4
    $origVisible = [Console]::CursorVisible
    $origCtrlC   = [Console]::TreatControlCAsInput
    1..$rows | ForEach-Object { Write-Host '' }
    $top = [Console]::CursorTop - $rows

    try {
        [Console]::CursorVisible = $false
        [Console]::TreatControlCAsInput = $true
        # Drop keys already waiting in the buffer (a stray right-click paste would toggle rows).
        while ([Console]::KeyAvailable) { [void] [Console]::ReadKey($true) }
        while ($true) {
            # One short of the window width: a full-width line wraps and shifts every frame down.
            $w = [Math]::Max(40, [Console]::WindowWidth - 1)
            [Console]::SetCursorPosition(0, $top)
            Write-Host ('  bootstrap: pick what to install'.PadRight($w)) -ForegroundColor Cyan
            Write-Host ('  Up/Down move | Space toggle | A all | N none | Enter start | Q quit'.PadRight($w)) -ForegroundColor DarkGray
            Write-Host ''.PadRight($w)
            for ($i = 0; $i -lt $Names.Count; $i++) {
                $n = $Names[$i]
                $row = '{0} {1} {2} {3}' -f $(if ($i -eq $cursor) { '>' } else { ' ' }),
                    $(if ($sel.Contains($n)) { '[x]' } else { '[ ]' }), $n.PadRight(13), $label[$n]
                if ($row.Length -gt $w) { $row = $row.Substring(0, $w) }
                $color = if ($i -eq $cursor) { 'White' } elseif ($sel.Contains($n)) { 'Gray' } else { 'DarkGray' }
                Write-Host $row.PadRight($w) -ForegroundColor $color
            }
            Write-Host ("  $($sel.Count) of $($Names.Count) selected".PadRight($w)) -ForegroundColor Cyan

            $key = [Console]::ReadKey($true)
            if ($key.Key -eq 'C' -and ($key.Modifiers -band [ConsoleModifiers]::Control)) { return $null }
            switch ($key.Key) {
                'UpArrow'   { $cursor = ($cursor - 1 + $Names.Count) % $Names.Count }
                'DownArrow' { $cursor = ($cursor + 1) % $Names.Count }
                'Spacebar'  { $n = $Names[$cursor]; if (-not $sel.Remove($n)) { [void] $sel.Add($n) } }
                'A'         { foreach ($n in $Names) { [void] $sel.Add($n) } }
                'N'         { $sel.Clear() }
                'Enter'     { return @($Names | Where-Object { $sel.Contains($_) }) }
                'Q'         { return $null }
                'Escape'    { return $null }
            }
        }
    }
    finally {
        [Console]::CursorVisible = $origVisible
        [Console]::TreatControlCAsInput = $origCtrlC
        try { [Console]::SetCursorPosition(0, $top + $rows) } catch { }
    }
}

# ---- run -----------------------------------------------------------------

Write-Host "bootstrap: repo=$Repo log=$Log admin=$(Test-Admin) dryrun=$DryRun" -ForegroundColor Cyan

# Pick first, so the rest (winget repair, installs) can run unattended.
$allSteps = @($Steps.Keys)
if ($Only)    { $selected = @($allSteps | Where-Object { $_ -in $Only }) }
elseif ($All) { $selected = $allSteps }
else          { $selected = Show-StepMenu $allSteps }
if (-not $selected -or $selected.Count -eq 0) {
    Write-Host 'Nothing selected, exiting.' -ForegroundColor Yellow
    Stop-Transcript | Out-Null
    return
}
Write-Host ("steps: {0}" -f ($selected -join ', ')) -ForegroundColor Cyan

Ensure-Winget
if (-not $script:Winget) {
    Add-Result 'winget' 'FAIL' 'not available, stopping before any install or copy'
}
else {

    Write-Host "`n==== 1/3 install ====" -ForegroundColor Cyan
    foreach ($name in $selected) {
        foreach ($id in $Steps[$name].Apps) { $Installed[$id] = Install-App $id }
    }

    Write-Host "`n==== 2/3 stop auto-started programs ====" -ForegroundColor Cyan
    $procs = @($selected | ForEach-Object { $Steps[$_].Procs } | Where-Object { $_ })
    foreach ($p in $procs) {
        $running = Get-Process -Name $p -ErrorAction SilentlyContinue
        if (-not $running) { continue }
        if ($DryRun) { Write-Host "  would stop $p"; continue }
        $running | Stop-Process -Force -ErrorAction SilentlyContinue
        Write-Host "  stopped $p"
    }

    Write-Host "`n==== 3/3 configs ====" -ForegroundColor Cyan
    foreach ($name in $selected) {
        if (-not $Steps[$name].Config) { continue }
        Write-Host "`n== $name" -ForegroundColor Cyan
        & $Steps[$name].Config
    }
}

# winget changed PATH in the registry, but Explorer (and every window started from the Start
# menu) still holds the old one until told: terminals opened afterwards could not find
# oh-my-posh / fastfetch. Broadcast WM_SETTINGCHANGE "Environment" so new windows see it.
if (-not $DryRun) {
    Add-Type -Namespace Bootstrap -Name Native -MemberDefinition @'
[DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
public static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint Msg, UIntPtr wParam, string lParam, uint fuFlags, uint uTimeout, out UIntPtr lpdwResult);
'@
    $res = [UIntPtr]::Zero
    [void][Bootstrap.Native]::SendMessageTimeout([IntPtr]0xffff, 0x1A, [UIntPtr]::Zero, 'Environment', 2, 5000, [ref]$res)
    if ('windows' -in $selected) {
        # Same broadcast for the theme and accent keys, so open windows pick up dark mode now.
        [void][Bootstrap.Native]::SendMessageTimeout([IntPtr]0xffff, 0x1A, [UIntPtr]::Zero, 'ImmersiveColorSet', 2, 5000, [ref]$res)
    }
    Write-Host "`nEnvironment change broadcast. Open NEW terminal windows (old ones keep the old PATH)." -ForegroundColor Cyan
}
Write-Host "`n==== summary ====" -ForegroundColor Cyan
$Results | Format-Table -AutoSize | Out-String -Width 200 | Write-Host
$fail = @($Results | Where-Object State -eq 'FAIL').Count
$man  = @($Results | Where-Object State -eq 'MANUAL').Count
if ($man) {
    Write-Host "`n==== left for you ====" -ForegroundColor Yellow
    $Results | Where-Object State -eq 'MANUAL' | ForEach-Object { Write-Host ("  - {0}: {1}" -f $_.Step, $_.Note) -ForegroundColor Yellow }
}
Write-Host ("FAIL={0} MANUAL={1} log={2}" -f $fail, $man, $Log)
Stop-Transcript | Out-Null
