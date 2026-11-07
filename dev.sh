#!/bin/bash

# DRYRUN=1 (or `make devup dryrun`) prints what would change and changes nothing.

# Exit on any error
set -e

DRYRUN=${DRYRUN:-0}

echo_info() {
    echo -e "\033[1;34m$1\033[0m"
}
echo_success() {
    echo -e "\033[1;32m$1\033[0m"
}
echo_warning() {
    echo -e "\033[1;33m$1\033[0m"
}
echo_error() {
    echo -e "\033[1;31m$1\033[0m"
}

# Run a command, or just print it in a dry run.
run() {
    if [ "$DRYRUN" = 1 ]; then
        echo_warning "  [dry-run] $*"
    else
        "$@"
    fi
}

# Function to check if command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Function to install package if not exists
install_package_if_not() {
    if ! command_exists "$1"; then
        echo_info "Installing $1..."
        run brew install "$1"
    else
        echo_success "✓ $1 already installed."
    fi
}

if [ "$DRYRUN" = 1 ]; then
    echo_warning "DRY RUN: nothing will be changed."
fi
echo_info "Setting up development environment..."

# Check if Homebrew is installed
if ! command_exists brew; then
    if [ "$DRYRUN" = 1 ]; then
        echo_warning "Homebrew is not installed (run init.sh first); brew steps below are listed only."
    else
        echo_error "Homebrew is required but not installed. Please run init.sh first."
        exit 1
    fi
fi

# ==================== NODE.JS SETUP ====================
echo_info "Setting up Node.js environment..."

# Install NVM (Node Version Manager)
if [ ! -d "$HOME/.nvm" ]; then
    echo_info "Installing NVM (Node Version Manager)..."
    run bash -c 'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash'
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
else
    echo_success "✓ NVM already installed."
fi

# Source NVM in current shell
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Install and use the latest LTS Node.js version
if command_exists nvm; then
    echo_info "Installing Node.js LTS..."
    run nvm install --lts
    run nvm use --lts
    run nvm alias default node
    [ "$DRYRUN" = 1 ] || echo_success "✓ Node.js setup complete. Version: $(node -v)"
elif [ "$DRYRUN" = 1 ]; then
    echo_warning "  [dry-run] would install Node.js LTS via nvm"
else
    echo_warning "NVM not found in PATH. Please restart your terminal and run this script again."
fi

# ==================== GO SETUP ====================
echo_info "Setting up Go environment..."

# Install g (Go Version Manager)
if ! command_exists g; then
    echo_info "Installing g (Go Version Manager)..."
    run bash -c 'curl -sSL https://raw.githubusercontent.com/voidint/g/master/install.sh | bash'
else
    echo_success "✓ g already installed."
fi

# Source g environment
if [ -f "$HOME/.g/env" ]; then
    source "$HOME/.g/env"
fi

if command_exists g; then
    echo_info "Installing Go 1.23.6..."
    run g install 1.23.6
    run g use 1.23.6
    [ "$DRYRUN" = 1 ] || echo_success "✓ Go environment setup complete. Version: $(go version)"
elif [ "$DRYRUN" = 1 ]; then
    echo_warning "  [dry-run] would install Go 1.23.6 via g"
else
    echo_warning "g not found in PATH. Please restart your terminal and run this script again."
fi

# ==================== PYTHON SETUP WITH UV ====================
echo_info "Setting up Python environment with uv..."

# Install uv if not already installed
if ! command_exists uv; then
    echo_info "Installing uv..."
    run bash -c 'curl -LsSf https://astral.sh/uv/install.sh | sh'
else
    echo_success "✓ uv already installed."
fi

# ==================== IDE SETUP ====================
echo_info "Setting up IDE environment..."

# Install JetBrains Mono font (a cask, so check brew rather than PATH)
if command_exists brew && brew list --cask font-jetbrains-mono &> /dev/null; then
    echo_success "✓ font-jetbrains-mono already installed."
else
    echo_info "Installing font-jetbrains-mono..."
    run brew install --cask font-jetbrains-mono
fi

# Install a GUI app via Homebrew cask unless its .app is already present.
install_cask_if_not() {
    local app=$1 cask=$2
    if [ -d "/Applications/$app.app" ] || [ -d "$HOME/Applications/$app.app" ]; then
        echo_success "✓ $app already installed."
    else
        echo_info "Installing $app..."
        run brew install --cask "$cask"
    fi
}

# Terminal
install_cask_if_not "Warp" "warp"

# Warp settings are copied, not symlinked: Warp rewrites ~/.warp/settings.toml
# itself and would swap a symlink for a plain file. Never overwrites an
# existing file; re-export with `make warp-export`.
WARP_SETTINGS="$HOME/.warp/settings.toml"
WARP_SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/warp-settings.toml"
if [ ! -e "$WARP_SETTINGS" ]; then
    run mkdir -p "$(dirname "$WARP_SETTINGS")"
    run cp "$WARP_SRC" "$WARP_SETTINGS"
    [ "$DRYRUN" = 1 ] || echo_success "✓ Warp settings installed."
elif cmp -s "$WARP_SRC" "$WARP_SETTINGS"; then
    echo_success "✓ Warp settings already match."
else
    echo_warning "Warp settings differ from this repo; left as is (make warp-export to save yours)."
fi

# Zed + keymap (symlinked, so edits in this repo are live)
install_cask_if_not "Zed" "zed"
ZED_KEYMAP="$HOME/.config/zed/keymap.json"
KEYMAP_SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/keymap.json"
if [ "$(readlink "$ZED_KEYMAP" 2>/dev/null)" = "$KEYMAP_SRC" ]; then
    echo_success "✓ Zed keymap already linked."
else
    run mkdir -p "$(dirname "$ZED_KEYMAP")"
    if [ -e "$ZED_KEYMAP" ] || [ -L "$ZED_KEYMAP" ]; then
        run mv "$ZED_KEYMAP" "$ZED_KEYMAP.bak.$(date +%Y%m%d-%H%M%S)"
    fi
    run ln -s "$KEYMAP_SRC" "$ZED_KEYMAP"
    [ "$DRYRUN" = 1 ] || echo_success "✓ Zed keymap linked."
fi

# VSCode is switched off for now; set SETUP_VSCODE=1 to include it.
# Setup VSCode settings and extensions
if [ "${SETUP_VSCODE:-0}" != 1 ]; then
    echo_warning "Skipping VSCode (SETUP_VSCODE=1 to enable)."
elif command_exists code; then
    echo_info "Setting up VSCode..."
    
    # Backup existing settings
    if [ -f "$HOME/Library/Application Support/Code/User/settings.json" ]; then
        echo_info "Backing up existing VSCode settings..."
        run mv "$HOME/Library/Application Support/Code/User/settings.json" "$HOME/Library/Application Support/Code/User/settings.json.bak"
    fi
    
    # Install VSCode extensions (skip the ones already present)
    if [ -f "./vs-extension.txt" ]; then
        echo_info "Installing VSCode extensions..."
        installed_ext=$(code --list-extensions | tr 'A-Z' 'a-z')
        while read -r extension; do
            if [ -n "$extension" ] && [[ ! "$extension" =~ ^#.* ]]; then
                ext_lc=$(echo "$extension" | tr 'A-Z' 'a-z')
                if grep -qx "$ext_lc" <<< "$installed_ext"; then
                    echo_success "  ✓ $extension"
                else
                    run code --install-extension "$extension"
                fi
            fi
        done < "./vs-extension.txt"
    fi
    
    # Copy VSCode settings
    if [ -f "./vs-settings.json" ]; then
        run cp "./vs-settings.json" "$HOME/Library/Application Support/Code/User/settings.json"
        [ "$DRYRUN" = 1 ] || echo_success "✓ VSCode settings restored."
    fi
else
    echo_warning "VSCode not found. Please install VSCode first."
fi

# ==================== ZSH CONFIG ====================
# ~/.zshrc just sources zshrc.shared from this repo. An existing ~/.zshrc is
# backed up first; installer appends and local tweaks then go below the source line.
echo_info "Setting up zsh config..."
ZSHRC="$HOME/.zshrc"
ZSH_SHARED="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/zshrc.shared"
if grep -q 'localup-managed' "$ZSHRC" 2>/dev/null; then
    echo_success "✓ ~/.zshrc already sources zshrc.shared."
else
    if [ -f "$ZSHRC" ]; then
        run mv "$ZSHRC" "$ZSHRC.bak.$(date +%Y%m%d-%H%M%S)"
    fi
    if [ "$DRYRUN" = 1 ]; then
        echo_warning "  [dry-run] write ~/.zshrc that sources $ZSH_SHARED"
    else
        printf '# localup-managed: edit zshrc.shared in the localup repo; machine-specific lines go below.\nsource "%s"\n' "$ZSH_SHARED" > "$ZSHRC"
        echo_success "✓ ~/.zshrc now sources zshrc.shared."
    fi
fi

# ==================== FINAL SETUP ====================
if [ "$DRYRUN" = 1 ]; then
    echo_success "Dry run complete; nothing was changed."
else
    echo_success "🎉 Development environment setup complete!"
fi
