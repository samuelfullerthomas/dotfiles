#!/bin/sh

echo 'generating an ssh key...'
ssh-keygen -t ed25519 -C "sft89@pm.me"
eval "$(ssh-agent -s)"
echo "Host github.com\n\tAddKeysToAgent yes\n\tUseKeychain yes\n\tIdentityFile ~/.ssh/id_ed25519" > ~/.ssh/config
ssh-add --apple-use-keychain ~/.ssh/id_ed25519
pbcopy < ~/.ssh/id_ed25519.pub
echo "ssh key generated and copied to cliboard! add it to https://github.com/settings/ssh/new now while xcode installs!"

#install xcode
echo 'installing xcode...'
xcode-select --install

#install hombrew
echo 'installing brew...'

# install brew
if test ! $(which brew); then
  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

brew update
brew upgrade
brew cleanup

export HOMEBREW_CASK_OPTS="--appdir=/Applications"
sudo chown -R $(whoami) $(brew --prefix)/*


cd ~
git remote add origin git@github.com:samuelfullerthomas/dotfiles.git
git checkout -b master origin/master
git pull