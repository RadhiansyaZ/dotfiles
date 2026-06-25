#Requires -Version 5.1
<#
.SYNOPSIS
    Standalone Windows setup: winget packages + WSL-dotfiles symlinks.

.DESCRIPTION
    Creates Windows config symlinks that point into the dotfiles repo on the WSL filesystem
    via the \\wsl$\<distro> UNC path. Optionally installs winget packages.

    Requires Developer Mode (Settings > System > For developers) OR an elevated shell.

.PARAMETER Distro
    WSL distro name. Default: "Debian".

.PARAMETER SkipPackages
    Skip winget package installation. Useful on re-runs when packages are already present.

.NOTES
    Developer Mode (recommended — no elevation needed):
        Set-ExecutionPolicy -Scope Process Bypass -Force
        .\windows\setup-windows.ps1

    Elevated shell (alternative):
        # Open PowerShell as Administrator, then:
        Set-ExecutionPolicy -Scope Process Bypass -Force
        .\windows\setup-windows.ps1
#>
[CmdletBinding()]
param(
    [string] $Distro = "Debian",
    [switch] $SkipPackages
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# --------------------------------------------------------------------------- helpers
function Write-Step { param([string]$Msg) Write-Host "==> $Msg" -ForegroundColor Cyan }
function Write-Ok   { param([string]$Msg) Write-Host "  OK $Msg" -ForegroundColor Green }
function Write-Warn { param([string]$Msg) Write-Host "  !! $Msg" -ForegroundColor Yellow }
function Fail       { param([string]$Msg) Write-Host "  XX $Msg" -ForegroundColor Red; exit 1 }

function Test-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    (New-Object Security.Principal.WindowsPrincipal($id)).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-DeveloperMode {
    $key = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock"
    if (-not (Test-Path $key)) { return $false }
    $val = (Get-ItemProperty -Path $key -Name AllowDevelopmentWithoutDevLicense `
        -ErrorAction SilentlyContinue).AllowDevelopmentWithoutDevLicense
    return $val -eq 1
}

# Creates or replaces a SymbolicLink at $Target pointing to $Source.
# Skips if the link already exists and is correct. Warns if a real file/dir is in the way.
function Set-Symlink {
    param([string]$Target, [string]$Source)

    $item = Get-Item $Target -Force -ErrorAction SilentlyContinue
    if ($item) {
        if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
            # Normalise both sides so trailing-backslash differences don't cause false misses.
            $current = $item.Target.TrimEnd('\').TrimEnd('/')
            $want    = $Source.TrimEnd('\').TrimEnd('/')
            if ($current -eq $want) {
                Write-Ok "Already correct: $Target"
                return
            }
            Write-Warn "Replacing stale symlink: $Target"
            Write-Warn "  was: $current"
            Write-Warn "  now: $want"
            Remove-Item $Target -Force -Recurse
        } else {
            Write-Warn "$Target exists as a real file/directory — skipping. Remove it manually if you want a symlink."
            return
        }
    }

    $parent = Split-Path $Target -Parent
    if (-not (Test-Path $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    New-Item -ItemType SymbolicLink -Path $Target -Target $Source | Out-Null
    Write-Ok "Created: $Target"
    Write-Ok "     ->  $Source"
}

# --------------------------------------------------------------------------- 1. symlink capability
Write-Step "Checking symlink capability"
if (-not (Test-Admin) -and -not (Test-DeveloperMode)) {
    Fail @"
Cannot create symlinks: neither Developer Mode nor elevation is active.

  Option A (recommended): Enable Developer Mode in Settings > System > For developers,
           then re-run this script in a normal PowerShell.
  Option B: Open PowerShell as Administrator and re-run this script.
"@
}
if (Test-Admin) {
    Write-Ok "Running elevated — symlinks allowed."
} else {
    Write-Ok "Developer Mode active — symlinks allowed without elevation."
}

# --------------------------------------------------------------------------- 2. winget packages
if ($SkipPackages) {
    Write-Ok "SkipPackages set — skipping winget import."
} else {
    Write-Step "Installing winget packages from packages.winget.json"
    $manifest = Join-Path $PSScriptRoot "packages\packages.winget.json"
    if (-not (Test-Path $manifest)) {
        Write-Warn "Manifest not found at $manifest — skipping package installation."
    } elseif (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Warn "winget is not available — skipping package installation."
    } else {
        winget import --import-file $manifest `
            --accept-package-agreements `
            --accept-source-agreements `
            --ignore-versions
        Write-Ok "Winget import complete."
    }
}

# --------------------------------------------------------------------------- 3. resolve WSL home
Write-Step "Resolving WSL home in distro: $Distro"
if (-not (Get-Command wsl.exe -ErrorAction SilentlyContinue)) {
    Fail "wsl.exe not found. WSL2 is required to locate the dotfiles repo."
}

$wslHome = ""
try {
    $wslHome = (wsl.exe -d $Distro -e bash -c 'echo $HOME' | Out-String).Trim()
} catch {
    Fail "Failed to query WSL for distro '$Distro'. Is it installed? Run: wsl -l -v"
}

if ([string]::IsNullOrWhiteSpace($wslHome)) {
    Fail "Got an empty home path from distro '$Distro'."
}

# Convert /home/user -> home\user for the UNC path
$wslHomeUNC = $wslHome.TrimStart('/').Replace('/', '\')
$UNCBase = "\\wsl$\$Distro\$wslHomeUNC\dotfiles"
Write-Ok "UNC base: $UNCBase"

# --------------------------------------------------------------------------- 4. symlinks
Write-Step "Creating config symlinks"

Set-Symlink `
    -Target "$env:USERPROFILE\.gitconfig" `
    -Source "$UNCBase\git\.gitconfig"

Set-Symlink `
    -Target "$env:USERPROFILE\.gitignore" `
    -Source "$UNCBase\git\.gitignore"

Set-Symlink `
    -Target "$env:APPDATA\Zed\settings.json" `
    -Source "$UNCBase\zed\.config\zed\settings.json"

# .agents\ parent is created by Set-Symlink if absent
Set-Symlink `
    -Target "$env:USERPROFILE\.agents\skills" `
    -Source "$UNCBase\agents\.agents\skills"

# .config\ parent is created by Set-Symlink if absent
Set-Symlink `
    -Target "$env:USERPROFILE\.config\starship.toml" `
    -Source "$UNCBase\starship\starship.toml"

# --------------------------------------------------------------------------- done
Write-Step "Done"
Write-Host "  All symlinks are live. Open a new PowerShell session to pick up any config changes." -ForegroundColor White
