#Requires -Version 5.1
<#
.SYNOPSIS
    Standalone native Windows setup: winget packages + dotfiles symlinks.

.DESCRIPTION
    Installs winget packages and creates Windows config symlinks from this repository.
    It works whether the repository is opened through a WSL UNC path or from a Windows clone.

    The script self-elevates: if not already running as Administrator it re-launches itself
    via UAC, forwarding its parameters. Admin is required because machine-scoped MSI packages
    (e.g. Starship.Starship) cannot install otherwise.

.PARAMETER Distro
    WSL distro name retained for compatibility with existing invocations. It is not otherwise needed.

.PARAMETER SkipPackages
    Skip winget package installation. Useful on re-runs when packages are already present.

.NOTES
    Run from any PowerShell session (it elevates itself):
        Set-ExecutionPolicy -Scope Process Bypass -Force
        .\setup-windows.ps1

    Approve the UAC prompt when it appears. An elevated window opens and stays open (-NoExit)
    so you can read the package install and tool-verification output.
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

# Reload PATH from the registry into the current session. winget drops shims into
# %LOCALAPPDATA%\Microsoft\WinGet\Links, but the running shell's $env:PATH is a stale
# snapshot — without this, tools installed this run aren't resolvable until a new shell.
function Update-SessionPath {
    $machine = [Environment]::GetEnvironmentVariable("Path", "Machine")
    $user    = [Environment]::GetEnvironmentVariable("Path", "User")
    $env:PATH = (@($machine, $user) | Where-Object { $_ }) -join ';'
}

# --------------------------------------------------------------------------- 0. self-elevate
# Machine-scoped MSI packages (e.g. Starship.Starship) require admin. Re-launch elevated if
# we aren't already, forwarding the original parameters, so the whole run is reproducible.
if (-not (Test-Admin)) {
    Write-Step "Re-launching elevated (required for machine-scoped MSI packages)"
    $launcher = if (Get-Command pwsh -ErrorAction SilentlyContinue) { "pwsh" } else { "powershell" }
    $argList  = @("-NoExit", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "`"$PSCommandPath`"")
    if ($Distro)       { $argList += @("-Distro", $Distro) }
    if ($SkipPackages) { $argList += "-SkipPackages" }
    try {
        Start-Process -FilePath $launcher -Verb RunAs -ArgumentList $argList -ErrorAction Stop
    } catch {
        Fail "Elevation declined. Approve the UAC prompt, or re-run from an Administrator PowerShell."
    }
    exit
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
    $manifest = Join-Path $PSScriptRoot "windows\packages\packages.winget.json"
    if (-not (Test-Path $manifest)) {
        Write-Warn "Manifest not found at $manifest — skipping package installation."
    } elseif (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Warn "winget is not available — skipping package installation."
    } else {
        if (-not (Test-Admin)) {
            Write-Warn "Not elevated: machine-scoped MSI packages (e.g. Starship.Starship) will trigger a UAC"
            Write-Warn "prompt and won't install if it's declined. The verify step below reports what's missing."
        }
        winget import --import-file $manifest `
            --accept-package-agreements `
            --accept-source-agreements `
            --ignore-versions
        Update-SessionPath
        Write-Ok "Winget import complete; PATH refreshed for this session."
    }
}

# --------------------------------------------------------------------------- 3. repository source
# PSScriptRoot is the canonical source for all links/copies. It may be a \\wsl$ UNC
# path when the repo lives in WSL, or a normal Windows path when it is cloned locally.
$RepoRoot = $PSScriptRoot
Write-Ok "Repository source: $RepoRoot"

# --------------------------------------------------------------------------- 4. symlinks
Write-Step "Creating config symlinks"

Set-Symlink `
    -Target "$env:USERPROFILE\.gitconfig" `
    -Source "$RepoRoot\git\.gitconfig"

Set-Symlink `
    -Target "$env:USERPROFILE\.gitignore" `
    -Source "$RepoRoot\git\.gitignore"

# PowerShell 7 profile — without this the starship/zoxide/alias init never runs.
# Documents\PowerShell\ parent is created by Set-Symlink if absent.
Set-Symlink `
    -Target "$env:USERPROFILE\Documents\PowerShell\Microsoft.PowerShell_profile.ps1" `
    -Source "$RepoRoot\windows\powershell\Microsoft.PowerShell_profile.ps1"

# psmux reads this config from the Windows user profile.
Set-Symlink `
    -Target "$env:USERPROFILE\.psmux.conf" `
    -Source "$RepoRoot\psmux\.psmux.conf"

# .agents\ parent is created by Set-Symlink if absent
Set-Symlink `
    -Target "$env:USERPROFILE\.agents\skills" `
    -Source "$RepoRoot\agents\.agents\skills"

# .config\ parent is created by Set-Symlink if absent
Set-Symlink `
    -Target "$env:USERPROFILE\.config\starship.toml" `
    -Source "$RepoRoot\starship\starship.toml"

# WezTerm reads $HOME\.config\wezterm\wezterm.lua on Windows (HOME = %USERPROFILE%).
# .config\wezterm\ parent is created by Set-Symlink if absent.
Set-Symlink `
    -Target "$env:USERPROFILE\.config\wezterm\wezterm.lua" `
    -Source "$RepoRoot\wezterm\.config\wezterm\wezterm.lua"

# Pi and Zed settings are deliberately copied rather than symlinked: both applications write
# their settings, and Zed cannot open a UNC-backed symlink from its command palette.
& (Join-Path $RepoRoot "sync-win.ps1") -SourceRoot $RepoRoot

# --------------------------------------------------------------------------- 4b. psmux plugins
# PPM is psmux's TPM-equivalent plugin manager. The linked config loads it from this location
# and uses it to install the declared plugins on the first Prefix + I.
Write-Step "Installing psmux Plugin Manager"
$ppmDir = Join-Path $env:USERPROFILE ".psmux\plugins\ppm"
$ppmEntry = Join-Path $ppmDir "ppm.ps1"
if (Test-Path $ppmEntry) {
    Write-Ok "Already installed: psmux Plugin Manager"
} elseif (Get-Command git -ErrorAction SilentlyContinue) {
    $ppmTemp = Join-Path ([IO.Path]::GetTempPath()) "psmux-plugins-$([guid]::NewGuid())"
    try {
        git clone --depth 1 "https://github.com/psmux/psmux-plugins.git" $ppmTemp 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-Warn "Failed to clone psmux plugins — run setup again after resolving the Git error."
        } else {
            New-Item -ItemType Directory -Path (Split-Path $ppmDir -Parent) -Force | Out-Null
            if (Test-Path $ppmDir) { Remove-Item $ppmDir -Recurse -Force }
            Copy-Item (Join-Path $ppmTemp "ppm") $ppmDir -Recurse -Force
            Write-Ok "Installed: psmux Plugin Manager"
        }
    } finally {
        if (Test-Path $ppmTemp) { Remove-Item $ppmTemp -Recurse -Force }
    }
} else {
    Write-Warn "git not on PATH — skipping psmux Plugin Manager install. Re-run after git is installed."
}

# --------------------------------------------------------------------------- 4c. wezterm plugins
# WezTerm's bundled libgit2 cannot clone plugins on Windows (it fails with "unsupported URL
# protocol; class=Net"), so the wezterm.plugin.require() calls in wezterm.lua would error on
# every launch and flash empty windows. Pre-clone the plugin tree with the system git; wezterm
# reuses an existing plugin directory instead of cloning it itself.
Write-Step "Installing WezTerm plugins"

# Reproduces wezterm's URL -> on-disk directory name escaping (lua-api-crates/plugin):
# '/' and '\' -> sZs, ':' -> sCs, '.' -> sDs; [A-Za-z0-9_-] pass through unchanged.
function Get-WeztermPluginDir {
    param([string]$Url)
    $sb = [System.Text.StringBuilder]::new()
    foreach ($c in $Url.ToCharArray()) {
        switch -Regex ($c) {
            '[/\\]'         { [void]$sb.Append('sZs'); break }
            ':'             { [void]$sb.Append('sCs'); break }
            '\.'            { [void]$sb.Append('sDs'); break }
            '[A-Za-z0-9_-]' { [void]$sb.Append($c);   break }
            default         { [void]$sb.Append(('u{0}' -f [int][char]$c)); break }
        }
    }
    $sb.ToString()
}

# Clones $Url into wezterm's plugins directory under its escaped name, unless already present.
function Install-WeztermPlugin {
    param([string]$Url, [string]$PluginsRoot)
    $dir  = Join-Path $PluginsRoot (Get-WeztermPluginDir $Url)
    $init = Join-Path $dir "plugin\init.lua"
    if (Test-Path $init) { Write-Ok "Already installed: $Url"; return }
    if (Test-Path $dir)  { Remove-Item $dir -Recurse -Force }
    git clone --depth 1 $Url $dir 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0 -and (Test-Path $init)) {
        Write-Ok "Cloned: $Url"
    } else {
        Write-Warn "Failed to clone $Url — resurrect.wezterm will not load until this succeeds."
    }
}

if (Get-Command git -ErrorAction SilentlyContinue) {
    $pluginsRoot = Join-Path $env:APPDATA "wezterm\plugins"
    if (-not (Test-Path $pluginsRoot)) { New-Item -ItemType Directory -Path $pluginsRoot -Force | Out-Null }
    # resurrect.wezterm plus its dependency dev.wezterm (required by resurrect's init.lua).
    Install-WeztermPlugin -Url "https://github.com/MLFlexer/resurrect.wezterm" -PluginsRoot $pluginsRoot
    Install-WeztermPlugin -Url "https://github.com/chrisgve/dev.wezterm"       -PluginsRoot $pluginsRoot
} else {
    Write-Warn "git not on PATH — skipping WezTerm plugin install. Re-run after git is installed."
}

# --------------------------------------------------------------------------- 5. verify tools
Write-Step "Verifying shell tools are on PATH"
Update-SessionPath
$critical = @("starship", "fzf", "zoxide", "git", "nvim", "eza", "bat", "psmux")
$missing = @()
foreach ($tool in $critical) {
    if (Get-Command $tool -ErrorAction SilentlyContinue) {
        Write-Ok $tool
    } else {
        Write-Warn "$tool not found on PATH"
        $missing += $tool
    }
}
if ($missing.Count -gt 0) {
    Write-Warn "Missing: $($missing -join ', ')."
    Write-Warn "Re-run without -SkipPackages to install them, then open a new PowerShell session."
}

# --------------------------------------------------------------------------- done
Write-Step "Done"
Write-Host "  All symlinks are live. Open a new PowerShell session to pick up any config changes." -ForegroundColor White
