#Requires -Version 5.1
<#
.SYNOPSIS
    Complete native Windows setup for this dotfiles repository.

.DESCRIPTION
    An elevated two-stage wrapper:
      1. setup-wsl.ps1 ensures WSL2 and the requested distro exist.
      2. setup-windows.ps1 installs Windows packages and deploys Windows config.

    Use setup-wsl.ps1 or setup-windows.ps1 directly when only one stage is needed.
#>
[CmdletBinding()]
param(
    [string] $Distro = "Debian",
    [switch] $SkipWsl,
    [switch] $SkipPackages
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Test-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    (New-Object Security.Principal.WindowsPrincipal($id)).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Keep both stages in one elevated process so package installation and WSL setup have a
# predictable privilege boundary. setup-windows.ps1 is still independently self-elevating.
if (-not (Test-Admin)) {
    $launcher = if (Get-Command pwsh -ErrorAction SilentlyContinue) { "pwsh" } else { "powershell" }
    $argList = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "`"$PSCommandPath`"", "-Distro", $Distro)
    if ($SkipWsl)      { $argList += "-SkipWsl" }
    if ($SkipPackages) { $argList += "-SkipPackages" }
    $process = Start-Process -FilePath $launcher -Verb RunAs -ArgumentList $argList -Wait -PassThru
    exit $process.ExitCode
}

if (-not $SkipWsl) {
    & (Join-Path $PSScriptRoot "setup-wsl.ps1") -Distro $Distro
}

& (Join-Path $PSScriptRoot "setup-windows.ps1") -Distro $Distro -SkipPackages:$SkipPackages
