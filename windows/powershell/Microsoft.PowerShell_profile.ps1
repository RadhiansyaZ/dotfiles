# PowerShell profile — native Windows. Mirrors zsh/.zshrc.
# Deployed (symlinked) to: $HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1
# Keep this idempotent and fast: it runs on every shell start.

# ---------------------------------------------------------------------------
# History + line editing (PSReadLine replaces zsh-autosuggestions / -syntax-highlighting)
# ---------------------------------------------------------------------------
if (Get-Module -ListAvailable -Name PSReadLine) {
    Import-Module PSReadLine
    Set-PSReadLineOption -EditMode Emacs
    Set-PSReadLineOption -HistoryNoDuplicates
    Set-PSReadLineOption -HistorySearchCursorMovesToEnd
    # Inline + list autosuggestions from history (and plugins when available).
    try { Set-PSReadLineOption -PredictionSource HistoryAndPlugin } catch { Set-PSReadLineOption -PredictionSource History }
    try { Set-PSReadLineOption -PredictionViewStyle ListView } catch {}
}

# ---------------------------------------------------------------------------
# PATH (parity with .zshrc: ~/.local/bin and ~/go/bin)
# ---------------------------------------------------------------------------
$localBin = Join-Path $HOME ".local\bin"
if (Test-Path $localBin) { $env:PATH = "$localBin;$env:PATH" }
$goBin = Join-Path $HOME "go\bin"
if (Test-Path $goBin) { $env:PATH = "$env:PATH;$goBin" }

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

# ---------------------------------------------------------------------------
# Tool initialisation (all guarded so a missing tool never breaks the shell)
# ---------------------------------------------------------------------------
if (Get-Command starship -ErrorAction SilentlyContinue) {
    # Config is symlinked from WSL dotfiles via setup-windows-symlinks.ps1.
    $env:STARSHIP_CONFIG = Join-Path $HOME ".config\starship.toml"
    Invoke-Expression (& starship init powershell)
}
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { (zoxide init powershell --cmd cd | Out-String) })
}
# PSFzf's Import-Module throws if the fzf binary is missing, so require both.
if ((Get-Command fzf -ErrorAction SilentlyContinue) -and (Get-Module -ListAvailable -Name PSFzf)) {
    Import-Module PSFzf
    Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
}
