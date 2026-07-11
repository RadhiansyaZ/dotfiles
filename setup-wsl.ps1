#Requires -Version 5.1
<#
.SYNOPSIS
    Ensure WSL2 and a Linux distro are available for the dotfiles setup.

.DESCRIPTION
    This is the WSL-only first stage of setup.ps1. It deliberately does not provision
    Windows packages, OpenSSH, or Ansible: setup-windows.ps1 owns native Windows setup,
    while setup.sh owns provisioning inside Linux/WSL.
#>
[CmdletBinding()]
param(
    [string] $Distro = "Debian"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Test-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    (New-Object Security.Principal.WindowsPrincipal($id)).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-DistroInstalled {
    param([string] $Name)
    # wsl -l -q can emit UTF-16/nulls; normalize before matching.
    $list = (wsl.exe -l -q) -replace "`0", ""
    return ($list -split "`r?`n" | ForEach-Object { $_.Trim() }) -contains $Name
}

if (-not (Test-Admin)) {
    throw "Run setup-wsl.ps1 from an elevated PowerShell, or use .\setup.ps1."
}

if (-not (Get-Command wsl.exe -ErrorAction SilentlyContinue)) {
    Write-Host "==> Installing the WSL platform" -ForegroundColor Cyan
    wsl.exe --install --no-distribution
    Write-Warning "WSL was installed. Reboot Windows, then re-run .\setup.ps1."
    exit 1
}

Write-Host "==> Ensuring WSL2 + $Distro" -ForegroundColor Cyan
wsl.exe --set-default-version 2 | Out-Null

if (-not (Test-DistroInstalled -Name $Distro)) {
    wsl.exe --install -d $Distro
    if (-not (Test-DistroInstalled -Name $Distro)) {
        Write-Warning "Complete the $Distro first-run user setup (and reboot if requested), then re-run .\setup.ps1."
        exit 1
    }
}

Write-Host "  OK $Distro is ready." -ForegroundColor Green
