#!/usr/bin/env bash
# Imports SSH keys from the Windows user profile into the WSL ~/.ssh directory.
# Safe to re-run: skips files that are already present and identical.
set -euo pipefail

print_step()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
print_ok()    { printf '\033[1;32m  ✓\033[0m %s\n' "$*"; }
print_warn()  { printf '\033[1;33m  !\033[0m %s\n' "$*" >&2; }
print_error() { printf '\033[1;31m  ✗\033[0m %s\n' "$*" >&2; }

# --------------------------------------------------------------------------- 1. env check
if [[ "$(uname -r)" != *microsoft* ]]; then
    print_error "This script is intended for WSL only."
    exit 1
fi

if ! command -v cmd.exe >/dev/null 2>&1; then
    print_error "cmd.exe not found. This script must be run inside WSL."
    exit 1
fi

# --------------------------------------------------------------------------- 2. Windows username
print_step "Detecting Windows username"
WIN_USER="$(cmd.exe /c 'echo %USERNAME%' 2>/dev/null | tr -d '\r\n')"
if [[ -z "$WIN_USER" ]]; then
    print_error "Could not determine Windows username from %USERNAME%."
    exit 1
fi
print_ok "Windows user: $WIN_USER"

# --------------------------------------------------------------------------- 3. validate source
print_step "Validating Windows SSH directory"
if ! mountpoint -q /mnt/c 2>/dev/null && [[ ! -d /mnt/c ]]; then
    print_error "/mnt/c is not mounted. Ensure the Windows filesystem is accessible."
    exit 1
fi

WIN_SSH="/mnt/c/Users/$WIN_USER/.ssh"
if [[ ! -d "$WIN_SSH" ]]; then
    print_warn "Windows .ssh directory not found: $WIN_SSH"
    print_warn "Create SSH keys on the Windows side first, then re-run this script."
    exit 1
fi
print_ok "Source: $WIN_SSH"

# --------------------------------------------------------------------------- 4. prepare destination
WSL_SSH="$HOME/.ssh"
mkdir -p "$WSL_SSH"
chmod 700 "$WSL_SSH"

# --------------------------------------------------------------------------- 5. copy files
print_step "Copying SSH keys to $WSL_SSH"

copied=0
skipped=0

copy_if_changed() {
    local src="$1"
    local name
    name="$(basename "$src")"
    local dst="$WSL_SSH/$name"

    if [[ -f "$dst" ]]; then
        if [[ "$(md5sum "$src" | cut -d' ' -f1)" == "$(md5sum "$dst" | cut -d' ' -f1)" ]]; then
            print_ok "Unchanged: $name"
            ((skipped += 1)) || true
            return
        fi
        print_warn "Updating:  $name"
    else
        print_ok "Copying:   $name"
    fi
    cp "$src" "$dst"
    ((copied += 1)) || true
}

# Private keys (id_* excluding *.pub)
while IFS= read -r -d '' f; do
    copy_if_changed "$f"
done < <(find "$WIN_SSH" -maxdepth 1 -name 'id_*' ! -name '*.pub' -print0 2>/dev/null)

# Public keys
while IFS= read -r -d '' f; do
    copy_if_changed "$f"
done < <(find "$WIN_SSH" -maxdepth 1 -name '*.pub' -print0 2>/dev/null)

# known_hosts (exclude config — WSL SSH config comes from the dotfiles stow package)
if [[ -f "$WIN_SSH/known_hosts" ]]; then
    copy_if_changed "$WIN_SSH/known_hosts"
fi

# --------------------------------------------------------------------------- 6. permissions
print_step "Setting permissions"

while IFS= read -r -d '' f; do
    chmod 600 "$f"
done < <(find "$WSL_SSH" -maxdepth 1 -name 'id_*' ! -name '*.pub' -print0 2>/dev/null)

while IFS= read -r -d '' f; do
    chmod 644 "$f"
done < <(find "$WSL_SSH" -maxdepth 1 -name '*.pub' -print0 2>/dev/null)

[[ -f "$WSL_SSH/known_hosts" ]] && chmod 600 "$WSL_SSH/known_hosts"

print_ok "Permissions set."

# --------------------------------------------------------------------------- done
print_step "Done"
printf '  %d file(s) copied, %d unchanged.\n' "$copied" "$skipped"
