#!/bin/bash
#
# install.sh — Bootstrap script for dotfiles
#
# Usage:
#   git clone https://github.com/ellisbrown/dotfiles.git ~/dotfiles
#   bash ~/dotfiles/install.sh
#
# Safe to run multiple times (idempotent).

set -e

DOTFILES="$(cd "$(dirname "$0")" && pwd)"

# --- State for batch conflict resolution ---
overwrite_all=false
backup_all=false
skip_all=false

info()  { printf "\033[0;34m  [info]\033[0m  %s\n" "$1"; }
ok()    { printf "\033[0;32m  [ok]\033[0m    %s\n" "$1"; }
warn()  { printf "\033[0;33m  [warn]\033[0m  %s\n" "$1"; }
fail()  { printf "\033[0;31m  [fail]\033[0m  %s\n" "$1"; }

link_file() {
    local src="$1" dst="$2"

    local overwrite="" backup="" skip=""

    if [ -f "$dst" ] || [ -d "$dst" ] || [ -L "$dst" ]; then
        if [ "$overwrite_all" = false ] && [ "$backup_all" = false ] && [ "$skip_all" = false ]; then
            # Check if it's already linked correctly
            if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
                skip=true
            else
                local currentSrc
                currentSrc="$(readlink "$dst" 2>/dev/null || echo "$dst")"
                warn "File already exists: $dst (-> $currentSrc)"
                printf "   [s]kip, [S]kip all, [o]verwrite, [O]verwrite all, [b]ackup, [B]ackup all? "
                read -r -n 1 action
                echo

                case "$action" in
                    o) overwrite=true ;;
                    O) overwrite_all=true ;;
                    b) backup=true ;;
                    B) backup_all=true ;;
                    s) skip=true ;;
                    S) skip_all=true ;;
                    *) skip=true ;;
                esac
            fi
        fi

        overwrite=${overwrite:-$overwrite_all}
        backup=${backup:-$backup_all}
        skip=${skip:-$skip_all}

        if [ "$overwrite" = true ]; then
            rm -rf "$dst"
            ok "Removed $dst"
        fi

        if [ "$backup" = true ]; then
            mv "$dst" "${dst}.backup"
            ok "Backed up $dst -> ${dst}.backup"
        fi

        if [ "$skip" = true ]; then
            ok "Skipped $dst"
            return 0
        fi
    fi

    # Create parent directory if needed
    mkdir -p "$(dirname "$dst")"
    ln -s "$src" "$dst"
    ok "Linked $dst -> $src"
}

# ==============================================================================
#  Symlink mappings
# ==============================================================================

info "Installing dotfiles from $DOTFILES"
echo ""

# Universal configs (all platforms)
link_file "$DOTFILES/shell/aliases"    "$HOME/.aliases"
link_file "$DOTFILES/shell/inputrc"    "$HOME/.inputrc"
link_file "$DOTFILES/vim/vimrc"        "$HOME/.vimrc"
link_file "$DOTFILES/tmux/tmux.conf"   "$HOME/.tmux.conf"
link_file "$DOTFILES/gdb/gdbinit"      "$HOME/.gdbinit"
link_file "$DOTFILES/git/gitconfig"    "$HOME/.gitconfig"
link_file "$DOTFILES/git/gitignore_global" "$HOME/.gitignore_global"

# macOS-only configs
if [ "$(uname -s)" = "Darwin" ]; then
    info "Detected macOS — installing platform-specific configs"
    link_file "$DOTFILES/ghostty/config" "$HOME/Library/Application Support/com.mitchellh.ghostty/config"
fi

# ==============================================================================
#  Shell RC sourcing
# ==============================================================================

echo ""
info "Configuring shell RC files"

# Lines to add to shell rc files
dotfiles_block='
# dotfiles (https://github.com/ellisbrown/dotfiles)
export DOTFILES="'"$DOTFILES"'"
if [ -f ~/.aliases ]; then
    . ~/.aliases
fi'

add_to_rc() {
    local rc_file="$1"
    # Create the RC file if it doesn't exist (e.g., fresh cluster nodes)
    if [ ! -f "$rc_file" ]; then
        touch "$rc_file"
        ok "Created $rc_file"
    fi
    if ! grep -qF 'export DOTFILES=' "$rc_file" 2>/dev/null; then
        echo "$dotfiles_block" >> "$rc_file"
        ok "Added dotfiles sourcing to $rc_file"
    else
        ok "Already configured in $rc_file"
    fi
}

add_to_rc "$HOME/.zshrc"
add_to_rc "$HOME/.bashrc"

# ==============================================================================
#  Local overrides setup
# ==============================================================================

echo ""
if [ ! -f "$HOME/.localrc" ]; then
    info "No ~/.localrc found. You can create one for machine-specific config:"
    info "  cp $DOTFILES/shell/localrc.example ~/.localrc"
else
    ok "~/.localrc exists"
fi

# ==============================================================================
#  Done
# ==============================================================================

echo ""
ok "Dotfiles installed! Run 'source ~/.zshrc' or 'rsc' to reload."
