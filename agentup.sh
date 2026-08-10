#!/bin/bash

# Setup for the parallel-agent workflow: one agent per git worktree,
# one tmux window per worktree.
#
#   bash agentup.sh          install / update everything (idempotent)
#   bash agentup.sh --check   report what's installed, change nothing
#
# Installs tmux + fzf, links the tmux/Ghostty configs, and puts the `wt` and
# `wt-rm` worktree tools on PATH. Config files are SYMLINKED back into this
# repo, so editing them here updates them live everywhere and the changes are
# tracked in git. Anything already in place is backed up before being replaced.

set -uo pipefail

echo_info() { echo -e "\033[1;34m$1\033[0m"; }
echo_success() { echo -e "\033[1;32m$1\033[0m"; }
echo_warn() { echo -e "\033[1;33m$1\033[0m"; }
echo_error() { echo -e "\033[1;31m$1\033[0m"; }

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$REPO_DIR/agent"
CHECK_ONLY=0
[ "${1:-}" = "--check" ] && CHECK_ONLY=1

BACKUP_DIR="$HOME/.agentup-backup/$(date +%Y%m%d-%H%M%S)"
CHANGED=0

# link <source> <destination> — symlink, backing up whatever was there.
link() {
    local src=$1 dst=$2

    if [ ! -e "$src" ]; then
        echo_error "  ✗ missing payload: $src"
        return 1
    fi

    # Already pointing where we want it.
    if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
        echo_success "  ✓ $dst"
        return 0
    fi

    if [ $CHECK_ONLY -eq 1 ]; then
        if [ -e "$dst" ]; then
            echo_warn "  ~ $dst exists but is not linked to this repo"
        else
            echo_warn "  ~ $dst missing"
        fi
        return 0
    fi

    # Back up a real file (or a symlink pointing somewhere else).
    if [ -e "$dst" ] || [ -L "$dst" ]; then
        mkdir -p "$BACKUP_DIR"
        mv "$dst" "$BACKUP_DIR/$(basename "$dst")"
        echo_warn "  backed up existing $(basename "$dst") -> $BACKUP_DIR/"
    fi

    mkdir -p "$(dirname "$dst")"
    ln -s "$src" "$dst"
    echo_success "  ✓ linked $dst"
    CHANGED=1
}

install_package_if_not() {
    if ! command -v "$1" &> /dev/null; then
        if [ $CHECK_ONLY -eq 1 ]; then
            echo_warn "  ~ $1 not installed"
            return 0
        fi
        echo_info "  installing $1..."
        brew install "$1"
        CHANGED=1
    else
        # tmux reports its version with -V, not --version.
        local ver
        case "$1" in
            tmux) ver=$(tmux -V 2>&1 | head -1) ;;
            *)    ver=$("$1" --version 2>&1 | head -1) ;;
        esac
        echo_success "  ✓ $1 (${ver:0:40})"
    fi
}

if [ $CHECK_ONLY -eq 1 ]; then
    echo_info "Checking agent workflow setup (no changes will be made)..."
else
    echo_info "Setting up the parallel-agent workflow..."
fi

# --- 1. packages ------------------------------------------------------------
echo_info "[1/5] Packages"
if ! command -v brew &> /dev/null; then
    echo_error "  ✗ Homebrew not found — run 'make init' first."
    exit 1
fi
install_package_if_not tmux
install_package_if_not fzf

# --- 2. tmux ----------------------------------------------------------------
echo_info "[2/5] tmux config"
link "$SRC/tmux.conf" "$HOME/.tmux.conf"

# --- 3. worktree tools ------------------------------------------------------
echo_info "[3/5] Worktree tools (wt, wt-rm)"
link "$SRC/bin/wt" "$HOME/.local/bin/wt"
link "$SRC/bin/wt-rm" "$HOME/.local/bin/wt-rm"

# Per-repo configs. Never clobber these — they can hold machine-local tweaks.
mkdir -p "$HOME/.config/wt"
for conf in "$SRC"/wt/*.conf; do
    [ -e "$conf" ] || continue
    dest="$HOME/.config/wt/$(basename "$conf")"
    if [ -e "$dest" ] || [ -L "$dest" ]; then
        echo_success "  ✓ $(basename "$conf") (already present, left alone)"
    else
        link "$conf" "$dest"
    fi
done

# ~/.local/bin has to be on PATH or `wt` won't resolve.
if ! echo "$PATH" | tr ':' '\n' | grep -qx "$HOME/.local/bin"; then
    if [ $CHECK_ONLY -eq 1 ]; then
        echo_warn "  ~ ~/.local/bin is not on PATH"
    elif ! grep -q '.local/bin' "$HOME/.zshrc" 2>/dev/null; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc"
        echo_warn "  added ~/.local/bin to PATH in .zshrc — restart your shell"
        CHANGED=1
    fi
else
    echo_success "  ✓ ~/.local/bin on PATH"
fi

# --- 4. Ghostty -------------------------------------------------------------
echo_info "[4/5] Ghostty"
GHOSTTY_APP="/Applications/Ghostty.app"
if [ -d "$GHOSTTY_APP" ]; then
    link "$SRC/ghostty.conf" \
         "$HOME/Library/Application Support/com.mitchellh.ghostty/config.ghostty"

    # Ghostty sets TERM=xterm-ghostty but ships its terminfo inside the app
    # bundle. Anything that doesn't inherit TERMINFO (sudo, a tmux server
    # started elsewhere) then loses truecolor. Install it into the user db.
    if ! infocmp xterm-ghostty &> /dev/null; then
        if [ $CHECK_ONLY -eq 1 ]; then
            echo_warn "  ~ xterm-ghostty terminfo not installed"
        else
            tf="$GHOSTTY_APP/Contents/Resources/terminfo"
            if TERMINFO="$tf" infocmp -x xterm-ghostty > /tmp/ghostty.ti 2>/dev/null \
               && tic -x -o "$HOME/.terminfo" /tmp/ghostty.ti 2>/dev/null; then
                echo_success "  ✓ installed xterm-ghostty terminfo"
                CHANGED=1
            else
                echo_warn "  could not install xterm-ghostty terminfo (cosmetic only)"
            fi
            rm -f /tmp/ghostty.ti
        fi
    else
        echo_success "  ✓ xterm-ghostty terminfo"
    fi
else
    echo_warn "  ~ Ghostty not installed — skipping (brew install --cask ghostty)"
fi

# --- 5. summary -------------------------------------------------------------
echo_info "[5/5] Done"

if [ $CHECK_ONLY -eq 1 ]; then
    echo "  Run 'make agentup' to apply anything marked ~"
    exit 0
fi

[ -d "$BACKUP_DIR" ] && echo_warn "  Replaced files are in $BACKUP_DIR"
[ $CHANGED -eq 0 ] && echo_success "  Everything was already in place."

cat <<'EOF'

  Quick start:
    cd <a git repo>
    wt my-task        create a worktree + tmux window for a task
    wt                fzf-pick an existing worktree
    wt-rm my-task     tear it down (refuses if uncommitted/unpushed)
    wt-rm --merged    sweep everything already merged into main

  In tmux:
    Ctrl+b Space      fuzzy-jump between tasks
    Alt+h / Alt+l     previous / next task
    Ctrl+b d          detach (agents keep running)
    Ctrl+b m          toggle mouse mode

  For a new repo, copy the template and edit:
    cp ~/.config/wt/example.conf ~/.config/wt/<repo-name>.conf

  Restart Ghostty for its config to take effect.
EOF
