#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

print_step()    { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
print_error()   { printf '\033[1;31m  ✗\033[0m %s\n' "$*" >&2; }

OS_NAME="$(uname)"

case "$OS_NAME" in
    Darwin)
        print_step "Detected macOS — delegating to setup_macos.sh"
        exec bash "$DOTFILES_DIR/setup_macos.sh" "$@"
        ;;
    Linux)
        print_step "Detected Linux — delegating to setup_linux.sh"
        exec bash "$DOTFILES_DIR/setup_linux.sh" "$@"
        ;;
    *)
        print_error "Unsupported operating system: $OS_NAME"
        print_error "Supported operating systems: macOS and Debian/Ubuntu Linux"
        exit 1
        ;;
esac
