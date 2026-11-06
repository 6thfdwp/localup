#!/bin/bash

# One-command setup script for a new Mac laptop
# DRYRUN=1 (or `make init dryrun`) prints what would change and changes nothing.

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

# Run a command, or just print it in a dry run.
run() {
    if [ "$DRYRUN" = 1 ]; then
        echo_warning "  [dry-run] $*"
    else
        "$@"
    fi
}

[ "$DRYRUN" = 1 ] && echo_warning "DRY RUN: nothing will be changed."
echo_info "Setting up your Mac..."

# Check for Xcode Command Line Tools
if ! xcode-select --print-path &> /dev/null; then
    echo_info "Installing Xcode Command Line Tools..."
    run xcode-select --install
    [ "$DRYRUN" = 1 ] || read -p "Press [Enter] after the installation completes..."
else
    echo_success "✓ Xcode Command Line Tools already installed."
fi

# Install Homebrew if not already installed
if ! command -v brew &> /dev/null; then
    echo_info "Installing Homebrew..."
    if [ "$DRYRUN" = 1 ]; then
        echo_warning "  [dry-run] run the Homebrew install script"
    else
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        # Apple Silicon installs to /opt/homebrew, which isn't on PATH yet.
        [ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
else
    echo_success "✓ Homebrew already installed."
fi

# Update Homebrew and install essential packages
# echo_info "Updating Homebrew and installing packages..."
# brew update
# brew install git zsh curl wget
install_package_if_not() {
    # if ! brew list -1 | grep -q "^$1\$"; then
    if ! command -v $1 &> /dev/null; then
        echo_info "Installing $1..."
        run brew install $1
    else
        echo_success "✓ $1 already installed."
    fi
}
# List of essential packages
packages=(git zsh)

# Loop through the packages and install if not already installed
for package in "${packages[@]}"; do
    install_package_if_not $package
done

# Set Zsh as the default shell
if [ "$SHELL" != "/bin/zsh" ]; then
    echo_info "Setting Zsh as the default shell..."
    run chsh -s /bin/zsh
    [ "$DRYRUN" = 1 ] || echo_success "✓ Zsh is now the default shell. Please restart your terminal."
else
    echo_success "✓ Zsh is already the default shell."
fi

# Install Oh My Zsh if not already installed
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo_info "Installing Oh My Zsh..."
    if [ "$DRYRUN" = 1 ]; then
        echo_warning "  [dry-run] run the Oh My Zsh install script"
    else
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    fi
else
    echo_success "✓ Oh My Zsh already installed."
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

# Apps
install_cask_if_not "Google Chrome" "google-chrome"
install_cask_if_not "Rectangle" "rectangle"

[ "$DRYRUN" = 1 ] && echo_success "Dry run complete; nothing was changed."
true
