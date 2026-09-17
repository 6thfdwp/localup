#!/bin/bash

# Optional Zellij setup for the parallel-agent workflow — an alternative to the
# tmux setup in agentup.sh, which this script does not touch.
#
#   bash zellijup.sh           install / update (idempotent)
#   bash zellijup.sh --check   report what's installed, change nothing
#
# Installs zellij and symlinks its config and layouts back into this repo, so
# edits here apply live and stay tracked in git. Anything already in place is
# backed up before being replaced.

set -uo pipefail

echo_info() { echo -e "\033[1;34m$1\033[0m"; }
echo_success() { echo -e "\033[1;32m$1\033[0m"; }
echo_warn() { echo -e "\033[1;33m$1\033[0m"; }
echo_error() { echo -e "\033[1;31m$1\033[0m"; }

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$REPO_DIR/agent/zellij"
CHECK_ONLY=0
[ "${1:-}" = "--check" ] && CHECK_ONLY=1

BACKUP_DIR="$HOME/.agentup-backup/zellij-$(date +%Y%m%d-%H%M%S)"
CHANGED=0

# link <source> <destination> — symlink, backing up whatever was there.
link() {
    local src=$1 dst=$2

    if [ ! -e "$src" ]; then
        echo_error "  ✗ missing payload: $src"
        return 1
    fi

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

if [ $CHECK_ONLY -eq 1 ]; then
    echo_info "Checking Zellij setup (no changes will be made)..."
else
    echo_info "Setting up Zellij for the parallel-agent workflow..."
fi

# --- 1. package --------------------------------------------------------------
echo_info "[1/3] Package"
if ! command -v brew &> /dev/null; then
    echo_error "  ✗ Homebrew not found — run 'make init' first."
    exit 1
fi
if command -v zellij &> /dev/null; then
    echo_success "  ✓ $(zellij --version)"
elif [ $CHECK_ONLY -eq 1 ]; then
    echo_warn "  ~ zellij not installed"
else
    echo_info "  installing zellij..."
    brew install zellij
    CHANGED=1
fi

# --- 2. config + layouts -----------------------------------------------------
# ~/.config/zellij is the first directory zellij searches on macOS.
echo_info "[2/3] Config and layouts"
ZJ_DIR="$HOME/.config/zellij"
link "$SRC/config.kdl" "$ZJ_DIR/config.kdl"
for layout in "$SRC"/layouts/*.kdl; do
    [ -e "$layout" ] || continue
    link "$layout" "$ZJ_DIR/layouts/$(basename "$layout")"
done

if [ $CHECK_ONLY -eq 0 ] && command -v zellij &> /dev/null; then
    if zellij setup --check 2>&1 | grep -q "Well defined"; then
        echo_success "  ✓ config parses"
    else
        echo_error "  ✗ zellij rejected the config — run 'zellij setup --check'"
    fi
fi

# --- 3. summary --------------------------------------------------------------
echo_info "[3/3] Done"

if [ $CHECK_ONLY -eq 1 ]; then
    echo "  Run 'make zellijup' to apply anything marked ~"
    exit 0
fi

[ -d "$BACKUP_DIR" ] && echo_warn "  Replaced files are in $BACKUP_DIR"
[ $CHANGED -eq 0 ] && echo_success "  Everything was already in place."

cat <<'HELP'

  Quick start (from inside a worktree):
    zellij --layout agent -s <task>     new session: agent pane + shell pane

  Zellij starts locked — every key goes to the agent or shell.
    Ctrl g            unlock, then p pane · t tab · o session · s scroll
    Ctrl g  o  w      session manager (fuzzy-switch between sessions)
    Alt ← / →         move between panes, and across tabs at the edge
    Ctrl g  o  d      detach (agents keep running); re-attach: zellij attach <task>

  Alt shortcuts need Option-as-Meta: in Zed, set terminal.option_as_meta.
  The tmux setup (make agentup, wt, wt-rm) is unaffected.
HELP
