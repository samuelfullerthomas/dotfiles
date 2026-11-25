#!/bin/bash
# Read-only health check of this Mac against the repo: keyboard and other macOS
# defaults, packages, dotfile links, zsh, terminal, git. It changes nothing; each
# problem prints the command that fixes it. Exit code 1 means something failed.
#
#   ./doctor.sh                    (MACHINE from .machine)
#   MACHINE=personal ./doctor.sh
#   ./doctor.sh --no-brew          skip the slower Homebrew checks
#   ./doctor.sh --full-shell       time zsh with its startup hooks (logins, ssh-agent) too
#
# Runs on macOS's stock bash 3.2, so it works before Homebrew is installed.
set -uo pipefail
# shellcheck source=lib/common.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

# Links are checked against the live checkout, so this script can run from another one.
LINKED_DOTFILES="$DOTFILES_DIR"
[ -d "$HOME/setup-machine/dotfiles" ] && LINKED_DOTFILES="$(cd "$HOME/setup-machine/dotfiles" && pwd -P)"
CHECK_BREW=1 FULL_SHELL=0
for arg in "$@"; do
  case "$arg" in
    --no-brew) CHECK_BREW=0 ;;
    --full-shell) FULL_SHELL=1 ;;
    *) echo "usage: doctor.sh [--no-brew] [--full-shell]" >&2; exit 2 ;;
  esac
done
# .zshrc skips onStartup (logins, ssh-agent) when this is set, keeping the doctor read-only.
[ "$FULL_SHELL" = 1 ] || export SETUP_MACHINE_DOCTOR=1

if [ -t 1 ]; then G=$'\033[32m' Y=$'\033[33m' R=$'\033[31m' D=$'\033[2m' B=$'\033[1m' N=$'\033[0m'
else G='' Y='' R='' D='' B='' N=''; fi
FAILS=0 WARNS=0
section() { printf '\n%s%s%s\n' "$B" "$1" "$N"; }
ok()   { printf '  %s✓%s %s\n' "$G" "$N" "$1"; }
warn() { printf '  %s!%s %s\n' "$Y" "$N" "$1"; WARNS=$((WARNS + 1)); }
fail() { printf '  %s✗%s %s\n' "$R" "$N" "$1"; FAILS=$((FAILS + 1)); }
fix()  { printf '    %sfix: %s%s\n' "$D" "$1" "$N"; }
info() { printf '    %s%s%s\n' "$D" "$1" "$N"; }
have() { command -v "$1" >/dev/null 2>&1; }
# Run with a time limit (perl ships with macOS; coreutils timeout may not exist yet).
limit() { local s=$1; shift; perl -e 'alarm shift; exec @ARGV' "$s" "$@"; }

section "Machine"
if resolve_machine 2>/dev/null; then ok "MACHINE=$MACHINE"
else fail "MACHINE not set"; fix "cd $SM_DIR && make machine MACHINE=work|personal"; MACHINE=personal; info "checking as personal"; fi
ok "macOS $(sw_vers -productVersion) on $(uname -m)"
branch="$(git -C "$SM_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null || echo '?')"
dirty="$(git -C "$SM_DIR" status --porcelain -- . 2>/dev/null | wc -l | tr -d ' ')"
case "$branch" in
  personal-machine|coveo-machine) warn "repo is on per-machine branch '$branch'"; fix "merge it into the shared branch; machine differences now go through MACHINE" ;;
  *) ok "repo branch $branch ($dirty uncommitted file(s))" ;;
esac

section "Keyboard and macOS defaults"
while IFS='|' read -r domain key type value label; do
  actual="$(defaults_cmd read "$domain" "$key" 2>/dev/null)" || actual=""
  expected="$value"
  case "$type" in bool) case "$value" in true) expected=1 ;; false) expected=0 ;; esac ;; esac
  same=0
  if [ "$type" = float ] || [ "$type" = int ]; then
    [ -n "$actual" ] && awk -v a="$actual" -v e="$expected" 'BEGIN{exit !(a+0==e+0)}' && same=1
  else
    [ "$actual" = "$expected" ] && same=1
  fi
  if [ "$same" = 1 ]; then
    ok "$label"
  else
    warn "$label: is '${actual:-not set}', want '$expected'"
    flag=""; [ "$domain" != "${domain#currentHost:}" ] && flag="-currentHost "
    fix "defaults ${flag}write ${domain#currentHost:} $key -$type $value"
  fi
done < <(machine_prefs)
for app in com.vscodium com.microsoft.VSCode com.googlecode.iterm2 com.jetbrains.intellij; do
  if [ "$(defaults read "$app" ApplePressAndHoldEnabled 2>/dev/null)" = 1 ]; then
    warn "$app overrides ApplePressAndHoldEnabled=true (accent picker instead of repeat)"
    fix "defaults delete $app ApplePressAndHoldEnabled"
  fi
done
info "keyboard changes need a log out and back in; 'make prefs' applies everything above"

section "Packages"
if have brew; then
  ok "Homebrew $(brew --version | head -1 | awk '{print $2}') at $(brew --prefix)"
  if [ "$CHECK_BREW" = 1 ]; then
    missing="$(HOMEBREW_MACHINE=$MACHINE brew bundle check --file="$SM_DIR/Brewfile" --verbose --no-upgrade 2>/dev/null | grep -E '→|->' | sed -E 's/^[^A-Za-z]*//')"
    if [ -z "$missing" ]; then ok "everything in the Brewfile is installed"
    else warn "$(printf '%s\n' "$missing" | wc -l | tr -d ' ') Brewfile entries missing"; printf '%s\n' "$missing" | sed 's/^/      /' | head -15; fix "make apps"; fi
    # Only what you installed yourself: dependencies of other packages are noise here.
    wanted="$(brew leaves --installed-on-request 2>/dev/null; brew list --cask 2>/dev/null)"
    extra="$(HOMEBREW_MACHINE=$MACHINE brew bundle cleanup --file="$SM_DIR/Brewfile" 2>/dev/null | grep -vE "^(Would|Run)" | sed "/^$/d" | grep -Fxf <(printf "%s\n" "$wanted") || true)"
    if [ -z "$extra" ]; then ok "nothing installed outside the Brewfile"
    else warn "$(printf '%s\n' "$extra" | wc -l | tr -d ' ') installed packages are not in the Brewfile"; printf '%s\n' "$extra" | sed 's/^/      /' | head -15
      fix "add the ones you want to the Brewfile, then: HOMEBREW_MACHINE=$MACHINE brew bundle cleanup --file=$SM_DIR/Brewfile --force"; fi
  fi
else
  fail "Homebrew not installed"; fix "$SM_DIR/bootstrap.sh $MACHINE"
fi
for tool in stow git zsh; do have "$tool" || { fail "$tool not on PATH"; fix "make apps"; }; done

section "Dotfile links"
for pkg in $STOW_PACKAGES; do
  for top in "$DOTFILES_DIR/$pkg"/.[!.]* "$DOTFILES_DIR/$pkg"/*; do
    [ -d "$top" ] || continue
    t="$HOME/$(basename "$top")"
    if [ -L "$t" ] && case "$(cd "$t" 2>/dev/null && pwd -P)" in "$LINKED_DOTFILES"/*) true ;; *) false ;; esac; then
      fail "~/$(basename "$top") is a link into the repo (stow folded it), so runtime files land in the repo"
      fix "run ~/setup-machine/unfold.sh from a plain terminal (not inside Claude Code)"
    fi
  done
  while IFS= read -r rel; do
    rel="${rel#./}"
    machine_skips "$rel" && continue
    t="$HOME/$rel"
    if [ -L "$t" ]; then
      dest="$(readlink "$t")"; case "$dest" in /*) ;; *) dest="$(dirname "$t")/$dest" ;; esac
      if [ "$(cd "$(dirname "$dest")" 2>/dev/null && pwd -P)/$(basename "$dest")" = "$(cd "$(dirname "$LINKED_DOTFILES/$pkg/$rel")" 2>/dev/null && pwd -P)/$(basename "$rel")" ]; then
        ok "~/$rel"
      else
        warn "~/$rel links somewhere else: $(readlink "$t")"; fix "make link"
      fi
    elif [ -e "$t" ]; then
      case "$rel" in */*) case "$(cd "$HOME/${rel%%/*}" 2>/dev/null && pwd -P)" in "$LINKED_DOTFILES"/*) continue ;; esac ;; esac  # inside a folded dir, reported above
      warn "~/$rel is a real file, not linked to the repo"
      if cmp -s "$t" "$DOTFILES_DIR/$pkg/$rel"; then info "same content as the repo"; else info "differs: diff ~/$rel $DOTFILES_DIR/$pkg/$rel"; fi
      fix "make link (backs it up to ~/.dotfiles-backup first)"
    else
      warn "~/$rel missing"; fix "make link"
    fi
  done < <(cd "$DOTFILES_DIR/$pkg" && find . \( -type f -o -type l \) ! -name .DS_Store)
done

section "Shell"
login_shell="$(dscl . -read "/Users/$USER" UserShell 2>/dev/null | awk '{print $2}')"
case "$login_shell" in */zsh) ok "login shell $login_shell" ;; *) fail "login shell is $login_shell"; fix "chsh -s /bin/zsh" ;; esac
if [ -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]; then ok "oh-my-zsh installed"
else fail "oh-my-zsh missing (.zshrc uses it for the theme, plugins and completion)"
  fix 'RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended'; fi
if [ -f "$HOME/.local-secrets" ]; then
  perms="$(stat -f '%Lp' "$HOME/.local-secrets")"
  if [ "$perms" = 600 ]; then ok "~/.local-secrets is private (600)"; else warn "~/.local-secrets is mode $perms"; fix "chmod 600 ~/.local-secrets"; fi
fi
if have zsh; then
  # One timed interactive zsh (stderr kept) and one to see which tools it loads.
  [ "$FULL_SHELL" = 1 ] || info "startup hooks skipped; --full-shell includes them (logins, ssh-agent)"
  errfile="$(mktemp -t doctor-zsh)"
  ms="$(limit 30 zsh -c 'zmodload zsh/datetime; s=$EPOCHREALTIME
    zsh -i -c exit </dev/null >/dev/null 2>"$1"
    printf "%.0f" $(( (EPOCHREALTIME - s) * 1000 ))' _ "$errfile" 2>/dev/null)"
  errors="$(grep -vE '^Now using node|^Agent pid|^Identity added' "$errfile" | head -8)"
  rm -f "$errfile"
  if [ -z "$errors" ]; then ok "interactive zsh starts without errors"
  else warn "interactive zsh writes to stderr on startup (errors, or slow steps worth checking):"; printf '%s\n' "$errors" | sed 's/^/      /'; fi
  if [ -z "$ms" ]; then warn "couldn't time zsh startup"
  elif [ "$ms" -lt 300 ]; then ok "zsh starts in ${ms} ms"
  elif [ "$ms" -lt 800 ]; then warn "zsh starts in ${ms} ms (noticeable)"; fix "profile it: zsh -i -c 'zmodload zsh/zprof; source ~/.zshrc; zprof' | head -30"
  else fail "zsh starts in ${ms} ms (slow)"; fix "profile it: zsh -i -c 'zmodload zsh/zprof; source ~/.zshrc; zprof' | head -30"; fi
  tools="$(limit 20 zsh -i -c 'for t in nvm node pnpm zoxide gh git-lg; do whence $t >/dev/null && print -n "$t:1 " || print -n "$t:0 "; done' </dev/null 2>/dev/null | tail -1)"
  for pair in $tools; do
    if [ "${pair#*:}" = 1 ]; then ok "${pair%%:*} available in zsh"; else warn "${pair%%:*} not available in an interactive zsh"; fi
  done
fi

section "Terminal"
info "this check ran in: ${TERM_PROGRAM:-unknown} (TERM=$TERM)"
iterm_live="$HOME/Library/Preferences/com.googlecode.iterm2.plist"
iterm_repo="$SM_DIR/iterm/com.googlecode.iterm2.plist"
[ -f "$SM_DIR/iterm/com.googlecode.iterm2.$MACHINE.plist" ] && iterm_repo="$SM_DIR/iterm/com.googlecode.iterm2.$MACHINE.plist"
if [ -d /Applications/iTerm.app ]; then
  ok "iTerm2 installed"
  if [ "$(defaults read com.googlecode.iterm2 LoadPrefsFromCustomFolder 2>/dev/null)" = 1 ]; then
    ok "iTerm loads preferences from $(defaults read com.googlecode.iterm2 PrefsCustomFolder 2>/dev/null)"
  else
    info "iTerm uses its own preferences, not the repo's (Settings > General > Settings > Load from a custom folder)"
  fi
  for field in "Normal Font" "Columns" "Rows" "Option Key Sends" "Unlimited Scrollback"; do
    live="$(/usr/libexec/PlistBuddy -c "Print ':New Bookmarks:0:$field'" "$iterm_live" 2>/dev/null)"
    want="$(/usr/libexec/PlistBuddy -c "Print ':New Bookmarks:0:$field'" "$iterm_repo" 2>/dev/null)"
    [ -z "$want" ] && continue
    if [ "$live" = "$want" ]; then ok "iTerm default profile $field: $live"
    else warn "iTerm default profile $field is '${live:-unset}', repo has '$want'"; fi
  done
  font="$(/usr/libexec/PlistBuddy -c "Print ':New Bookmarks:0:Normal Font'" "$iterm_live" 2>/dev/null | sed 's/ [0-9.]*$//')"
  if [ -n "$font" ]; then
    if [ "$(osascript -l JavaScript -e "ObjC.import('AppKit'); \$.NSFont.fontWithNameSize('$font', 12).isNil() ? 'no' : 'yes'" 2>/dev/null)" = yes ]; then
      ok "font $font is installed"
    else
      fail "iTerm font $font is not installed, so iTerm falls back to another font"
    fi
  fi
else
  warn "iTerm2 not installed"; fix "make apps"
fi

section "Git and SSH"
email="$(git config --global user.email 2>/dev/null)"
if [ -n "$email" ]; then ok "git user.email $email"; else fail "git user.email not set"; fix "make link"; fi
key="$(git config --global user.signingkey 2>/dev/null)"
if [ -n "$key" ] && [ "$(git config --global commit.gpgsign)" = true ]; then
  if have gpg && gpg --list-secret-keys "$key" >/dev/null 2>&1; then ok "GPG signing key $key available"
  else fail "commits are signed with $key, but that secret key isn't in gpg (commits will fail)"; fix "import the key, or set commit.gpgsign=false"; fi
fi
if [ "$MACHINE" = work ]; then
  if [ -f "$HOME/.gitconfig.coveo" ]; then ok "~/.gitconfig.coveo present"; else warn "~/.gitconfig.coveo missing (work identity)"; fi
fi
if [ -f "$HOME/.ssh/id_ed25519" ]; then ok "SSH key ~/.ssh/id_ed25519"; else warn "no ~/.ssh/id_ed25519"; fix "$SM_DIR/bootstrap.sh $MACHINE"; fi
if grep -q "Host github.com" "$HOME/.ssh/config" 2>/dev/null; then ok "~/.ssh/config has a github.com entry"; else warn "~/.ssh/config has no github.com entry"; fi

printf '\n%s%d failed, %d warnings%s\n' "$B" "$FAILS" "$WARNS" "$N"
[ "$FAILS" = 0 ]
