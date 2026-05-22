.PHONY: all bootstrap apps dotfiles prefs

all: bootstrap apps dotfiles prefs

# First-time setup: SSH key, Xcode, Homebrew
bootstrap:
	./setup-machine-fundamentals.sh

# Install all apps/tools via Brewfile
apps:
	brew bundle --file=Brewfile

# Symlink dotfiles into ~ via stow
dotfiles:
	cd dotfiles && stow --adopt --target=$(HOME) git bin vim shell

# macOS preferences
prefs:
	./change-prefs.sh
