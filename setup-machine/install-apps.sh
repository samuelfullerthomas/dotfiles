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
brew cask install daisydisk
brew cask install viscosity
brew cask install kap
brew cask install muzzle
brew cask install private-internet-access
brew cask install authy
brew cask install sequel-pro

# browsers
brew cask install firefox
brew cask install homebrew/cask-versions/firefox-developer-edition
brew cask install google-chrome

# dev
brew cask install iterm2
brew cask install virtualbox

# editors
brew cask install visual-studio-code

# fun
brew cask install slack
brew cask install spotify
brew cask install vlc
