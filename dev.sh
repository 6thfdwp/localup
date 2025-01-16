echo_info() {
    echo -e "\033[1;34m$1\033[0m"
}
echo_success() {
    echo -e "\033[1;32m$1\033[0m"
}

# Install NVM (Node Version Manager)
if [ ! -d "$HOME/.nvm" ]; then
    echo_info "Installing NVM (Node Version Manager)..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
else
    echo_success "NVM already installed."
fi

# Install and use the latest Node.js version
if ! command -v nvm &> /dev/null; then
    nvm install --lts
    nvm use --lts
fi
echo_success "Node.js setup complete with NVM. Version: $(node -v)"


if ! command -v g &> /dev/null; then
    echo_info "Installing .g (Go Version Manager)..."
    curl -sSL https://raw.githubusercontent.com/voidint/g/master/install.sh | bash
else
    echo_success ".g already installed."
fi
source "$HOME/.g/env"

g install 1.22.10
# g use 1.22.10
echo_success "Go environment setup complete. Version: $(go version)"

# Set Zsh as the default shell
if [ "$SHELL" != "/bin/zsh" ]; then
    echo_info "Setting Zsh as the default shell..."
    chsh -s /bin/zsh
    echo_success "✓ Zsh is now the default shell. Please restart your terminal."
else
    echo_success "✓ Zsh is already the default shell."
fi


# python?
# Install Oh My Zsh if not already installed
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo_info "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
    echo_success "✓ Oh My Zsh already installed."
fi

# restore .zshrc maybe manually
# cp .zshrc ~/.zshrc
# source ~/.zshrc

# echo_success "Zsh setup complete with Oh My Zsh."