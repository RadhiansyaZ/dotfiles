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

# ─── Task 2: Linux/Debian platform guard ──────────────────────────────────────

if [[ "$(uname)" != "Linux" ]]; then
    print_error "This script only supports Linux. Detected: $(uname)"
    exit 1
fi

if [[ ! -f /etc/debian_version ]]; then
    print_warn "Could not find /etc/debian_version — this script targets Debian/Ubuntu."
    print_warn "Continuing anyway, but package names may differ."
fi

# Warn if not on Debian 12 (bookworm)
if command_exists lsb_release; then
    DISTRO_CODENAME="$(lsb_release -cs 2>/dev/null || true)"
    if [[ -n "$DISTRO_CODENAME" && "$DISTRO_CODENAME" != "bookworm" && "$DISTRO_CODENAME" != "noble" && "$DISTRO_CODENAME" != "jammy" ]]; then
        print_warn "Detected distro codename: $DISTRO_CODENAME. Package names are tested on Debian bookworm."
    fi
fi

# ─── Task 3: Architecture detection ──────────────────────────────────────────

MACHINE_ARCH="$(uname -m)"
case "$MACHINE_ARCH" in
    x86_64)
        ARCH="amd64"
        GOARCH="amd64"
        ARCH_AWS="x86_64"
        ;;
    aarch64|arm64)
        ARCH="arm64"
        GOARCH="arm64"
        ARCH_AWS="aarch64"
        ;;
    *)
        print_error "Unsupported architecture: $MACHINE_ARCH. Only x86_64 and aarch64 are supported."
        exit 1
        ;;
esac

print_success "Architecture: $MACHINE_ARCH → ARCH=$ARCH, GOARCH=$GOARCH"

# ─── Task 4: apt update and base dependencies ─────────────────────────────────

print_step "Updating apt and installing base dependencies"
sudo apt-get update -y
sudo apt-get install -y --no-install-recommends \
    curl \
    wget \
    unzip \
    xz-utils \
    gpg \
    ca-certificates \
    software-properties-common \
    build-essential \
    fontconfig
print_success "Base apt dependencies installed"
INSTALLED+=("apt base dependencies")

# Ensure ~/.local/bin exists and is on PATH early (pip, zoxide, uv, pnpm land here)
mkdir -p "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$PATH"

# ─── Task 5: Install zsh via apt ──────────────────────────────────────────────

print_step "Checking zsh"
if command_exists zsh; then
    print_skip "zsh"
    SKIPPED+=("zsh")
else
    print_step "Installing zsh"
    sudo apt-get install -y zsh
    print_success "zsh installed"
    INSTALLED+=("zsh")
fi

# ─── Task 6: Set zsh as default shell ────────────────────────────────────────

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

# ─── Task 7: Install apt CLI tools ────────────────────────────────────────────

print_step "Installing apt CLI tools"

APT_PACKAGES=(
    # Shell/CLI
    stow tmux bat ripgrep fd-find fzf jq tree htop
    # Database
    libpq-dev pgformatter sqitch libdbd-pg-perl
    # Security
    pass git-crypt
    # Python
    python3 python3-pip
    # Media
    mpv
)

# Install all at once for efficiency; skip only if every package is already installed
ALL_PRESENT=true
for pkg in stow tmux ripgrep fzf jq pass git-crypt python3 mpv; do
    if ! command_exists "$pkg" && ! dpkg -l "$pkg" &>/dev/null 2>&1; then
        ALL_PRESENT=false
        break
    fi
done

if $ALL_PRESENT; then
    print_skip "apt CLI tools (already installed)"
    SKIPPED+=("apt CLI tools")
else
    sudo apt-get install -y "${APT_PACKAGES[@]}"
    print_success "apt CLI tools installed"
    INSTALLED+=("apt CLI tools")
fi

# ─── Task 8: Create bat and fd symlinks ───────────────────────────────────────

print_step "Checking bat symlink (batcat → bat)"
BATCAT_PATH="$(command -v batcat 2>/dev/null || true)"
if [[ -n "$BATCAT_PATH" ]]; then
    if [[ -L "$HOME/.local/bin/bat" ]]; then
        print_skip "bat symlink"
        SKIPPED+=("bat symlink")
    else
        ln -sf "$BATCAT_PATH" "$HOME/.local/bin/bat"
        print_success "Created ~/.local/bin/bat → $BATCAT_PATH"
        INSTALLED+=("bat symlink")
    fi
else
    print_warn "batcat not found; skipping bat symlink"
    WARNED+=("batcat not found; bat symlink not created")
fi

print_step "Checking fd symlink (fdfind → fd)"
FDFIND_PATH="$(command -v fdfind 2>/dev/null || true)"
if [[ -n "$FDFIND_PATH" ]]; then
    if [[ -L "$HOME/.local/bin/fd" ]]; then
        print_skip "fd symlink"
        SKIPPED+=("fd symlink")
    else
        ln -sf "$FDFIND_PATH" "$HOME/.local/bin/fd"
        print_success "Created ~/.local/bin/fd → $FDFIND_PATH"
        INSTALLED+=("fd symlink")
    fi
else
    print_warn "fdfind not found; skipping fd symlink"
    WARNED+=("fdfind not found; fd symlink not created")
fi

# ─── Task 9: Install gh CLI (official apt repo) ───────────────────────────────

print_step "Checking gh CLI"
if command_exists gh; then
    print_skip "gh CLI"
    SKIPPED+=("gh CLI")
else
    print_step "Installing gh CLI via official apt repo"
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        | sudo gpg --dearmor -o /etc/apt/keyrings/githubcli-archive-keyring.gpg
    sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
    sudo apt-get update -y
    sudo apt-get install -y gh
    print_success "gh CLI installed"
    INSTALLED+=("gh CLI")
fi

# ─── Task 10: Install eza (official Debian repo) ──────────────────────────────

print_step "Checking eza"
if command_exists eza; then
    print_skip "eza"
    SKIPPED+=("eza")
else
    print_step "Installing eza via gierens apt repo"
    sudo mkdir -p /etc/apt/keyrings
    wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc \
        | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
    echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" \
        | sudo tee /etc/apt/sources.list.d/gierens.list >/dev/null
    sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
    sudo apt-get update -y
    sudo apt-get install -y eza
    print_success "eza installed"
    INSTALLED+=("eza")
fi

# ─── Task 11: Install Neovim (GitHub binary release) ─────────────────────────

print_step "Checking Neovim"
if [[ -x /opt/nvim/bin/nvim && -L /usr/local/bin/nvim && "$(readlink /usr/local/bin/nvim 2>/dev/null || true)" == "/opt/nvim/bin/nvim" ]]; then
    print_skip "Neovim"
    SKIPPED+=("Neovim")
else
    print_step "Installing Neovim from GitHub release"
    NVIM_TMP="$(mktemp -d)"
    NVIM_TARBALL="nvim-linux-${ARCH}.tar.gz"
    NVIM_URL="https://github.com/neovim/neovim/releases/latest/download/${NVIM_TARBALL}"

    if curl -fsSL -o "$NVIM_TMP/$NVIM_TARBALL" "$NVIM_URL"; then
        sudo rm -rf /opt/nvim
        sudo mkdir -p /opt/nvim
        sudo tar -xzf "$NVIM_TMP/$NVIM_TARBALL" -C /opt/nvim --strip-components=1
        sudo ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim
        print_success "Neovim installed to /opt/nvim"
        INSTALLED+=("Neovim")
    else
        print_warn "Failed to download Neovim from $NVIM_URL — skipping"
        WARNED+=("Neovim download failed")
    fi
    rm -rf "$NVIM_TMP"
fi

# ─── Task 12: Install Go (official tarball) ───────────────────────────────────

print_step "Checking Go"
if command_exists go; then
    print_skip "Go"
    SKIPPED+=("Go")
else
    print_step "Installing Go from official tarball"
    GO_VERSION="$(curl -fsSL https://go.dev/VERSION?m=text | head -1 || echo "go1.23.0")"
    GO_VERSION="${GO_VERSION#go}"  # strip leading "go"
    GO_TARBALL="go${GO_VERSION}.linux-${GOARCH}.tar.gz"
    GO_URL="https://go.dev/dl/${GO_TARBALL}"
    GO_TMP="$(mktemp -d)"

    if curl -fsSL -o "$GO_TMP/$GO_TARBALL" "$GO_URL"; then
        sudo rm -rf /usr/local/go
        sudo tar -C /usr/local -xzf "$GO_TMP/$GO_TARBALL"
        print_success "Go ${GO_VERSION} installed to /usr/local/go"
        INSTALLED+=("Go ${GO_VERSION}")
    else
        print_warn "Failed to download Go from $GO_URL — skipping"
        WARNED+=("Go download failed")
    fi
    rm -rf "$GO_TMP"
fi

# Ensure Go binaries are available for the rest of this session
export PATH="/usr/local/go/bin:$HOME/go/bin:$PATH"

# ─── Task 13: Install Go tools ────────────────────────────────────────────────

print_step "Installing Go tools"

GO_TOOLS_INSTALLED=()
GO_TOOLS_SKIPPED=()
GO_TOOLS_FAILED=()

while IFS= read -r line; do
    module="${line#go \"}"
    module="${module%\"}"
    binary_name="$(basename "$module")"
    # Strip major-version suffix (e.g. /v2, /v3)
    if [[ "$binary_name" =~ ^v[0-9]+$ ]]; then
        binary_name="$(basename "$(dirname "$module")")"
    fi

    if command_exists "$binary_name"; then
        print_skip "go tool: $binary_name"
        GO_TOOLS_SKIPPED+=("$binary_name")
    else
        print_step "Installing go tool: $binary_name"
        if go install "${module}@latest" 2>/dev/null; then
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

# ─── Task 14: Install starship (curl installer) ───────────────────────────────

print_step "Checking starship"
if command_exists starship; then
    print_skip "starship"
    SKIPPED+=("starship")
else
    print_step "Installing starship"
    curl -sS https://starship.rs/install.sh | sudo sh -s -- --yes
    print_success "starship installed"
    INSTALLED+=("starship")
fi

# ─── Task 15: Install zoxide (curl installer) ────────────────────────────────

print_step "Checking zoxide"
if command_exists zoxide; then
    print_skip "zoxide"
    SKIPPED+=("zoxide")
else
    print_step "Installing zoxide"
    curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
    print_success "zoxide installed"
    INSTALLED+=("zoxide")
fi

# ─── Task 16: Install nvm (curl installer) ────────────────────────────────────

print_step "Checking nvm"
NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
if [[ -d "$NVM_DIR" ]]; then
    print_skip "nvm"
    SKIPPED+=("nvm")
else
    print_step "Installing nvm"
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/HEAD/install.sh | bash
    print_success "nvm installed"
    INSTALLED+=("nvm")
fi

# Source nvm for the remainder of this session
if [[ -s "$NVM_DIR/nvm.sh" ]]; then
    # shellcheck disable=SC1091
    . "$NVM_DIR/nvm.sh"
fi

# ─── Task 17: Install pnpm (curl installer) ───────────────────────────────────

print_step "Checking pnpm"
if command_exists pnpm; then
    print_skip "pnpm"
    SKIPPED+=("pnpm")
else
    print_step "Installing pnpm"
    curl -fsSL https://get.pnpm.io/install.sh | sh -
    print_success "pnpm installed"
    INSTALLED+=("pnpm")
fi

# Export PNPM_HOME so pnpm is available in the current session
PNPM_HOME="${PNPM_HOME:-$HOME/.local/share/pnpm}"
export PATH="$PNPM_HOME:$PATH"

# ─── Task 18: Install uv (curl installer) ────────────────────────────────────

print_step "Checking uv"
if command_exists uv; then
    print_skip "uv"
    SKIPPED+=("uv")
else
    print_step "Installing uv"
    curl -LsSf https://astral.sh/uv/install.sh | sh
    print_success "uv installed"
    INSTALLED+=("uv")
fi

# ─── Task 19: Install AWS CLI v2 ─────────────────────────────────────────────

print_step "Checking AWS CLI"
if command_exists aws; then
    print_skip "AWS CLI"
    SKIPPED+=("AWS CLI")
else
    print_step "Installing AWS CLI v2"
    AWS_TMP="$(mktemp -d)"
    AWS_ZIP="awscliv2.zip"
    AWS_URL="https://awscli.amazonaws.com/awscli-exe-linux-${ARCH_AWS}.zip"

    if curl -fsSL -o "$AWS_TMP/$AWS_ZIP" "$AWS_URL"; then
        unzip -q "$AWS_TMP/$AWS_ZIP" -d "$AWS_TMP"
        sudo "$AWS_TMP/aws/install"
        print_success "AWS CLI v2 installed"
        INSTALLED+=("AWS CLI v2")
    else
        print_warn "Failed to download AWS CLI from $AWS_URL — skipping"
        WARNED+=("AWS CLI download failed")
    fi
    rm -rf "$AWS_TMP"
fi

# ─── Task 20: Install GitHub binary tools ─────────────────────────────────────

# Helper: download, extract (if needed), and install a binary from a GitHub release.
# Usage: install_github_binary <binary_name> <download_url> [binary_in_archive]
# If binary_in_archive is omitted, the download_url is assumed to be a single binary.
install_github_binary() {
    local binary="$1"
    local url="$2"
    local binary_in_archive="${3:-}"
    local tmp_dir
    tmp_dir="$(mktemp -d)"
    local filename
    filename="$(basename "$url")"
    local filepath="$tmp_dir/$filename"

    print_step "Installing $binary"
    if ! curl -fsSL -o "$filepath" "$url"; then
        print_warn "Failed to download $binary from $url — skipping"
        WARNED+=("$binary download failed")
        rm -rf "$tmp_dir"
        return 0
    fi

    if [[ "$filename" == *.tar.gz || "$filename" == *.tgz ]]; then
        tar -xzf "$filepath" -C "$tmp_dir"
        if [[ -n "$binary_in_archive" ]]; then
            local extracted_bin="$tmp_dir/$binary_in_archive"
        else
            local extracted_bin="$tmp_dir/$binary"
        fi
        if [[ ! -f "$extracted_bin" ]]; then
            # Try searching one level deep
            extracted_bin="$(find "$tmp_dir" -maxdepth 2 -type f -name "$binary" | head -1 || true)"
        fi
        if [[ -n "$extracted_bin" && -f "$extracted_bin" ]]; then
            sudo install -m 0755 "$extracted_bin" "/usr/local/bin/$binary"
            print_success "$binary installed to /usr/local/bin/$binary"
            INSTALLED+=("$binary")
        else
            print_warn "Could not locate $binary binary in archive — skipping"
            WARNED+=("$binary binary not found in archive")
        fi
    elif [[ "$filename" == *.zip ]]; then
        unzip -q "$filepath" -d "$tmp_dir"
        local extracted_bin
        extracted_bin="$(find "$tmp_dir" -maxdepth 2 -type f -name "$binary" | head -1 || true)"
        if [[ -n "$extracted_bin" && -f "$extracted_bin" ]]; then
            sudo install -m 0755 "$extracted_bin" "/usr/local/bin/$binary"
            print_success "$binary installed to /usr/local/bin/$binary"
            INSTALLED+=("$binary")
        else
            print_warn "Could not locate $binary binary in zip — skipping"
            WARNED+=("$binary binary not found in zip")
        fi
    else
        # Single binary
        sudo install -m 0755 "$filepath" "/usr/local/bin/$binary"
        print_success "$binary installed to /usr/local/bin/$binary"
        INSTALLED+=("$binary")
    fi

    rm -rf "$tmp_dir"
}

# Fetch the latest release download URL for a given GitHub repo and asset pattern
# Usage: get_github_release_url <owner/repo> <asset_pattern>
get_github_release_url() {
    local repo="$1"
    local pattern="$2"
    curl -fsSL "https://api.github.com/repos/${repo}/releases/latest" \
        | grep '"browser_download_url"' \
        | grep -E "$pattern" \
        | head -1 \
        | sed 's/.*"browser_download_url": "\(.*\)"/\1/' \
        | tr -d '"'
}

print_step "Installing GitHub binary tools"

# lazygit
if command_exists lazygit; then
    print_skip "lazygit"; SKIPPED+=("lazygit")
else
    URL="$(get_github_release_url "jesseduffield/lazygit" "lazygit_.*_Linux_${ARCH}\.tar\.gz")"
    if [[ -n "$URL" ]]; then
        install_github_binary "lazygit" "$URL"
    else
        print_warn "Could not resolve lazygit download URL — skipping"
        WARNED+=("lazygit URL resolution failed")
    fi
fi

# lazysql
if command_exists lazysql; then
    print_skip "lazysql"; SKIPPED+=("lazysql")
else
    URL="$(get_github_release_url "jorgerojas26/lazysql" "lazysql_linux_${ARCH}\.tar\.gz")"
    if [[ -n "$URL" ]]; then
        install_github_binary "lazysql" "$URL"
    else
        print_warn "Could not resolve lazysql download URL — skipping"
        WARNED+=("lazysql URL resolution failed")
    fi
fi

# act
if command_exists act; then
    print_skip "act"; SKIPPED+=("act")
else
    URL="$(get_github_release_url "nektos/act" "act_Linux_${ARCH}\.tar\.gz")"
    if [[ -n "$URL" ]]; then
        install_github_binary "act" "$URL"
    else
        print_warn "Could not resolve act download URL — skipping"
        WARNED+=("act URL resolution failed")
    fi
fi

# actionlint
if command_exists actionlint; then
    print_skip "actionlint"; SKIPPED+=("actionlint")
else
    URL="$(get_github_release_url "rhysd/actionlint" "actionlint_.*_linux_${ARCH}\.tar\.gz")"
    if [[ -n "$URL" ]]; then
        install_github_binary "actionlint" "$URL"
    else
        print_warn "Could not resolve actionlint download URL — skipping"
        WARNED+=("actionlint URL resolution failed")
    fi
fi

# dbmate (single binary, no archive)
if command_exists dbmate; then
    print_skip "dbmate"; SKIPPED+=("dbmate")
else
    URL="https://github.com/amacneil/dbmate/releases/latest/download/dbmate-linux-${ARCH}"
    install_github_binary "dbmate" "$URL"
fi

# htmlq (only x86_64 assets are published; skip gracefully on arm64)
if command_exists htmlq; then
    print_skip "htmlq"; SKIPPED+=("htmlq")
elif [[ "$ARCH" == "amd64" ]]; then
    URL="$(get_github_release_url "mgdm/htmlq" "htmlq-x86_64-linux\.tar\.gz")"
    if [[ -n "$URL" ]]; then
        install_github_binary "htmlq" "$URL"
    else
        print_warn "Could not resolve htmlq download URL — skipping"
        WARNED+=("htmlq URL resolution failed")
    fi
else
    print_warn "htmlq does not publish arm64 Linux releases — skipping"
    WARNED+=("htmlq: no arm64 release available")
fi

# saml2aws
if command_exists saml2aws; then
    print_skip "saml2aws"; SKIPPED+=("saml2aws")
elif [[ "$ARCH" == "amd64" ]]; then
    URL="$(get_github_release_url "Versent/saml2aws" "saml2aws_.*_linux_${ARCH}\.tar\.gz")"
    if [[ -n "$URL" ]]; then
        install_github_binary "saml2aws" "$URL"
    else
        print_warn "Could not resolve saml2aws download URL — skipping"
        WARNED+=("saml2aws URL resolution failed")
    fi
else
    print_warn "saml2aws: skipping on non-amd64 architecture"
    WARNED+=("saml2aws: skipped on $ARCH")
fi

# opencode
if command_exists opencode; then
    print_skip "opencode"; SKIPPED+=("opencode")
else
    # opencode releases assets as "opencode-linux-<arch>" single binaries
    URL="https://github.com/sst/opencode/releases/latest/download/opencode-linux-${ARCH}"
    install_github_binary "opencode" "$URL"
fi

# ─── Task 21: Install pre-commit (pip) ───────────────────────────────────────

print_step "Checking pre-commit"
if command_exists pre-commit; then
    print_skip "pre-commit"
    SKIPPED+=("pre-commit")
else
    print_step "Installing pre-commit via pip"
    pip3 install --user pre-commit
    print_success "pre-commit installed"
    INSTALLED+=("pre-commit")
fi

# ─── Task 22: Oh My Zsh ───────────────────────────────────────────────────────

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

# ─── Task 23: Oh My Zsh custom plugins ───────────────────────────────────────

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

# ─── Task 24: Remove plain-file stow conflicts ───────────────────────────────

print_step "Checking for plain-file stow conflicts"

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

# ─── Task 25: Stow dry-run validation ────────────────────────────────────────

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
    print_error "Resolve the conflicts listed below and re-run setup_linux.sh:"
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

# ─── Task 26: Stow all packages ──────────────────────────────────────────────

print_step "Stowing dotfile packages"

for pkg in "${STOW_PACKAGES[@]}"; do
    stow --target="$HOME" --restow --dir="$DOTFILES_DIR" "$pkg"
    print_success "Stowed: $pkg"
done

INSTALLED+=("Stowed packages: ${STOW_PACKAGES[*]}")

# ─── Task 27: Nerd Fonts ─────────────────────────────────────────────────────

print_step "Installing Nerd Fonts"
bash "$DOTFILES_DIR/fonts.sh"
INSTALLED+=("Nerd Fonts")

# ─── Task 28: Tmux Plugin Manager ────────────────────────────────────────────

print_step "Bootstrapping Tmux Plugin Manager"
bash "$DOTFILES_DIR/tpm.sh"
INSTALLED+=("Tmux Plugin Manager")

# ─── Task 29: Summary ────────────────────────────────────────────────────────

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
printf '  1. Open a new terminal session — zsh becomes the default shell on next login.\n'
printf '  2. PATH entries for Go (~/go/bin), NVM (~/.nvm), pnpm, uv, and zoxide\n'
printf '     only take full effect inside an interactive zsh session.\n'
printf '  3. If tmux plugins were not auto-installed, open tmux and press prefix + I.\n'
echo ""
