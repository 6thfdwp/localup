#!/bin/bash

# One-command setup script for a new Mac laptop
echo_info() {
    echo -e "\033[1;34m$1\033[0m"
}
echo_success() {
    echo -e "\033[1;32m$1\033[0m"
}

# Check for Xcode Command Line Tools
if ! xcode-select --print-path &> /dev/null; then
    echo_info "Installing Xcode Command Line Tools..."
    xcode-select --install
    read -p "Press [Enter] after the installation completes..."
else
    echo_success "Xcode Command Line Tools already installed."
fi

# Install Homebrew if not already installed
if ! command -v brew &> /dev/null; then
    echo_info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    echo_success "Homebrew already installed."
fi

# Update Homebrew and install essential packages
# echo_info "Updating Homebrew and installing packages..."
# brew update
# brew install git zsh curl wget

# Code langs env
# install .g to manage multi Go version
# install nvm 
# python?
