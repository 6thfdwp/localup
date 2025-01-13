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
nvm install --lts
nvm use --lts
echo_success "Node.js setup complete with NVM. Version: $(node -v)"


if ! command -v g &> /dev/null; then
    echo_info "Installing .g (Go Version Manager)..."
    curl -sSL https://raw.githubusercontent.com/voidint/g/master/install.sh | bash
else
    echo_success ".g already installed."
fi
source "$HOME/.g/env"

g install latest
g use latest
echo_success "Go environment setup complete. Version: $(go version)""