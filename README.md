# Dotfiles

Setup for my two Macs (work and personal) with Homebrew, GNU Stow and a Makefile.
`setup-machine/AGENTS.md` lists the design decisions.

## New Mac

```bash
curl -fsSL https://raw.githubusercontent.com/samuelfullerthomas/dotfiles/main/setup-machine/bootstrap.sh | bash -s personal   # or work
```

It installs Xcode tools and Homebrew, makes an SSH key and waits for you to add it
to GitHub, checks the repo out into `~`, then runs `make apply` and `make doctor`.
Every step checks first, so it's safe to rerun. By default it clones the private
repo (see below); `DOTFILES_REPO=<url>` clones another.

## Day to day

Edit files in `setup-machine/`, then:

| Command | What it does |
|---|---|
| `make apply` | `make apps` + `make link` + `make prefs` |
| `make apps` | `brew bundle` from `Brewfile` |
| `make link` | Link `dotfiles/*` into `~` (`link.sh`) |
| `make prefs` | macOS defaults from `prefs.list` (`change-prefs.sh`) |
| `make check` | shellcheck, plus what `make apply` would change |
| `make doctor` | Read-only health check: key repeat, links, zsh startup time, iTerm, git and SSH |
| `make machine MACHINE=work\|personal` | Remember which Mac this is (`.machine`, not committed) |

## Work and personal

One branch serves both Macs. `MACHINE` picks the differences:

- `Brewfile`: the `if work` / `unless work` blocks.
- `prefs.list`: the first column is `all`, `work` or `personal`.
- `dotfiles/`: `*.coveo` files are linked only on work, `*.personal` only on personal.

## Linking

`link.sh` runs `stow --no-folding`, so each file is its own link and directories
like `~/.local` stay real. A file already in `~` is moved to
`~/.dotfiles-backup/<time>/`, never overwritten (no `stow --adopt`). If an older
setup folded a directory into the repo, `make link` refuses and `./unfold.sh`
repairs it; run that from a plain terminal.

To track a new file, put it in a stow package at its path under `~`, then `make link`:

```bash
mkdir -p setup-machine/dotfiles/foo/.config/foo
mv ~/.config/foo/bar.toml setup-machine/dotfiles/foo/.config/foo/
```

New packages also go in `STOW_PACKAGES` in `lib/common.sh`.

## Private repo

`dotfiles-private` is this repo plus private files: work config (`*.coveo`, git
`includeIf` rules) and scripts that name private hosts. Its `main` has this repo
as the `upstream-origin` remote:

```bash
# shareable change: commit it here first, then in the private checkout
git fetch upstream-origin && git merge upstream-origin/main
```

Changes only flow from public to private. Never push the private `main` here.
Secrets go in neither repo: `~/.local-secrets` (mode 600) is sourced by `.zshrc`.

## Git profiles

`.gitconfig` uses `includeIf "gitdir:..."` to switch identity per directory.
`./add-work-profile.sh` creates `~/.gitconfig.<profile>` and adds the include.



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
