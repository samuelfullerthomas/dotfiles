#!/bin/sh
brew install git
brew install imagemagick
brew install homebrew/versions/mysql56
brew install python
brew install rbenv
brew install redis
brew install ruby

# nvm
curl -o- https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash
source ~/.zshrc
nvm install 10

nvm alias default 10
nvm use 10

npm install -g ndb lock-cli commitizen standard avn avn-nvm avn-n
avn setup

nvm install 8 --reinstall-packages-from=10
avn setup
