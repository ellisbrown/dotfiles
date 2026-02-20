#!/bin/bash
#
# setup.sh — Full setup for a new machine
#
# Usage:
#   git clone https://github.com/ellisbrown/dotfiles.git ~/dotfiles
#   bash ~/dotfiles/setup.sh
#
# On macOS: installs Homebrew (if missing), runs brew bundle, then install.sh
# On Linux: runs install.sh directly

set -e

DOTFILES="$(cd "$(dirname "$0")" && pwd)"

info() { printf "\033[0;34m  [info]\033[0m  %s\n" "$1"; }
ok()   { printf "\033[0;32m  [ok]\033[0m    %s\n" "$1"; }

echo ""
echo "  dotfiles setup"
echo "  =============="
echo ""

# --- macOS: Homebrew + packages ---
if [ "$(uname -s)" = "Darwin" ]; then
    if ! command -v brew &>/dev/null; then
        info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        # Add brew to PATH for the rest of this script
        if [ -f /opt/homebrew/bin/brew ]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        elif [ -f /usr/local/bin/brew ]; then
            eval "$(/usr/local/bin/brew shellenv)"
        fi
    else
        ok "Homebrew already installed"
    fi

    info "Installing packages from Brewfile..."
    brew bundle --file="$DOTFILES/Brewfile" || true
    echo ""
fi

# --- Symlinks + shell config ---
bash "$DOTFILES/install.sh"

echo ""
ok "Setup complete! Run 'source ~/.zshrc' or 'rsc' to reload."
