#!/bin/bash
set -e

echo "=== New Machine Bootstrap ==="

# 1. Install Xcode CLI tools (needed for git)
if ! xcode-select -p &>/dev/null; then
  echo "Installing Xcode CLI tools..."
  xcode-select --install
  echo "Press enter once Xcode CLI tools are installed."
  read -r
fi

# 2. Install Homebrew
if ! command -v brew &>/dev/null; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# 3. Clone the repo (HTTPS - no SSH key needed yet)
if [ ! -d "$HOME/setup-machine" ]; then
  echo "Cloning dotfiles repo..."
  git clone https://github.com/samuelfullerthomas/dotfiles.git "$HOME/setup-machine-tmp"
  mv "$HOME/setup-machine-tmp/setup-machine" "$HOME/setup-machine"
  rm -rf "$HOME/setup-machine-tmp"
fi

cd "$HOME/setup-machine"

# 4. Generate SSH key (skip if one already exists)
if [ -f "$HOME/.ssh/id_ed25519" ]; then
  echo "SSH key already exists at ~/.ssh/id_ed25519, skipping generation."
else
  echo "Generating SSH key..."
  ssh-keygen -t ed25519 -C "sft89@pm.me"
  mkdir -p ~/.ssh
  cat <<EOF > ~/.ssh/config
Host github.com
	AddKeysToAgent yes
	UseKeychain yes
	IdentityFile ~/.ssh/id_ed25519
EOF
fi
eval "$(ssh-agent -s)"
ssh-add --apple-use-keychain ~/.ssh/id_ed25519
pbcopy < ~/.ssh/id_ed25519.pub
echo ""
echo "✅ SSH key copied to clipboard!"
echo "   → Add it at: https://github.com/settings/ssh/new"
echo "   → Then run: cd ~/setup-machine && make all"
echo ""
