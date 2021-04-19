#!/bin/sh
echo 'installing brew...'

# install brew
if test ! $(which brew); then
  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

brew update
brew upgrade
brew cleanup

export HOMEBREW_CASK_OPTS="--appdir=/Applications"

# utils
brew install daisydisk
brew install viscosity
brew install kap
brew install muzzle
brew install private-internet-access
brew install authy
brew install sequel-pro

# browsers
brew install homebrew/cask-versions/firefox-developer-edition
brew install google-chrome

# dev
brew install iterm2
#brew install virtualbox

# editors
brew install visual-studio-code

# fun
brew install slack
brew install spotify
brew install vlc
brew install vnc-viewer
