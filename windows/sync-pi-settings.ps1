#Requires -Version 5.1
<#
.SYNOPSIS
    Sync the Pi coding agent config from the WSL dotfiles repo to real local copies on Windows.

.DESCRIPTION
    Pi actively writes its own settings.json (version bumps via lastChangelogVersion, `pi install`
    edits to the packages array). A symlink pointing at a \\wsl.localhost UNC target is the same
    fragile pattern that broke Zed's settings UI, so Pi gets genuine local copies instead of
    symlinks — this script re-syncs them from the canonical files in the WSL repo.

    Only settings.json and mcp.json are synced. auth.json (secrets), sessions\, npm\, git\ and
    bin\*.exe stay machine-local and are never touched. Pi rebuilds npm\ and git\ from the
    packages list on its next run.

    First run over a pre-existing real file backs it up to <file>.bak (an existing .bak is never
    overwritten). Idempotent: files matching the source by content are left alone. One-way:
    WSL repo -> %USERPROFILE%\.pi\agent.

    Re-run this whenever the repo's Pi config changes. `setup-windows.ps1` invokes the root
    `sync-win.ps1` wrapper automatically; from an interactive shell, the Sync-PiSettings function
    in the PowerShell profile is the convenient entry point.

.PARAMETER SourceDir
    Directory holding the canonical Pi config in the WSL repo, reached over the \\wsl.localhost
    share. By default it is derived from this script's repository location. Override it when needed.

.PARAMETER DestDir
    Destination directory on the Windows host. Defaults to %USERPROFILE%\.pi\agent.

.EXAMPLE
    .\sync-pi-settings.ps1

.EXAMPLE
    .\sync-pi-settings.ps1 -SourceDir "\\wsl.localhost\Ubuntu\home\me\dotfiles\pi\.pi\agent"
#>
[CmdletBinding()]
param(
    [string] $SourceDir = (Join-Path (Split-Path -Parent $PSScriptRoot) "pi\.pi\agent"),
    [string] $DestDir   = (Join-Path $env:USERPROFILE ".pi\agent")
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $SourceDir)) {
    Write-Error "Source not found: $SourceDir (is the WSL distro running and the repo present?)"
    exit 1
}

# Ensure the destination directory exists (e.g. a fresh machine without Pi launched yet).
if (-not (Test-Path -LiteralPath $DestDir)) {
    New-Item -ItemType Directory -Path $DestDir -Force | Out-Null
}

# Only these two files are shared. Everything else in .pi\agent stays machine-local.
$files = @("settings.json", "mcp.json")

foreach ($name in $files) {
    $source = Join-Path $SourceDir $name
    $dest   = Join-Path $DestDir   $name

    if (-not (Test-Path -LiteralPath $source)) {
        Write-Output "SKIP-missing-src $name"
        continue
    }

    # Drop a leftover symlink from the old approach so we write a real file in its place.
    if (Test-Path -LiteralPath $dest) {
        $item = Get-Item -LiteralPath $dest -Force
        if ($item.LinkType -eq "SymbolicLink") { Remove-Item -LiteralPath $dest -Force }
    }

    # Back up a pre-existing real file once; never clobber an existing backup.
    $bak = "$dest.bak"
    if ((Test-Path -LiteralPath $dest) -and -not (Test-Path -LiteralPath $bak)) {
        Copy-Item -LiteralPath $dest -Destination $bak -Force
        Write-Output "BACKUP -> $bak"
    }

    # Copy only when content differs, so re-runs are idempotent and report accurately.
    $needsCopy = $true
    if (Test-Path -LiteralPath $dest) {
        $srcHash  = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
        $destHash = (Get-FileHash -LiteralPath $dest   -Algorithm SHA256).Hash
        if ($srcHash -eq $destHash) { $needsCopy = $false }
    }

    if ($needsCopy) {
        Copy-Item -LiteralPath $source -Destination $dest -Force
        Write-Output "CHANGED $dest"
    } else {
        Write-Output "OK $dest"
    }
}
