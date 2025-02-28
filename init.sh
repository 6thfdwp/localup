#!/bin/bash

# One-command setup script for a new Mac laptop
echo_info() {
    echo -e "\033[1;34m$1\033[0m"
}
echo_success() {
    echo -e "\033[1;32m$1\033[0m"
}
echo_info "Setting up your Mac..."

# Check for Xcode Command Line Tools
if ! xcode-select --print-path &> /dev/null; then
    echo_info "Installing Xcode Command Line Tools..."
    xcode-select --install
    read -p "Press [Enter] after the installation completes..."
else
    echo_success "✓ Xcode Command Line Tools already installed."
fi

# Install Homebrew if not already installed
if ! command -v brew &> /dev/null; then
    echo_info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
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
        brew install $1
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
    chsh -s /bin/zsh
    echo_success "✓ Zsh is now the default shell. Please restart your terminal."
else
    echo_success "✓ Zsh is already the default shell."
fi

# Install Oh My Zsh if not already installed
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo_info "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
    echo_success "✓ Oh My Zsh already installed."
fi