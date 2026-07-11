#Requires -Version 5.1
<#
.SYNOPSIS
    Sync all Windows-local copies from the canonical dotfiles repository.

.DESCRIPTION
    Runs every copy-based Windows sync in windows/. Symlinked configuration does not need
    syncing. Pi and Zed settings are copied because those applications write their settings
    and cannot reliably use a UNC-backed symlink.

    Invoke this script through the repository's WSL UNC path when WSL is canonical, for example:
      & "\\wsl$\Debian\home\me\dotfiles\sync-win.ps1"
#>
[CmdletBinding()]
param(
    [string] $SourceRoot = $PSScriptRoot,
    [switch] $SkipPi,
    [switch] $SkipZed
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $SourceRoot)) {
    throw "Dotfiles source root not found: $SourceRoot"
}

$SourceRoot = (Resolve-Path -LiteralPath $SourceRoot).Path
$syncDir = Join-Path $PSScriptRoot "windows"

if (-not $SkipZed) {
    & (Join-Path $syncDir "sync-zed-settings.ps1") `
        -Source (Join-Path $SourceRoot "zed\.config\zed\settings.json")
}

if (-not $SkipPi) {
    & (Join-Path $syncDir "sync-pi-settings.ps1") `
        -SourceDir (Join-Path $SourceRoot "pi\.pi\agent")
}
