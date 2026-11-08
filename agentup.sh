#!/bin/bash

# Setup for the parallel-agent workflow: one agent per git worktree,
# one tmux window per worktree.
#
#   bash agentup.sh          install / update everything (idempotent)
#   bash agentup.sh --check   report what's installed, change nothing
#   (DRYRUN=1 / `make agentup dryrun` does the same)
#
# Installs tmux + fzf, links the tmux config, installs Claude Code and sets up skills,
# plugins and MCP servers, and puts the `wt`, `wt-rm` and `wt-jump` tools on
# PATH. Config files are SYMLINKED back into this
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
if [ "${1:-}" = "--check" ] || [ "${DRYRUN:-0}" = 1 ]; then CHECK_ONLY=1; fi

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
echo_info "[3/5] Worktree tools (wt, wt-rm, wt-jump)"
link "$SRC/bin/wt" "$HOME/.local/bin/wt"
link "$SRC/bin/wt-rm" "$HOME/.local/bin/wt-rm"
link "$SRC/bin/wt-jump" "$HOME/.local/bin/wt-jump"

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

# --- 4. Claude Code skills, plugins, MCP ------------------------------------
echo_info "[4/5] Claude Code skills, plugins, MCP"

# install_skill <name> <package> — public skills via the skills CLI.
# Needs npx (Node comes from `make devup`).
install_skill() {
    local name=$1 pkg=$2

    if [ -e "$HOME/.claude/skills/$name" ]; then
        echo_success "  ✓ skill $name"
    elif [ $CHECK_ONLY -eq 1 ]; then
        echo_warn "  ~ skill $name not installed ($pkg)"
    elif ! command -v npx &> /dev/null; then
        echo_warn "  ~ npx not found — run 'make devup', then re-run, to get $name"
    elif npx --yes skills add "$pkg" -g -a claude-code -s "$name" -y > /dev/null 2>&1; then
        echo_success "  ✓ installed skill $name"
        CHANGED=1
    else
        echo_error "  ✗ failed to install skill $name from $pkg"
    fi
}
install_skill humanizer blader/humanizer
install_skill idea-refine addyosmani/agent-skills
install_skill interview-me addyosmani/agent-skills

# Claude Code itself: native installer (self-updating; lands in ~/.local/bin).
export PATH="$HOME/.local/bin:$PATH"
if command -v claude &> /dev/null; then
    echo_success "  ✓ claude ($(claude --version 2>&1 | head -1))"
elif [ $CHECK_ONLY -eq 1 ]; then
    echo_warn "  ~ claude not installed"
elif curl -fsSL https://claude.ai/install.sh | bash > /dev/null 2>&1; then
    echo_success "  ✓ installed claude"
    CHANGED=1
else
    echo_error "  ✗ failed to install claude (https://claude.ai/install.sh)"
fi

if ! command -v claude &> /dev/null; then
    echo_warn "  ~ claude not on PATH — skipping plugins and MCP servers"
else
    # install_plugin <plugin@marketplace>. context7 also brings its MCP server.
    PLUGINS_INSTALLED=$(claude plugin list 2>/dev/null)
    install_plugin() {
        if grep -q "❯ $1\$" <<< "$PLUGINS_INSTALLED"; then
            echo_success "  ✓ plugin $1"
        elif [ $CHECK_ONLY -eq 1 ]; then
            echo_warn "  ~ plugin $1 not installed"
        elif claude plugin install "$1" > /dev/null 2>&1; then
            echo_success "  ✓ installed plugin $1"
            CHANGED=1
        else
            echo_error "  ✗ failed to install plugin $1"
        fi
    }
    install_plugin commit-commands@claude-plugins-official
    install_plugin context7@claude-plugins-official
    install_plugin feature-dev@claude-plugins-official
    install_plugin frontend-design@claude-plugins-official
    install_plugin pyright-lsp@claude-plugins-official
    install_plugin ralph-loop@claude-plugins-official

    # install_mcp <name> <url> — user-scoped HTTP server. OAuth happens on first
    # use (/mcp inside Claude Code); no secrets are stored here.
    install_mcp() {
        local name=$1 url=$2
        if claude mcp get "$name" &> /dev/null; then
            echo_success "  ✓ mcp $name"
        elif [ $CHECK_ONLY -eq 1 ]; then
            echo_warn "  ~ mcp $name not configured"
        elif claude mcp add --scope user --transport http "$name" "$url" > /dev/null 2>&1; then
            echo_success "  ✓ added mcp $name (authenticate via /mcp)"
            CHANGED=1
        else
            echo_error "  ✗ failed to add mcp $name"
        fi
    }
    install_mcp linear-server https://mcp.linear.app/mcp
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
    Ctrl+a Space      fuzzy-jump between tasks
    Alt+h / Alt+l     previous / next task
    Ctrl+a d          detach (agents keep running)
    Ctrl+a m          toggle mouse mode

  For a new repo, copy the template and edit:
    cp ~/.config/wt/example.conf ~/.config/wt/<repo-name>.conf
EOF
