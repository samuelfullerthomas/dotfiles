#!/bin/sh

cd ~
git remote add origin git@github.com:samuelfullerthomas/dotfiles.git
git checkout -b master origin/master
git pull
