#Requires -Version 5.1
<#
.SYNOPSIS
    Native Windows bootstrap for the dotfiles repo.

.DESCRIPTION
    Thin bootstrap only. The heavy provisioning (winget packages, config symlinks, the
    PowerShell profile, fonts, language runtimes) is performed by Ansible running inside
    WSL — see PLAN.md. This script prepares the machine so that hand-off can happen:

      1. Require an elevated session.
      2. Enable Developer Mode (lets symlinks be created later without elevation).
      3. Install WSL2 + Debian (to match the existing WSL/Linux environment).
      4. Install + enable the Windows OpenSSH Server and set PowerShell as its default shell
         (Ansible's Windows modules run over SSH against the local Windows host).
      5. Generate an SSH key inside WSL and authorize it on the Windows host.
      6. Add a firewall allow-rule for inbound SSH (needed under WSL2 NAT networking).
      7. Detect WSL2 mirrored networking and resolve the Windows host address.
      8. Hand off to ./setup.sh inside WSL (which bootstraps Ansible and runs the playbook).

.NOTES
    Run from an ELEVATED PowerShell:
        Set-ExecutionPolicy -Scope Process Bypass -Force
        .\setup.ps1

    Re-runnable: every step is idempotent and safe to run again.
#>
[CmdletBinding()]
param(
    [string] $Distro = "Debian",
    [switch] $SkipWsl,
    [switch] $SkipHandoff
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# --------------------------------------------------------------------------- helpers
function Write-Step { param([string]$Msg) Write-Host "==> $Msg" -ForegroundColor Cyan }
function Write-Ok   { param([string]$Msg) Write-Host "  OK $Msg" -ForegroundColor Green }
function Write-Warn { param([string]$Msg) Write-Host "  !! $Msg" -ForegroundColor Yellow }
function Write-Err  { param([string]$Msg) Write-Host "  XX $Msg" -ForegroundColor Red }

function Test-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    (New-Object Security.Principal.WindowsPrincipal($id)).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)
}

$RepoWin = $PSScriptRoot

# --------------------------------------------------------------------------- 1. admin
if (-not (Test-Admin)) {
    Write-Err "This script must be run from an elevated PowerShell."
    Write-Err "Right-click PowerShell > Run as Administrator, then re-run .\setup.ps1"
    exit 1
}
Write-Ok "Running elevated."

# --------------------------------------------------------------------------- 2. dev mode
function Enable-DeveloperMode {
    Write-Step "Enabling Developer Mode (for symlink creation without elevation)"
    $key = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock"
    if (-not (Test-Path $key)) { New-Item -Path $key -Force | Out-Null }
    Set-ItemProperty -Path $key -Name AllowDevelopmentWithoutDevLicense -Value 1 -Type DWord
    Write-Ok "Developer Mode enabled."
}

# --------------------------------------------------------------------------- 3. WSL2 + distro
function Test-DistroInstalled {
    param([string]$Name)
    # wsl -l -q emits UTF-16; normalise and strip nulls before matching.
    $list = (wsl.exe -l -q) -replace "`0", ""
    return ($list -split "`r?`n" | ForEach-Object { $_.Trim() }) -contains $Name
}

function Install-Wsl {
    param([string]$Name)
    Write-Step "Ensuring WSL2 + $Name"

    if (-not (Get-Command wsl.exe -ErrorAction SilentlyContinue)) {
        Write-Warn "WSL is not installed. Installing the WSL platform (a reboot may be required)."
        wsl.exe --install --no-distribution
        Write-Warn "If WSL was just installed, REBOOT Windows and re-run .\setup.ps1"
    }

    wsl.exe --set-default-version 2 | Out-Null

    if (Test-DistroInstalled -Name $Name) {
        Write-Ok "$Name already installed."
    } else {
        Write-Step "Installing $Name (this may prompt to create a UNIX user)"
        wsl.exe --install -d $Name
        if (-not (Test-DistroInstalled -Name $Name)) {
            Write-Warn "$Name install may need a reboot or first-run user setup."
            Write-Warn "Complete it, then re-run .\setup.ps1"
            exit 1
        }
    }
    Write-Ok "$Name ready."
}

# --------------------------------------------------------------------------- 4. OpenSSH server
function Install-OpenSSHServer {
    Write-Step "Installing + enabling the Windows OpenSSH Server"

    # PowerShell 7 is the primary shell for this script. The DISM cmdlets
    # (Get-/Add-WindowsCapability) ship in a Windows PowerShell module whose COM classes are
    # not registered for PowerShell 7 — calling them directly throws "Class not registered"
    # (0x80040154). Load the module through the Windows PowerShell compatibility layer so the
    # cmdlets run first-class from pwsh 7. (Under Windows PowerShell 5.1 this is a no-op.)
    if ($PSVersionTable.PSEdition -eq 'Core') {
        Remove-Module DISM -ErrorAction SilentlyContinue
        Import-Module DISM -UseWindowsPowerShell -WarningAction SilentlyContinue
    }

    $cap = Get-WindowsCapability -Online -Name "OpenSSH.Server*"
    if ("$($cap.State)" -ne "Installed") {
        Add-WindowsCapability -Online -Name "OpenSSH.Server~~~~0.0.1.0" | Out-Null
    }

    Set-Service -Name sshd -StartupType Automatic
    Start-Service sshd

    # Ansible's Windows modules need a PowerShell login shell over SSH (prefer pwsh 7).
    $pwshCmd = Get-Command pwsh.exe -ErrorAction SilentlyContinue
    if ($pwshCmd) { $shell = $pwshCmd.Source }
    else { $shell = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" }
    $sshRegKey = "HKLM:\SOFTWARE\OpenSSH"
    if (-not (Test-Path $sshRegKey)) { New-Item -Path $sshRegKey -Force | Out-Null }
    New-ItemProperty -Path $sshRegKey -Name DefaultShell `
        -Value $shell -PropertyType String -Force | Out-Null
    Write-Ok "sshd running; default SSH shell = $shell"
}

# --------------------------------------------------------------------------- 5. SSH key auth
function Set-AuthorizedKey {
    param([string]$PublicKey)
    if ([string]::IsNullOrWhiteSpace($PublicKey)) {
        Write-Warn "No public key produced from WSL; skipping authorized_keys setup."
        return
    }
    # Admin users authenticate via administrators_authorized_keys with locked-down ACLs.
    $akFile = "$env:ProgramData\ssh\administrators_authorized_keys"
    if (Test-Path $akFile) { $existing = Get-Content $akFile -Raw } else { $existing = "" }
    if ($existing -notmatch [regex]::Escape($PublicKey.Trim())) {
        Add-Content -Path $akFile -Value $PublicKey
    }
    # Required ACL: owners Administrators + SYSTEM, inheritance disabled.
    icacls $akFile /inheritance:r /grant "Administrators:F" "SYSTEM:F" | Out-Null
    Write-Ok "Authorized WSL public key for SSH into Windows."
}

# --------------------------------------------------------------------------- 6. firewall
function Add-SshFirewallRule {
    Write-Step "Ensuring inbound SSH firewall rule (for WSL2 NAT networking)"
    if (-not (Get-NetFirewallRule -Name "OpenSSH-Server-WSL" -ErrorAction SilentlyContinue)) {
        New-NetFirewallRule -Name "OpenSSH-Server-WSL" `
            -DisplayName "OpenSSH SSH Server (WSL bootstrap)" `
            -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22 | Out-Null
    }
    Write-Ok "Firewall allows inbound TCP/22."
}

# --------------------------------------------------------------------------- 7. host address
function Resolve-WindowsHost {
    # Mirrored networking (Win11 22H2+) => WSL reaches Windows on localhost.
    $wslconfig = Join-Path $env:USERPROFILE ".wslconfig"
    if ((Test-Path $wslconfig) -and ((Get-Content $wslconfig -Raw) -match "networkingMode\s*=\s*mirrored")) {
        Write-Ok "WSL mirrored networking detected -> host = 127.0.0.1"
        return "127.0.0.1"
    }
    # NAT mode: the Windows host is the WSL default gateway. Use cut (not awk) so there is
    # no '$' to escape across the PowerShell -> wsl -> sh quoting boundary.
    $gw = (wsl.exe -d $Distro -- sh -c "ip route show default 2>/dev/null | head -n1 | cut -d' ' -f3").Trim()
    if ($gw) {
        Write-Ok "WSL NAT networking -> host = $gw (default gateway)"
        return $gw
    }
    Write-Warn "Could not resolve Windows host address; defaulting to 127.0.0.1"
    return "127.0.0.1"
}

# --------------------------------------------------------------------------- run
Enable-DeveloperMode
Install-OpenSSHServer
Add-SshFirewallRule

if (-not $SkipWsl) {
    Install-Wsl -Name $Distro

    # Bare distro images may lack openssh-client (no ssh-keygen / ssh). Ensure it exists —
    # Ansible's WSL->Windows SSH transport needs it too. Idempotent: skips if already present.
    Write-Step "Ensuring openssh-client is installed in $Distro"
    wsl.exe -d $Distro -u root -- sh -c "command -v ssh-keygen >/dev/null 2>&1 || { apt-get update -y && apt-get install -y openssh-client; }" | Out-Null

    Write-Step "Generating SSH key inside WSL (if absent) and reading its public key"
    # Escape `$HOME with a backtick so PowerShell passes it literally to sh. A plain \$HOME
    # would be expanded by PowerShell to the *Windows* home path before sh ever sees it.
    $keygenCmd = "mkdir -p `$HOME/.ssh; test -f `$HOME/.ssh/id_ed25519.pub || ssh-keygen -t ed25519 -N '' -f `$HOME/.ssh/id_ed25519 -q; cat `$HOME/.ssh/id_ed25519.pub"
    $pubKey = (wsl.exe -d $Distro -- sh -c $keygenCmd | Out-String).Trim()
    Set-AuthorizedKey -PublicKey $pubKey
}

$winHost = Resolve-WindowsHost
$winUser = $env:USERNAME
# wslpath fails if backslashes are stripped crossing the PS->wsl boundary; feed it a
# forward-slash Windows path (wslpath accepts both) so the conversion is reliable.
$repoWinFwd = $RepoWin -replace '\\', '/'
$repoWsl = (wsl.exe -d $Distro -- wslpath -u "$repoWinFwd" | Out-String).Trim()

Write-Step "Bootstrap summary"
Write-Host "  Windows host : $winHost"
Write-Host "  Windows user : $winUser"
Write-Host "  Repo (Win)   : $RepoWin"
Write-Host "  Repo (WSL)   : $repoWsl"

# --------------------------------------------------------------------------- 8. hand off
if ($SkipHandoff) {
    Write-Warn "SkipHandoff set; not invoking setup.sh. Run it manually inside WSL:"
    Write-Host "  wsl -d $Distro -- env DOTFILES_WIN_HOST=$winHost DOTFILES_WIN_USER=$winUser DOTFILES_WIN_DIR='$RepoWin' bash '$repoWsl/setup.sh'"
    exit 0
}

Write-Step "Handing off to setup.sh inside WSL ($Distro)"
wsl.exe -d $Distro -- env `
    DOTFILES_WIN_HOST="$winHost" `
    DOTFILES_WIN_USER="$winUser" `
    DOTFILES_WIN_DIR="$RepoWin" `
    bash "$repoWsl/setup.sh"

Write-Ok "Bootstrap complete. Open a new PowerShell to load the profile."
