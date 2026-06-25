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
    git branch | Where-Object { $_ -notmatch '^\*|\bmaster\b|\bmain\b' } |
        ForEach-Object { git branch -D $_.Trim() }
}

# Clipboard helpers (Set-Clipboard is built in on Windows).
function shrug        { $t = '¯\_(ツ)_/¯';        Write-Host $t; $t | Set-Clipboard }
function flip         { $t = '（╯°□°）╯ ┻━┻';       Write-Host $t; $t | Set-Clipboard }
function disappointed { $t = ' ಠ_ಠ ';             Write-Host $t; $t | Set-Clipboard }

# JSON-escape stdin (parity with jqsanitize).
function jqsanitize { $input | jq -R . | jq -s . | jq -r 'join("")' }

# ---------------------------------------------------------------------------
# Tool initialisation (all guarded so a missing tool never breaks the shell)
# ---------------------------------------------------------------------------
if (Get-Command starship -ErrorAction SilentlyContinue) {
    Invoke-Expression (& starship init powershell)
}
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { (zoxide init powershell --cmd cd | Out-String) })
}
if (Get-Module -ListAvailable -Name PSFzf) {
    Import-Module PSFzf
    Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
}
