# Clone VSCode settings and extensions
if [ -f "$HOME/Library/Application Support/Code/User/settings.json" ]; then
    echo_info "Backing up existing VSCode settings..."
    mv "$HOME/Library/Application Support/Code/User/settings.json" "$HOME/Library/Application Support/Code/User/settings.json.bak"
fi

# install font: Jetbrains Mono ExtraLight, Jetbrains Mono, Jetbrains Mono Thin, Jetbrains Mono
# export common extensions
# Theme: Nortics Arctis. Font family: Jetbrains Mono 
# vim
# language support
# 
# Install VSCode extensions
while read -r extension; do
    code --install-extension "$extension"
done < "./vsext.txt"

echo_info "Restoring VSCode settings and extensions..."
# git clone https://github.com/yourusername/vscode-config.git "$HOME/.vscode-config"
# ln -sfn "$(pwd)/vssettings.json" "$HOME/Library/Application Support/Code/User/settings.json"
cp "./vssettings.json" "$HOME/Library/Application Support/Code/User/settings.json"

