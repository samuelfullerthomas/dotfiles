#!/bin/bash
set -e

echo "Generating SSH key..."
ssh-keygen -t ed25519 -C "sft89@pm.me"
eval "$(ssh-agent -s)"
cat <<EOF > ~/.ssh/config
Host github.com
	AddKeysToAgent yes
	UseKeychain yes
	IdentityFile ~/.ssh/id_ed25519
EOF
ssh-add --apple-use-keychain ~/.ssh/id_ed25519
pbcopy < ~/.ssh/id_ed25519.pub
echo "SSH key copied to clipboard! Add it to https://github.com/settings/ssh/new"

# Xcode CLI tools
echo "Installing Xcode CLI tools..."
xcode-select --install 2>/dev/null || true

# Homebrew
if ! command -v brew &>/dev/null; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

brew update
echo "Homebrew ready."
