# PowerShell profile — native Windows. Mirrors zsh/.zshrc.
# Deployed (symlinked) to: $HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1
# Keep this idempotent and fast: it runs on every shell start.

# ---------------------------------------------------------------------------
# History + line editing (PSReadLine replaces zsh-autosuggestions / -syntax-highlighting)
# PS7 autoloads PSReadLine; only import if it isn't already loaded (avoids a
# Get-Module -ListAvailable filesystem scan on every start).
# ---------------------------------------------------------------------------
if (-not (Get-Module PSReadLine)) { Import-Module PSReadLine -ErrorAction SilentlyContinue }
if (Get-Module PSReadLine) {
    Set-PSReadLineOption -EditMode Emacs
    Set-PSReadLineOption -HistoryNoDuplicates
    Set-PSReadLineOption -HistorySearchCursorMovesToEnd
    # Inline + list autosuggestions from history (and plugins when available).
    try { Set-PSReadLineOption -PredictionSource HistoryAndPlugin } catch { try { Set-PSReadLineOption -PredictionSource History } catch {} }
    try { Set-PSReadLineOption -PredictionViewStyle ListView } catch {}
}

# ---------------------------------------------------------------------------
# PATH (parity with .zshrc: ~/.local/bin and ~/go/bin)
# Guarded so re-sourcing the profile (. $PROFILE) doesn't keep growing PATH.
# ---------------------------------------------------------------------------
$localBin = Join-Path $HOME ".local\bin"
if ((Test-Path $localBin) -and ($env:PATH -notlike "*$localBin*")) { $env:PATH = "$localBin;$env:PATH" }
$goBin = Join-Path $HOME "go\bin"
if ((Test-Path $goBin) -and ($env:PATH -notlike "*$goBin*")) { $env:PATH = "$env:PATH;$goBin" }

# ---------------------------------------------------------------------------
# EDITOR — prefer zed, fall back to nvim (mirrors the intent of .zshrc but guarded)
# ---------------------------------------------------------------------------
if (Get-Command zed -ErrorAction SilentlyContinue) {
    $env:EDITOR = "zed --wait"
} elseif (Get-Command nvim -ErrorAction SilentlyContinue) {
    $env:EDITOR = "nvim"
}

# ---------------------------------------------------------------------------
# Aliases / functions (parity with .zshrc CLI aliases)
# ---------------------------------------------------------------------------
if (Get-Command bat -ErrorAction SilentlyContinue) {
    function cat { bat --style=plain @args }
}
if (Get-Command eza -ErrorAction SilentlyContinue) {
    Remove-Item Alias:ls -ErrorAction SilentlyContinue
    function ls { eza @args }
}

# Delete every local branch except the current one / master / main.
function gcleanup {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) { return }
    git branch | Where-Object { $_ -notmatch '^\*|\bmaster\b|\bmain\b' } |
        ForEach-Object { git branch -D $_.Trim() }
}

# Interactive git log browser with fzf preview (parity with .zshrc gdiff).
# Uses fzf {1} token — strip ANSI codes automatically — so no --graph.
function gdiff {
    if (-not (Get-Command fzf -ErrorAction SilentlyContinue)) { return }
    $entry = git log --color=always --format="%C(auto)%h%d %s %C(black)%C(bold)%cr" @args |
        fzf --ansi --no-sort --reverse --preview "git show --color=always {1}"
    if ($entry) {
        $hash = [regex]::Match($entry, '[a-f0-9]{7,40}').Value
        if ($hash) { git show --color=always $hash | less -R }
    }
}

# Clipboard helpers (Set-Clipboard is built in on Windows).
function shrug        { $t = '¯\_(ツ)_/¯';        Write-Host $t; $t | Set-Clipboard }
function flip         { $t = '（╯°□°）╯ ┻━┻';       Write-Host $t; $t | Set-Clipboard }
function disappointed { $t = ' ಠ_ಠ ';             Write-Host $t; $t | Set-Clipboard }

# Measure curl request timings (parity with .zshrc curltime).
function curltime {
    curl -o /dev/null -s -w "Establish Connection: %{time_connect}s`nTTFB: %{time_starttransfer}s`nTotal: %{time_total}s`n" @args
}

# JSON-escape stdin (parity with jqsanitize).
function jqsanitize {
    if (-not (Get-Command jq -ErrorAction SilentlyContinue)) { return }
    $input | jq -R . | jq -s . | jq -r 'join("")'
}

# Re-sync Zed's settings from the WSL dotfiles repo. Zed can't use a symlinked settings.json
# (its "open settings" palette action breaks on a \\wsl.localhost symlink), so it gets a real
# local copy that windows/sync-zed-settings.ps1 refreshes. One-way: WSL repo -> %APPDATA%\Zed.
# Run this after changing the repo's Zed settings. Pass-through args override -Source / -Dest.
function Sync-ZedSettings {
    $syncScript = "\\wsl.localhost\Debian\home\RadhiansyaPutra\dotfiles\windows\sync-zed-settings.ps1"
    if (-not (Test-Path -LiteralPath $syncScript)) {
        Write-Warning "Zed sync script not reachable: $syncScript (is the WSL distro running?)"
        return
    }
    & $syncScript @args
}

# ---------------------------------------------------------------------------
# Cached tool initialisation
# `starship init` / `zoxide init` print a deterministic script that only
# changes when the binary is upgraded. Spawning those processes on every shell
# start (plus Defender scanning them cold) is the dominant startup cost, so we
# cache the generated script to disk and regenerate only when the binary is
# newer than the cache. Run `Reset-ShellCache` if a cache ever goes stale.
# ---------------------------------------------------------------------------
$script:ShellCacheDir = Join-Path $HOME ".cache\pwsh-init"

function Invoke-CachedInit {
    param(
        [Parameter(Mandatory)][string]$Tool,
        [Parameter(Mandatory)][scriptblock]$Generate
    )
    $cmd = Get-Command $Tool -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $cmd) { return }

    $cacheFile = Join-Path $script:ShellCacheDir "$Tool.ps1"
    $binTime   = (Get-Item -LiteralPath $cmd.Source).LastWriteTimeUtc
    $fresh     = (Test-Path -LiteralPath $cacheFile) -and
                 ((Get-Item -LiteralPath $cacheFile).LastWriteTimeUtc -ge $binTime)

    if (-not $fresh) {
        if (-not (Test-Path -LiteralPath $script:ShellCacheDir)) {
            New-Item -ItemType Directory -Force -Path $script:ShellCacheDir | Out-Null
        }
        (& $Generate | Out-String) | Set-Content -LiteralPath $cacheFile -Encoding UTF8
    }
    . $cacheFile
}

# Wipe the init cache so the next shell (or `. $PROFILE`) regenerates it.
function Reset-ShellCache {
    if (Test-Path -LiteralPath $script:ShellCacheDir) {
        Remove-Item -LiteralPath $script:ShellCacheDir -Recurse -Force
        Write-Host "Cleared shell init cache: $script:ShellCacheDir"
    } else {
        Write-Host "No shell init cache to clear ($script:ShellCacheDir)."
    }
    Write-Host "Open a new shell or run '. `$PROFILE' to regenerate."
}

# starship reads STARSHIP_CONFIG at prompt-render time (not baked into the init
# script), so caching the init output is safe regardless of starship.toml.
# Config is symlinked from WSL dotfiles via setup-windows-symlinks.ps1.
$env:STARSHIP_CONFIG = Join-Path $HOME ".config\starship.toml"
Invoke-CachedInit -Tool starship -Generate { & starship init powershell }
Invoke-CachedInit -Tool zoxide   -Generate { & zoxide init powershell --cmd cd }

# ---------------------------------------------------------------------------
# PSFzf — lazy loaded. Importing it costs ~270ms, so defer until the first
# Ctrl+t / Ctrl+r press. The first press imports the module and calls
# Set-PsFzfOption, which rebinds these chords to PSFzf's own handlers; later
# presses hit PSFzf directly.
# ---------------------------------------------------------------------------
if ((Get-Command fzf -ErrorAction SilentlyContinue) -and (Get-Module PSReadLine)) {
    $script:PSFzfLoaded = $false
    function Import-PSFzfLazy {
        if ($script:PSFzfLoaded) { return $true }
        if (-not (Get-Module -ListAvailable -Name PSFzf)) { return $false }
        Import-Module PSFzf
        Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
        $script:PSFzfLoaded = $true
        return $true
    }
    Set-PSReadLineKeyHandler -Chord 'Ctrl+t' -ScriptBlock {
        if (Import-PSFzfLazy) { Invoke-FzfPsReadlineHandlerProvider }
    }
    Set-PSReadLineKeyHandler -Chord 'Ctrl+r' -ScriptBlock {
        if (Import-PSFzfLazy) { Invoke-FzfPsReadlineHandlerHistory }
    }
}
