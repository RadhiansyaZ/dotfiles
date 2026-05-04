#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ─── Helpers ──────────────────────────────────────────────────────────────────

print_step()    { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
print_success() { printf '\033[1;32m  ✓\033[0m %s\n' "$*"; }
print_skip()    { printf '\033[1;33m  -\033[0m %s (skipped)\n' "$*"; }
print_warn()    { printf '\033[1;33m  !\033[0m %s\n' "$*"; }
print_error()   { printf '\033[1;31m  ✗\033[0m %s\n' "$*" >&2; }

command_exists() { command -v "$1" &>/dev/null; }

# Track what was installed vs skipped for the summary
INSTALLED=()
SKIPPED=()
WARNED=()

# ─── Task 3: macOS platform guard ─────────────────────────────────────────────

if [[ "$(uname)" != "Darwin" ]]; then
    print_error "This script only supports macOS. Detected: $(uname)"
    exit 1
fi

# ─── Task 4: Xcode Command Line Tools ─────────────────────────────────────────

print_step "Checking Xcode Command Line Tools"
if xcode-select -p &>/dev/null; then
    print_skip "Xcode Command Line Tools"
    SKIPPED+=("Xcode Command Line Tools")
else
    print_warn "Xcode Command Line Tools not found. Launching installer..."
    xcode-select --install
    print_warn "Re-run this script after the Xcode CLT installation completes."
    exit 0
fi

# ─── Task 5: Homebrew ─────────────────────────────────────────────────────────

print_step "Checking Homebrew"
if command_exists brew; then
    print_skip "Homebrew"
    SKIPPED+=("Homebrew")
else
    print_step "Installing Homebrew"
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    INSTALLED+=("Homebrew")
fi

# Always initialise Homebrew environment for this shell session
if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
else
    print_error "Homebrew was not found after installation"
    exit 1
fi

# ─── Task 6: brew bundle ──────────────────────────────────────────────────────

print_step "Running brew bundle"
brew bundle --file="$DOTFILES_DIR/Brewfile" --no-upgrade
print_success "brew bundle complete"
INSTALLED+=("brew bundle")

# ─── Task 7: Go via Homebrew ──────────────────────────────────────────────────

print_step "Checking Go"
if command_exists go; then
    print_skip "Go"
    SKIPPED+=("Go")
else
    print_step "Installing Go"
    brew install go
    INSTALLED+=("Go")
fi

# ─── Task 8: Go tools ─────────────────────────────────────────────────────────

print_step "Installing Go tools"
export PATH="$HOME/go/bin:$PATH"

GO_TOOLS_INSTALLED=()
GO_TOOLS_SKIPPED=()
GO_TOOLS_FAILED=()

while IFS= read -r line; do
    module="${line#go \"}"
    module="${module%\"}"
    binary_name="$(basename "$module")"
    # Strip major-version suffix (e.g. /v2, /v3) — the real binary is named after the parent dir
    if [[ "$binary_name" =~ ^v[0-9]+$ ]]; then
        binary_name="$(basename "$(dirname "$module")")"
    fi

    if command_exists "$binary_name"; then
        print_skip "go tool: $binary_name"
        GO_TOOLS_SKIPPED+=("$binary_name")
    else
        print_step "Installing go tool: $binary_name"
        if go install "${module}@latest"; then
            print_success "Installed $binary_name"
            GO_TOOLS_INSTALLED+=("$binary_name")
        else
            print_warn "Failed to install $binary_name — continuing"
            GO_TOOLS_FAILED+=("$binary_name")
        fi
    fi
done < <(grep --color=never '^go "' "$DOTFILES_DIR/Brewfile")

[[ ${#GO_TOOLS_INSTALLED[@]} -gt 0 ]] && INSTALLED+=("Go tools: ${GO_TOOLS_INSTALLED[*]}")
[[ ${#GO_TOOLS_SKIPPED[@]}   -gt 0 ]] && SKIPPED+=("Go tools: ${GO_TOOLS_SKIPPED[*]}")
[[ ${#GO_TOOLS_FAILED[@]}    -gt 0 ]] && WARNED+=("Go tools failed: ${GO_TOOLS_FAILED[*]}")

# ─── Task 9: Default shell → zsh ──────────────────────────────────────────────

print_step "Checking default shell"
ZSH_PATH="$(which zsh)"
if [[ "$SHELL" == "$ZSH_PATH" ]]; then
    print_skip "Default shell (already zsh)"
    SKIPPED+=("Default shell")
else
    if ! grep -qF "$ZSH_PATH" /etc/shells; then
        print_step "Adding $ZSH_PATH to /etc/shells"
        echo "$ZSH_PATH" | sudo tee -a /etc/shells >/dev/null
    fi
    print_step "Changing default shell to $ZSH_PATH"
    chsh -s "$ZSH_PATH"
    INSTALLED+=("Default shell → zsh")
fi

# ─── Task 10: Oh My Zsh ───────────────────────────────────────────────────────

print_step "Checking Oh My Zsh"
if [[ -d "$HOME/.oh-my-zsh" ]]; then
    print_skip "Oh My Zsh"
    SKIPPED+=("Oh My Zsh")
else
    print_step "Installing Oh My Zsh"
    RUNZSH=no CHSH=no /bin/bash -c \
        "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    INSTALLED+=("Oh My Zsh")
fi

# ─── Task 11: Oh My Zsh custom plugins ────────────────────────────────────────

print_step "Checking Oh My Zsh custom plugins"
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

OMZ_PLUGIN_NAMES=(zsh-autosuggestions zsh-syntax-highlighting)
OMZ_PLUGIN_URLS=(
    "https://github.com/zsh-users/zsh-autosuggestions"
    "https://github.com/zsh-users/zsh-syntax-highlighting"
)

for i in "${!OMZ_PLUGIN_NAMES[@]}"; do
    plugin="${OMZ_PLUGIN_NAMES[$i]}"
    url="${OMZ_PLUGIN_URLS[$i]}"
    plugin_dir="$ZSH_CUSTOM/plugins/$plugin"
    if [[ -d "$plugin_dir" ]]; then
        print_skip "OMZ plugin: $plugin"
        SKIPPED+=("OMZ plugin: $plugin")
    else
        print_step "Cloning OMZ plugin: $plugin"
        git clone "$url" "$plugin_dir"
        INSTALLED+=("OMZ plugin: $plugin")
    fi
done

# ─── Task 12: Remove plain-file conflicts before stowing ──────────────────────

print_step "Checking for plain-file stow conflicts"

# Build list of target files from the zsh stow package
ZSH_STOW_FILES=(
    "$HOME/.zshrc"
    "$HOME/.homebrew.zshrc"
    "$HOME/.gdt.zshrc"
)

for target in "${ZSH_STOW_FILES[@]}"; do
    if [[ -f "$target" && ! -L "$target" ]]; then
        print_step "Removing plain-file conflict: $target"
        rm "$target"
        INSTALLED+=("Removed conflict: $target")
    else
        print_skip "No plain-file conflict: $target"
        SKIPPED+=("Conflict check: $target")
    fi
done

# ─── Task 13: Stow dry-run validation ─────────────────────────────────────────

print_step "Running stow dry-run validation"

STOW_PACKAGES=(agents ghostty git gnupg nvim opencode postgresql ssh tmux zed zsh)
FAILED_PACKAGES=()
STOW_LOG="/tmp/stow-dryrun.log"
true > "$STOW_LOG"

for pkg in "${STOW_PACKAGES[@]}"; do
    if stow -nv --restow --target="$HOME" --dir="$DOTFILES_DIR" "$pkg" >>"$STOW_LOG" 2>&1; then
        print_success "Dry-run OK: $pkg"
    else
        print_error "Dry-run FAILED: $pkg"
        FAILED_PACKAGES+=("$pkg")
    fi
done

if [[ ${#FAILED_PACKAGES[@]} -gt 0 ]]; then
    print_error "Stow dry-run conflicts detected in: ${FAILED_PACKAGES[*]}"
    print_error "Resolve the conflicts listed below and re-run setup_macos.sh:"
    echo ""
    for pkg in "${FAILED_PACKAGES[@]}"; do
        printf '\033[1;31mPackage: %s\033[0m\n' "$pkg"
        grep -A5 "^stow.*$pkg\|CONFLICT\|existing target\|link_dest" "$STOW_LOG" 2>/dev/null || true
    done
    echo ""
    print_warn "Full dry-run log: $STOW_LOG"
    exit 1
fi

print_success "All packages passed dry-run"

# ─── Task 14: Stow all packages ───────────────────────────────────────────────

print_step "Stowing dotfile packages"

for pkg in "${STOW_PACKAGES[@]}"; do
    stow --target="$HOME" --restow --dir="$DOTFILES_DIR" "$pkg"
    print_success "Stowed: $pkg"
done

INSTALLED+=("Stowed packages: ${STOW_PACKAGES[*]}")

# ─── Task 15: Nerd Fonts ──────────────────────────────────────────────────────

print_step "Installing Nerd Fonts"
bash "$DOTFILES_DIR/fonts.sh"
INSTALLED+=("Nerd Fonts")

# ─── Task 16: Tmux Plugin Manager ─────────────────────────────────────────────

print_step "Bootstrapping Tmux Plugin Manager"
bash "$DOTFILES_DIR/tpm.sh"
INSTALLED+=("Tmux Plugin Manager")

# ─── Task 17: Summary ─────────────────────────────────────────────────────────

echo ""
printf '\033[1;32m════════════════════════════════════════\033[0m\n'
printf '\033[1;32m  Setup complete!\033[0m\n'
printf '\033[1;32m════════════════════════════════════════\033[0m\n'
echo ""

if [[ ${#INSTALLED[@]} -gt 0 ]]; then
    printf '\033[1;34mInstalled / updated:\033[0m\n'
    for item in "${INSTALLED[@]}"; do
        printf '  + %s\n' "$item"
    done
    echo ""
fi

if [[ ${#SKIPPED[@]} -gt 0 ]]; then
    printf '\033[1;33mSkipped (already present):\033[0m\n'
    for item in "${SKIPPED[@]}"; do
        printf '  - %s\n' "$item"
    done
    echo ""
fi

if [[ ${#WARNED[@]} -gt 0 ]]; then
    printf '\033[1;31mWarnings:\033[0m\n'
    for item in "${WARNED[@]}"; do
        printf '  ! %s\n' "$item"
    done
    echo ""
fi

printf '\033[1;34mNext steps:\033[0m\n'
printf '  1. Open a new terminal session to load the updated zsh configuration.\n'
printf '  2. PATH entries for Go (~/go/bin), NVM, and JetBrains Toolbox only\n'
printf '     take effect inside an interactive zsh session.\n'
echo ""
