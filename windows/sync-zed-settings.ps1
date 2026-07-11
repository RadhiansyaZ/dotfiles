#Requires -Version 5.1
<#
.SYNOPSIS
    Sync the Zed settings file from the WSL dotfiles repo to a real local copy on Windows.

.DESCRIPTION
    Zed on Windows cannot open its settings.json from the command palette ("zed: open
    settings") when that file is a SYMLINK pointing at a \\wsl.localhost UNC target — the
    action silently fails. So instead of symlinking (the approach used for every other
    Windows config in this repo), Zed gets a genuine local copy in %APPDATA%\Zed that this
    script re-syncs from the canonical settings.json in the WSL repo.

    First run over a pre-existing real settings.json (the file Zed created, or a leftover
    from the old symlink approach) backs it up to settings.json.bak. An existing .bak is
    never overwritten. Idempotent: if the destination already matches the source by content,
    nothing is written and it reports OK.

    Re-run this whenever the repo's Zed settings change (or wire it into the ansible Windows
    play, which does exactly that).

.PARAMETER Source
    Path to the canonical settings.json in the WSL repo, reached over the \\wsl.localhost
    share. By default it is derived from this script's repository location. Override it when needed, e.g.
        -Source "\\wsl.localhost\Ubuntu\home\me\dotfiles\zed\.config\zed\settings.json"

.PARAMETER Dest
    Destination on the Windows host. Defaults to %APPDATA%\Zed\settings.json.

.EXAMPLE
    .\sync-zed-settings.ps1

.EXAMPLE
    .\sync-zed-settings.ps1 -Source "\\wsl.localhost\Debian\home\me\dotfiles\zed\.config\zed\settings.json"
#>
[CmdletBinding()]
param(
    [string] $Source = (Join-Path (Split-Path -Parent $PSScriptRoot) "zed\.config\zed\settings.json"),
    [string] $Dest   = (Join-Path $env:APPDATA "Zed\settings.json")
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $Source)) {
    Write-Error "Source not found: $Source (is the WSL distro running and the repo present?)"
    exit 1
}

# Ensure the destination directory exists (e.g. a fresh machine without Zed launched yet).
$destDir = Split-Path -Parent $Dest
if (-not (Test-Path -LiteralPath $destDir)) {
    New-Item -ItemType Directory -Path $destDir -Force | Out-Null
}

# Drop a leftover symlink from the old approach so we write a real file in its place.
if (Test-Path -LiteralPath $Dest) {
    $item = Get-Item -LiteralPath $Dest -Force
    if ($item.LinkType -eq "SymbolicLink") { Remove-Item -LiteralPath $Dest -Force }
}

# Back up a pre-existing real file once; never clobber an existing backup.
$bak = "$Dest.bak"
if ((Test-Path -LiteralPath $Dest) -and -not (Test-Path -LiteralPath $bak)) {
    Copy-Item -LiteralPath $Dest -Destination $bak -Force
    Write-Output "BACKUP -> $bak"
}

# Copy only when content differs, so re-runs are idempotent and report accurately.
$needsCopy = $true
if (Test-Path -LiteralPath $Dest) {
    $srcHash  = (Get-FileHash -LiteralPath $Source -Algorithm SHA256).Hash
    $destHash = (Get-FileHash -LiteralPath $Dest   -Algorithm SHA256).Hash
    if ($srcHash -eq $destHash) { $needsCopy = $false }
}

if ($needsCopy) {
    Copy-Item -LiteralPath $Source -Destination $Dest -Force
    Write-Output "CHANGED $Dest"
} else {
    Write-Output "OK $Dest"
}
