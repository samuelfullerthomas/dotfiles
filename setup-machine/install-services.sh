#!/bin/sh
sudo chown -R $(whoami) $(brew --prefix)/*
brew install git
brew install imagemagick
brew install homebrew/versions/mysql56
brew install python
brew install rbenv
brew install redis
brew install ruby
brew install bash-completion
brew cask install docker
brew install kubectl

# nvm
curl -o- https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash
source ~/.zshrc
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

nvm install 10

nvm alias default 10
nvm use 10

npm install -g ndb lock-cli commitizen standard avn avn-nvm avn-n vaca
avn setup

nvm install 8 --reinstall-packages-from=10
avn setup
