# Dotfiles

Machine setup for macOS. Uses Homebrew, GNU Stow, and a Makefile.

## New Machine Setup

Open Terminal and run:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/samuelfullerthomas/dotfiles/master/setup-machine/bootstrap-new-machine.sh)"
```

This installs Xcode CLI tools, Homebrew, clones the repo, generates an SSH key, and copies it to your clipboard.

Then add the key at https://github.com/settings/ssh/new and run:

```bash
cd ~/setup-machine
make all
```

## What `make all` does

| Target | What it does |
|--------|-------------|
| `make bootstrap` | SSH key, Xcode CLI tools, Homebrew |
| `make apps` | Install everything in the Brewfile |
| `make dotfiles` | Symlink dotfiles into ~ via stow |
| `make prefs` | Apply macOS preferences |

Run any target individually to update just that piece.

## Structure

```
setup-machine/
├── Makefile
├── Brewfile                    # Declarative app/tool installs
├── bootstrap-new-machine.sh   # Curl this on a fresh machine
├── setup-machine-fundamentals.sh
├── change-prefs.sh            # macOS defaults
├── iterm/                     # iTerm config + color schemes
└── dotfiles/                  # Stow packages → symlinked into ~
    ├── git/                   # .gitconfig, .gitconfig.coveo, etc.
    ├── bin/                   # ~/.local/bin scripts (git-recent, git-lg)
    ├── vim/                   # .vimrc, color scheme
    └── shell/                 # .zshrc, .sleep, .wakeup
```

## Adding new dotfiles

1. Create the file in the appropriate stow package (mirror the ~ path)
2. Run `make dotfiles` to symlink it

Example: to track `~/.config/foo/bar.toml`:
```bash
mkdir -p dotfiles/foo/.config/foo
mv ~/.config/foo/bar.toml dotfiles/foo/.config/foo/
make dotfiles
```

## Manual steps

## GPG Keys

Keys are stored in the `backups` drive in iCloud (password protected).

To restore on a new machine:

```bash
# Import the keys
gpg --import /path/to/backups/private-key.asc
gpg --import /path/to/backups/public-key.asc

# Trust the key (set to ultimate trust)
gpg --edit-key 4EFD83FB40FABF3D
# type: trust → 5 → y → quit

# Verify it works
echo "test" | gpg --clearsign

# Tell git to use the GPG agent
echo "pinentry-program /opt/homebrew/bin/pinentry-mac" > ~/.gnupg/gpg-agent.conf
gpgconf --kill gpg-agent
```

Personal signing key: `4EFD83FB40FABF3D`
Coveo signing key: `BC0D1F8B5143DF97`
- iTerm: import profile from `iterm/default-profile-2023.json`
- Desktop backgrounds: https://github.com/samuelfullerthomas/backgrounds

## Sleepwatcher

Turns off Bluetooth on sleep, back on at wake (prevents headphone auto-connect).
Managed via `.sleep` and `.wakeup` scripts + the `sleepwatcher` brew formula.
