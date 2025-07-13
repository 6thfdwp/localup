#!/bin/bash

echo "==== Git Global Configuration ===="

# Prompt for Git user.name
read -p "Enter your Git user.name (e.g., Your Name): " GIT_NAME

# Prompt for Git user.email (reused for SSH key)
read -p "Enter your Git user.email (must match your GitHub/GitLab account): " GIT_EMAIL

# Set Git global config
git config --global user.name "$GIT_NAME"
git config --global user.email "$GIT_EMAIL"

# Set default branch to 'main'
git config --global init.defaultBranch main

# # Optional: set editor to VSCode if installed
# if command -v code &> /dev/null; then
#     git config --global core.editor "code --wait"
#     echo "Set VSCode as git editor."
# fi

# alias
git config --global alias.logline 'log --graph --pretty=format:"%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset" --abbrev-commit'


echo "==== SSH Key Setup ===="

KEY_PATH="$HOME/.ssh/id_ed25519"

if [ -f "$KEY_PATH" ]; then
    echo "SSH key already exists at $KEY_PATH"
else
    ssh-keygen -t ed25519 -C "$GIT_EMAIL" -f "$KEY_PATH" -N ""
fi

eval "$(ssh-agent -s)"
ssh-add "$KEY_PATH"

# Copy public key to clipboard
if command -v pbcopy &> /dev/null; then
    pbcopy < "${KEY_PATH}.pub"
    echo "✅ Public key copied to clipboard (macOS)"
elif command -v xclip &> /dev/null; then
    xclip -selection clipboard < "${KEY_PATH}.pub"
    echo "✅ Public key copied to clipboard (Linux)"
else
    echo "⚠️  Install 'xclip' to copy to clipboard automatically on Linux."
    echo "---- Your public key ----"
    cat "${KEY_PATH}.pub"
    echo "------------------------"
fi

echo "👉 Go to your Git hosting provider (e.g., GitHub: https://github.com/settings/keys)"
echo "   Paste your public key there."

# (Optional) Update Git remote to SSH
read -p "Do you want to update a local Git repo remote to SSH? (y/n): " UPDATE_REMOTE
if [ "$UPDATE_REMOTE" = "y" ]; then
    read -p "Enter the path to your repo: " REPO_PATH
    cd "$REPO_PATH" || exit
    ORIGIN_URL=$(git remote get-url origin)
    SSH_URL=$(echo "$ORIGIN_URL" | sed -E 's#https://([^/]+)/([^/]+)/([^\.]+)(\.git)?#git@\1:\2/\3.git#')
    git remote set-url origin "$SSH_URL"
    echo "✅ Remote 'origin' updated to $SSH_URL"
fi

echo "🎉 All done! Test your setup with: git config --list && git push"