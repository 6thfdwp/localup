# Clone VSCode settings and extensions
if [ -f "$HOME/Library/Application Support/Code/User/settings.json" ]; then
    echo_info "Backing up existing VSCode settings..."
    mv "$HOME/Library/Application Support/Code/User/settings.json" "$HOME/Library/Application Support/Code/User/settings.json.bak"
fi


echo_info "Restoring VSCode settings and extensions..."
git clone https://github.com/yourusername/vscode-config.git "$HOME/.vscode-config"
ln -s "$HOME/.vscode-config/settings.json" "$HOME/Library/Application Support/Code/User/settings.json"

# export common extensions
# Theme: Nortics Arctis
# vim
# language support
# 
# Install VSCode extensions
while read -r extension; do
    code --install-extension "$extension"
done < "$HOME/.vscode-config/extensions.txt"