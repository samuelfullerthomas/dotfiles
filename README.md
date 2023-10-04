# Misleading named dotfiles

![img](https://user-images.githubusercontent.com/10165959/70323974-2bbf4280-1826-11ea-80fe-0649d87c9ae1.gif)

Hi! this is the home directory for this computer and it is also a fairly exclusive git repo

The linked git repo stores useful dot files and also this readme which lets me setup a new machine to my preferred specifications. The setup-machine folder has a bunch of scripts that help me setup a new computer with a few simple commands! How sweet it that! Pretty sweet, is what.

## From scratch setup

### Step 0

1. download and load the `dotfiles` repo onto the new machine via a thumb drive (easiest way to do it!)
2. run `make move`

### Step 1

1. cd into ~/setup-machine
2. run `make bootstrap`

This runs xcode install, installs brew, and generates an ssh key!

Once you've added the ssh key to github:

3. run `make tracking`

This will make the repo track the remote and switch to the master branch

### Step 2

1. run `make machine`

this one will take a while, as it installs services, applications, and utilities

### Web browsers

Firefox developer version
Google Chrome

### notes app

Bear

### Terminal

iTerm2

### code editor

VSCode

### db explorer

sequel pro

### 2fa

authy

### disk managment

daisy disk

### chat

slack

### misc

muzzle
kap
private internet access
docker for mac
photoshop

sleepwatcher

I use [sleepwatcher](https://www.bernhard-baehr.de/) to manage a single thing on sleep and wakeup - turning off bluetooth! I have bluetooth headphones and they sometimes connect at annoying times to the computer, so I use sleepwatcher to turn off bluetooth when the computer goes to sleep, and turn it back on when it wakes up.

I learned about it here:
https://www.kodiakskorner.com/log/258

### Things to install manually

google cloud sdk
https://cloud.google.com/sdk/docs/quickstart-macos

iterm setup with profile & badge

see for color schemes:
https://iterm2colorschemes.com

see for profile setup:
https://stackoverflow.com/questions/35211565/how-do-i-import-an-iterm2-profile

the badge setup is:

`\(user.gitBranch)\n signing as \(user.profile)`

macos apps not on brew, but in the app store:

plash: https://apps.apple.com/gb/app/plash/id1494023538?mt=12

plash website for displaying the time on the homepage is: https://time.pablopunk.com?seconds&fg=white&bg=transparent&position=bottom-right

gifski: https://apps.apple.com/gb/app/gifski/id1351639930?mt=12
heic-converter: https://apps.apple.com/gb/app/heic-converter/id1294126402?mt=12

gpg keys are located in:

in the `backups` drive in icloud, password protected


Desktop backgrounds:

https://github.com/samuelfullerthomas/backgrounds