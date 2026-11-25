#!/bin/bash
# Links dotfiles/<package>/* into ~ with stow, one file at a time.
# A file already in ~ that isn't our link is moved to ~/.dotfiles-backup/<time>/
# first, so the repo's version wins and nothing is lost (no `stow --adopt`).
#
#   ./link.sh            back up conflicts, then link
#   ./link.sh --dry-run  print what would happen, change nothing
set -euo pipefail
# shellcheck source=lib/common.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
resolve_machine

DRY_RUN=0
[ "${1:-}" = --dry-run ] && DRY_RUN=1
BACKUP_DIR=""  # created on first conflict, unique per run

real() { (cd "$(dirname "$1")" 2>/dev/null && printf '%s/%s\n' "$(pwd -P)" "$(basename "$1")"); }
# Where a symlink points, as a physical path (empty if its directory is gone).
link_dest() {
  local dest
  dest="$(readlink "$1")"
  case "$dest" in /*) ;; *) dest="$(dirname "$1")/$dest" ;; esac
  real "$dest"
}

# A directory in ~ that is itself a link into the repo means stow "folded" it, and
# everything programs write there lands in the repo. Refuse rather than unstow it.
folded=""
for pkg in $STOW_PACKAGES; do
  for top in "$DOTFILES_DIR/$pkg"/.[!.]* "$DOTFILES_DIR/$pkg"/*; do
    [ -d "$top" ] || continue
    target="$HOME/$(basename "$top")"
    if [ -L "$target" ] && case "$(link_dest "$target")" in "$DOTFILES_DIR"/*) true ;; *) false ;; esac; then
      folded="$folded $target"
    fi
  done
done
if [ -n "$folded" ]; then
  echo "These directories are links into the repo (stow folded them):$folded" >&2
  echo "Run ./unfold.sh outside Claude Code first, then rerun this." >&2
  exit 1
fi

conflicts=0
for pkg in $STOW_PACKAGES; do
  while IFS= read -r rel; do
    rel="${rel#./}"
    machine_skips "$rel" && continue
    target="$HOME/$rel"
    source_file="$DOTFILES_DIR/$pkg/$rel"
    if [ -L "$target" ]; then
      [ "$(link_dest "$target")" = "$(real "$source_file")" ] && continue
    elif [ ! -e "$target" ]; then
      continue
    fi
    conflicts=$((conflicts + 1))
    if [ "$DRY_RUN" = 1 ]; then
      echo "would back up: ~/$rel"
    else
      if [ -z "$BACKUP_DIR" ]; then
        mkdir -p "$HOME/.dotfiles-backup"
        BACKUP_DIR="$(mktemp -d "$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)-XXXX")"
      fi
      mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
      mv "$target" "$BACKUP_DIR/$rel"
      echo "backed up: ~/$rel -> $BACKUP_DIR/$rel"
    fi
  done < <(cd "$DOTFILES_DIR/$pkg" && find . \( -type f -o -type l \) ! -name .DS_Store)
done

ignore=()
case "$MACHINE" in personal) ignore=(--ignore='\.coveo$') ;; work) ignore=(--ignore='\.personal$') ;; esac
# shellcheck disable=SC2086
if [ "$DRY_RUN" = 1 ]; then
  echo "$conflicts file(s) would be backed up. Stow plan:"
  status=0
  plan="$(stow --no-folding --simulate --verbose=1 --dir="$DOTFILES_DIR" --target="$HOME" "${ignore[@]+"${ignore[@]}"}" $STOW_PACKAGES 2>&1)" || status=$?
  printf "%s\n" "$plan" | grep -v "^WARNING: in simulation mode" || true
  exit "$status"
else
  stow --no-folding --restow --dir="$DOTFILES_DIR" --target="$HOME" "${ignore[@]+"${ignore[@]}"}" $STOW_PACKAGES
  echo "Linked: $STOW_PACKAGES ($MACHINE)"
fi
