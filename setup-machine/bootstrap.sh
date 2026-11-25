#!/bin/bash
# Takes a fresh Mac to a configured one. Safe to rerun: every step checks first.
#
#   bash bootstrap.sh personal        (or work)
#
# On a fresh Mac, curl this from the public repo:
#   curl -fsSL https://raw.githubusercontent.com/samuelfullerthomas/dotfiles/main/setup-machine/bootstrap.sh | bash -s personal
# It clones the private repo (public main plus private files) once step 3 has set
# up a GitHub key; DOTFILES_REPO=<url> clones another, e.g. the public one.
# Stock bash 3.2 only: Homebrew doesn't exist yet.
set -euo pipefail

MACHINE="${1:-${MACHINE:-}}"
DOTFILES_REPO="${DOTFILES_REPO:-git@github.com:samuelfullerthomas/dotfiles-private.git}"
SSH_KEY_EMAIL="${SSH_KEY_EMAIL:-sft89@pm.me}"
SSH_KEY="$HOME/.ssh/id_ed25519"

ask() { local reply; read -r -p "$1" reply </dev/tty; printf '%s' "$reply"; }
step() { printf '\n==> %s\n' "$1"; }

while [ "$MACHINE" != work ] && [ "$MACHINE" != personal ]; do
  MACHINE="$(ask 'Which machine is this? [work/personal] ')"
done

step "1. Xcode command line tools"
if xcode-select -p >/dev/null 2>&1; then echo "    already installed"
else
  xcode-select --install || true
  echo "    waiting for the installer to finish..."
  until xcode-select -p >/dev/null 2>&1; do sleep 10; done
fi

step "2. Homebrew"
if [ -x /opt/homebrew/bin/brew ]; then echo "    already installed"
else
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
eval "$(/opt/homebrew/bin/brew shellenv)"

step "3. SSH key for GitHub"
mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
if [ -f "$SSH_KEY" ]; then echo "    $SSH_KEY exists, keeping it"
else ssh-keygen -t ed25519 -C "$SSH_KEY_EMAIL" -f "$SSH_KEY"; fi
if ! grep -q '^Host github.com' "$HOME/.ssh/config" 2>/dev/null; then
  printf 'Host github.com\n\tAddKeysToAgent yes\n\tUseKeychain yes\n\tIdentityFile %s\n' "$SSH_KEY" >> "$HOME/.ssh/config"
  echo "    added a github.com entry to ~/.ssh/config"
fi
ssh-add --apple-use-keychain "$SSH_KEY" 2>/dev/null || true
until ssh -T -o StrictHostKeyChecking=accept-new git@github.com 2>&1 | grep -q 'successfully authenticated'; do
  pbcopy < "$SSH_KEY.pub"
  echo "    GitHub doesn't accept this key yet. It's on your clipboard: add it at https://github.com/settings/ssh/new"
  open https://github.com/settings/ssh/new || true
  ask "    Press enter once it's added. " >/dev/null
done
echo "    GitHub accepts the key"

step "4. Dotfiles repo in ~"
if git -C "$HOME" rev-parse --git-dir >/dev/null 2>&1; then
  echo "    ~ is already a git repo ($(git -C "$HOME" rev-parse --abbrev-ref HEAD)), leaving it as is"
else
  git -C "$HOME" init -q
  git -C "$HOME" remote add origin "$DOTFILES_REPO"
  git -C "$HOME" fetch -q origin
  branch="$(git -C "$HOME" ls-remote --symref origin HEAD | awk '/^ref:/ {sub("refs/heads/", "", $2); print $2}')"
  # Fails, without overwriting, if ~ already has an untracked README.md or .gitignore.
  git -C "$HOME" checkout -b "$branch" --track "origin/$branch"
fi
if [ ! -f "$HOME/setup-machine/doctor.sh" ]; then
  echo "    ~/setup-machine is on a branch without bootstrap/doctor (old per-machine branch?)." >&2
  echo "    Switch ~ to the shared branch (git -C ~ switch <branch>) and rerun." >&2
  exit 1
fi
cd "$HOME/setup-machine"
echo "$MACHINE" > .machine

step "5. oh-my-zsh and nvm directory"
if [ -d "$HOME/.oh-my-zsh" ]; then echo "    oh-my-zsh already installed"
else
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi
mkdir -p "$HOME/.nvm"

step "6. make apply (apps, dotfile links, macOS prefs)"
make apply

step "7. doctor"
./doctor.sh || true
echo
echo "Done. Log out and back in for keyboard settings, then run 'make doctor' again."
