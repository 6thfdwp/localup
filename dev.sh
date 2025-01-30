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
# need to add GOPATH in .g/env. usually $HOME/go
g install 1.22.10
# g use 1.22.10
echo_success "Go environment setup complete. Version: $(go version)"

if ! command -v pyenv &> /dev/null; then
    echo_info "Installing Pyenv..."
    # curl https://pyenv.run | bash
    brew install pyenv
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    # eval "$(pyenv init --path)"
    eval "$(pyenv init - zsh)"
else
    echo_success "Pyenv already installed."
fi

# Install Python 3.11
pyenv install 3.11
pyenv global 3.11
# pyenv local 3.11.0 # only for current project dir
# pyenv shell 3.11.0 # only for current shell session
echo_success "Python environment setup complete. Version: $(python -V)"

brew install pyenv-virtualenv
# this need to be in .zshrc
# eval "$(pyenv virtualenv-init -)"

#*************** IDE **************** #
# install font: Jetbrains Mono ExtraLight, Jetbrains Mono, Jetbrains Mono Thin, Jetbrains Mono
brew install --cask font-jetbrains-mono

# Clone VSCode settings and extensions
if [ -f "$HOME/Library/Application Support/Code/User/settings.json" ]; then
    echo_info "Backing up existing VSCode settings..."
    mv "$HOME/Library/Application Support/Code/User/settings.json" "$HOME/Library/Application Support/Code/User/settings.json.bak"
fi

# export common extensions
# Theme: Nortics Arctis. Font family: Jetbrains Mono 
# 
# Install VSCode extensions
echo_info "Restoring VSCode settings and extensions..."
while read -r extension; do
    code --install-extension "$extension"
done < "./vsext.txt"

cp "./vssettings.json" "$HOME/Library/Application Support/Code/User/settings.json"
# restore .zshrc maybe manually
# cp .zshrc ~/.zshrc
# source ~/.zshrc

echo_success "Dev env done."