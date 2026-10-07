#Requires -Version 5.1
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Assert-True([bool] $Condition, [string] $Message) {
    if (-not $Condition) { throw $Message }
}

function Assert-Equal($Actual, $Expected, [string] $Message) {
    if ($Actual -cne $Expected) { throw $Message }
}

function Assert-Log([string[]] $Actual, [string[]] $Expected) {
    Assert-Equal $Actual.Count $Expected.Count "Unexpected wrapper helper count"
    for ($index = 0; $index -lt $Expected.Count; $index++) {
        Assert-Equal $Actual[$index] $Expected[$index] "Unexpected wrapper helper or source direction"
    }
}

$repoRoot = Split-Path -Parent $PSScriptRoot
$helper = Join-Path $repoRoot "windows/sync-zed-settings.ps1"
$wrapperSource = Join-Path $repoRoot "sync-win.ps1"
$work = Join-Path ([IO.Path]::GetTempPath()) ([Guid]::NewGuid().ToString("N"))
$oldLog = $env:PRV_SYNC_FIXTURE_LOG

try {
    $source = Join-Path $work "canonical/settings.json"
    $destination = Join-Path $work "windows-local/Zed/settings.json"
    New-Item -ItemType Directory -Path (Split-Path -Parent $source) -Force | Out-Null
    New-Item -ItemType Directory -Path (Split-Path -Parent $destination) -Force | Out-Null
    $sourceText = "{`n  `"theme`": `"Dark`",`n  `"shared`": true,`n}`n"
    [IO.File]::WriteAllText($source, $sourceText, [Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText($destination, "local-before-first-sync", [Text.UTF8Encoding]::new($false))

    & $helper -Source $source -Dest $destination | Out-Null
    Assert-Equal ([IO.File]::ReadAllText($destination)) $sourceText "Canonical settings were not copied forward"
    Assert-Equal ([IO.File]::ReadAllText("$destination.bak")) "local-before-first-sync" "First destination backup was not preserved"
    Assert-Equal ([IO.File]::ReadAllText($source)) $sourceText "Sync modified its canonical source"

    $firstWrite = (Get-Item -LiteralPath $destination).LastWriteTimeUtc
    $repeatOutput = @(& $helper -Source $source -Dest $destination)
    $isStable = @($repeatOutput | Where-Object { $_ -match '^OK ' }).Count -gt 0
    Assert-True $isStable "Identical repeat sync was not stable"
    Assert-Equal (Get-Item -LiteralPath $destination).LastWriteTimeUtc $firstWrite "Identical repeat sync rewrote the destination"
    Assert-Equal ([IO.File]::ReadAllText("$destination.bak")) "local-before-first-sync" "Existing backup was overwritten"

    [IO.File]::WriteAllText($destination, "later-local-edit", [Text.UTF8Encoding]::new($false))
    & $helper -Source $source -Dest $destination | Out-Null
    Assert-Equal ([IO.File]::ReadAllText($destination)) $sourceText "Changed destination did not return to canonical content"
    Assert-Equal ([IO.File]::ReadAllText("$destination.bak")) "local-before-first-sync" "Later sync replaced the first backup"
    Assert-Equal ([IO.File]::ReadAllText($source)) $sourceText "Sync modified its canonical source"

    $wrapperRoot = Join-Path $work "wrapper"
    $mockDir = Join-Path $wrapperRoot "windows"
    New-Item -ItemType Directory -Path $mockDir -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $wrapperRoot "zed/.config/zed") -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $wrapperRoot "pi/.pi/agent") -Force | Out-Null
    Copy-Item -LiteralPath $wrapperSource -Destination (Join-Path $wrapperRoot "sync-win.ps1")
    $log = Join-Path $work "wrapper.log"
    $env:PRV_SYNC_FIXTURE_LOG = $log
    Set-Content -LiteralPath (Join-Path $mockDir "sync-zed-settings.ps1") -NoNewline -Value @'
param([string] $Source)
Add-Content -LiteralPath $env:PRV_SYNC_FIXTURE_LOG -Value ("zed|" + $Source)
'@
    Set-Content -LiteralPath (Join-Path $mockDir "sync-pi-settings.ps1") -NoNewline -Value @'
param([string] $SourceDir)
Add-Content -LiteralPath $env:PRV_SYNC_FIXTURE_LOG -Value ("pi|" + $SourceDir)
'@
    $wrapper = Join-Path $wrapperRoot "sync-win.ps1"
    $expectedZed = "zed|" + (Join-Path $wrapperRoot "zed/.config/zed/settings.json")
    $expectedPi = "pi|" + (Join-Path $wrapperRoot "pi/.pi/agent")

    Remove-Item -LiteralPath $log -ErrorAction SilentlyContinue
    & $wrapper -SourceRoot $wrapperRoot
    Assert-Log ([IO.File]::ReadAllLines($log)) @($expectedZed, $expectedPi)

    Remove-Item -LiteralPath $log
    & $wrapper -SourceRoot $wrapperRoot -SkipPi
    Assert-Log ([IO.File]::ReadAllLines($log)) @($expectedZed)

    Remove-Item -LiteralPath $log
    & $wrapper -SourceRoot $wrapperRoot -SkipZed
    Assert-Log ([IO.File]::ReadAllLines($log)) @($expectedPi)

    Write-Output "Windows sync fixtures passed"
}
finally {
    if ($null -eq $oldLog) { Remove-Item Env:PRV_SYNC_FIXTURE_LOG -ErrorAction SilentlyContinue }
    else { $env:PRV_SYNC_FIXTURE_LOG = $oldLog }
    Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue
}
