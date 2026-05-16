#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANSIBLE_DIR="$DOTFILES_DIR/ansible"
PLAYBOOK="$ANSIBLE_DIR/playbook.yml"
INVENTORY="$ANSIBLE_DIR/inventory.ini"

print_step()    { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
print_error()   { printf '\033[1;31m  ✗\033[0m %s\n' "$*" >&2; }

command_exists() { command -v "$1" >/dev/null 2>&1; }

if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
    print_error "Do not run this script with sudo."
    print_error "Run ./setup.sh as your normal user; the Ansible playbook will request sudo only for tasks that need it."
    exit 1
fi

OS_NAME="$(uname)"

case "$OS_NAME" in
    Darwin|Linux)
        ;;
    *)
        print_error "Unsupported operating system: $OS_NAME"
        print_error "Supported operating systems: macOS and Debian/Ubuntu Linux"
        exit 1
        ;;
esac

install_ansible_macos() {
    local venv_dir="$DOTFILES_DIR/.ansible-venv"
    local python_bin=""
    local venv_owner=""

    if command_exists python3; then
        python_bin="$(command -v python3)"
    else
        print_error "python3 is required to install Ansible on macOS without Homebrew."
        print_error "Install Python 3 from https://www.python.org/downloads/macos/ and rerun this script."
        exit 1
    fi

    if [[ -e "$venv_dir" && ! -w "$venv_dir" ]]; then
        venv_owner="$(stat -f '%Su' "$venv_dir" 2>/dev/null || printf 'another user')"
        print_error "$venv_dir is not writable by $(id -un). It appears to be owned by $venv_owner."
        print_error "Fix it with: sudo chown -R $(id -un):$(id -gn) $venv_dir"
        exit 1
    fi

    print_step "Installing Ansible developer tools in a local Python virtual environment"
    "$python_bin" -m venv "$venv_dir"
    "$venv_dir/bin/python" -m pip install --upgrade pip
    "$venv_dir/bin/python" -m pip install --upgrade ansible ansible-lint ansible-dev-tools
}

install_ansible_linux() {
    if [[ ! -f /etc/debian_version ]]; then
        print_error "Linux bootstrap currently supports Debian/Ubuntu only."
        exit 1
    fi

    print_step "Installing Ansible with apt"
    sudo apt-get update -y
    sudo apt-get install -y ansible
}

ANSIBLE_PLAYBOOK_BIN=""
if command_exists ansible-playbook; then
    ANSIBLE_PLAYBOOK_BIN="$(command -v ansible-playbook)"
fi

if [[ -z "$ANSIBLE_PLAYBOOK_BIN" ]]; then
    case "$OS_NAME" in
        Darwin) install_ansible_macos ;;
        Linux) install_ansible_linux ;;
    esac
fi

if command_exists ansible-playbook; then
    ANSIBLE_PLAYBOOK_BIN="$(command -v ansible-playbook)"
elif [[ -x "$DOTFILES_DIR/.ansible-venv/bin/ansible-playbook" ]]; then
    ANSIBLE_PLAYBOOK_BIN="$DOTFILES_DIR/.ansible-venv/bin/ansible-playbook"
fi

if [[ -z "$ANSIBLE_PLAYBOOK_BIN" ]]; then
    print_error "ansible-playbook was not found after bootstrap"
    exit 1
fi

print_step "Running Ansible dotfiles playbook"
exec "$ANSIBLE_PLAYBOOK_BIN" -i "$INVENTORY" "$PLAYBOOK" --ask-become-pass "$@"

