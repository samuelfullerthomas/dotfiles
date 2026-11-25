# Notes for agents working on setup-machine

Configures both of Sam's Macs from one branch. `make help` lists the entry points;
`bootstrap.sh` sets up a new Mac. Deliberate decisions, don't silently revert them:

- **One branch, two machines.** Differences go through `MACHINE=work|personal`
  (from `.machine`): the `if work` block in `Brewfile`, the machine column in
  `prefs.list`, and `link.sh` linking `*.coveo` files only on work and `*.personal` only on
  personal (`iterm/com.googlecode.iterm2.<machine>.plist` likewise). Don't create
  per-machine branches; `personal-machine` was one and has been merged back.
- **No `stow --adopt`.** It replaces the repo's file with whatever is on the
  machine. `link.sh` moves conflicting files to `~/.dotfiles-backup/` instead.
- **Always `stow --no-folding`.** Folding made `~/.local` a link into the repo, so
  2 GB of program state (Claude Code, uv, GitKraken) lived in it. Only files we
  wrote belong in `dotfiles/`; `unfold.sh` repairs a folded machine.
- **`doctor.sh` is read-only.** It reports and prints fixes; changes go through
  `make` targets. Add a check there when you add a setting that can drift.
- **`prefs.list` is the single source for macOS defaults**, used by both
  `change-prefs.sh` and `doctor.sh`. Add rows there, not `defaults write` lines.
- **Stock bash 3.2.** `bootstrap.sh`, `doctor.sh` and `lib/common.sh` run before
  Homebrew exists: no associative arrays, `mapfile` or `${var,,}`. Prompts read
  from `/dev/tty` so `curl | bash` works.
- **Two repos, one direction.** Public `samuelfullerthomas/dotfiles` holds
  everything shareable; private `dotfiles-private` is public `main` plus private
  files (`*.coveo`, scripts naming private hosts, work `includeIf` rules). Make
  shareable changes in public, then `git merge upstream-origin/main` into private.
  Never push private `main` to public.
- **No secrets in either repo.** They go in `~/.local-secrets` (mode 600), which
  `.zshrc` sources.

Validate with `make check` (shellcheck plus a dry run of what `make apply` would
change) and `make doctor`.

## Maintaining this file

Keep only what almost every future session needs. Point to files instead of
repeating them, and prune or rewrite entries rather than appending.
