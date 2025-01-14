echo_info() {
    echo -e "\033[1;34m$1\033[0m"
}
echo_success() {
    echo -e "\033[1;32m$1\033[0m"
}

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

# git clone https://github.com/yourusername/vscode-config.git "$HOME/.vscode-config"
# ln -sfn "$(pwd)/vssettings.json" "$HOME/Library/Application Support/Code/User/settings.json"
cp "./vssettings.json" "$HOME/Library/Application Support/Code/User/settings.json"

