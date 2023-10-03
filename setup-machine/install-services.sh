#!/bin/sh
echo "installing services..."

brew install git
brew install git-gui
brew install rbenv
brew install imagemagick
brew install homebrew/versions/mysql56
brew install python
brew install rbenv
brew install redis
brew install ruby
brew install bash-completion
brew install docker
brew install kubectl

echo "all services installed!"

# nvm
echo "installing nvm..."
curl -o- https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash

source ~/.zshrc

nvm install --lts
nvm use --lts

echo "node installed!"


