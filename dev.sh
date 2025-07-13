#!/bin/bash

# Exit on any error
set -e

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

# Function to check if command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Function to install package if not exists
install_package_if_not() {
    if ! command_exists "$1"; then
        echo_info "Installing $1..."
        brew install "$1"
    else
        echo_success "✓ $1 already installed."
    fi
}

echo_info "Setting up development environment..."

# Check if Homebrew is installed
if ! command_exists brew; then
    echo_error "Homebrew is required but not installed. Please run init.sh first."
    exit 1
fi

# ==================== NODE.JS SETUP ====================
echo_info "Setting up Node.js environment..."

# Install NVM (Node Version Manager)
if [ ! -d "$HOME/.nvm" ]; then
    echo_info "Installing NVM (Node Version Manager)..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
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
    nvm install --lts
    nvm use --lts
    nvm alias default node
    echo_success "✓ Node.js setup complete. Version: $(node -v)"
else
    echo_warning "NVM not found in PATH. Please restart your terminal and run this script again."
fi

# ==================== GO SETUP ====================
echo_info "Setting up Go environment..."

# Install g (Go Version Manager)
if ! command_exists g; then
    echo_info "Installing g (Go Version Manager)..."
    curl -sSL https://raw.githubusercontent.com/voidint/g/master/install.sh | bash
else
    echo_success "✓ g already installed."
fi

# Source g environment
if [ -f "$HOME/.g/env" ]; then
    source "$HOME/.g/env"
fi

if command_exists g; then
    echo_info "Installing Go 1.23.6..."
    g install 1.23.6
    g use 1.23.6
    echo_success "✓ Go environment setup complete. Version: $(go version)"
else
    echo_warning "g not found in PATH. Please restart your terminal and run this script again."
fi

# ==================== PYTHON SETUP WITH UV ====================
echo_info "Setting up Python environment with uv..."

# Install uv if not already installed
if ! command_exists uv; then
    echo_info "Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
else
    echo_success "✓ uv already installed."
fi

# ==================== IDE SETUP ====================
echo_info "Setting up IDE environment..."

# Install JetBrains Mono font
install_package_if_not "font-jetbrains-mono"

# Setup VSCode settings and extensions
if command_exists code; then
    echo_info "Setting up VSCode..."
    
    # Backup existing settings
    if [ -f "$HOME/Library/Application Support/Code/User/settings.json" ]; then
        echo_info "Backing up existing VSCode settings..."
        mv "$HOME/Library/Application Support/Code/User/settings.json" "$HOME/Library/Application Support/Code/User/settings.json.bak"
    fi
    
    # Install VSCode extensions
    if [ -f "./vs-extension.txt" ]; then
        echo_info "Installing VSCode extensions..."
        while read -r extension; do
            if [ -n "$extension" ] && [[ ! "$extension" =~ ^#.* ]]; then
                code --install-extension "$extension"
            fi
        done < "./vs-extension.txt"
    fi
    
    # Copy VSCode settings
    if [ -f "./vs-settings.json" ]; then
        cp "./vs-settings.json" "$HOME/Library/Application Support/Code/User/settings.json"
        echo_success "✓ VSCode settings restored."
    fi
else
    echo_warning "VSCode not found. Please install VSCode first."
fi

# ==================== FINAL SETUP ====================
echo_success "🎉 Development environment setup complete!"