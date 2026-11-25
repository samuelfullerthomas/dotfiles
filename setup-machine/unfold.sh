#!/bin/bash
# One-off repair for directories stow "folded": ~/.local or ~/.vim being a link
# into the repo, so everything programs write there (Claude Code, uv, GitKraken,
# vim state...) lives in setup-machine/dotfiles. Each one is moved back to ~ as a
# real directory, then only the tracked files are linked.
#
# Run it from a plain terminal, not inside Claude Code or Kiro: for a moment
# ~/.local doesn't exist, and their binaries live there.
set -euo pipefail
# shellcheck source=lib/common.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
resolve_machine

if [ -n "${CLAUDECODE:-}" ]; then
  echo "Refusing to run inside Claude Code; use a plain terminal." >&2
  exit 1
fi

real_dir() { (cd "$1" 2>/dev/null && pwd -P); }

# On failure, put the directory back in the repo and the link back in ~. Never
# deletes: anything in the way is moved aside with a .partial suffix.
rollback() {
  trap - ERR
  set +e
  if [ -d "$link" ] && [ ! -L "$link" ]; then
    [ -e "$top" ] && mv "$top" "$top.partial.$$"
    mv "$link" "$top" && ln -s "$dest" "$link"
    git -C "$SM_DIR" checkout -- "dotfiles/$pkg/$name" 2>/dev/null
  elif [ ! -e "$link" ] && [ -d "$top" ]; then
    ln -s "$dest" "$link"
  fi
  echo "Failed while moving ~/$name; put it back as it was. Nothing was deleted." >&2
  exit 1
}
repo_dotfiles="$(real_dir "$DOTFILES_DIR")"
moved=0

for pkg in $STOW_PACKAGES; do
  for top in "$DOTFILES_DIR/$pkg"/.[!.]* "$DOTFILES_DIR/$pkg"/*; do
    [ -d "$top" ] || continue
    name="$(basename "$top")"
    link="$HOME/$name"
    [ -L "$link" ] || continue
    dest="$(readlink "$link")"
    case "$dest" in /*) ;; *) dest="$HOME/$dest" ;; esac
    if [ "$(real_dir "$dest")" != "$(real_dir "$top")" ]; then
      echo "~/$name points at $dest, not into this repo. Leaving it alone." >&2
      continue
    fi
    case "$(real_dir "$top")" in "$repo_dotfiles"/*) ;; *) continue ;; esac

    echo "Moving dotfiles/$pkg/$name back to ~/$name ($(du -sh "$top" | cut -f1))"
    trap rollback ERR
    rm "$link"
    mv "$top" "$link"
    # The move took the tracked files with it: restore them in the repo, then
    # remove the identical copies in ~ so stow can link them.
    git -C "$SM_DIR" checkout -- "dotfiles/$pkg/$name"
    while IFS= read -r rel; do
      rel="${rel#./}"
      if [ -f "$HOME/$rel" ] && [ ! -L "$HOME/$rel" ] && cmp -s "$HOME/$rel" "$DOTFILES_DIR/$pkg/$rel"; then
        rm "$HOME/$rel"
      fi
    done < <(cd "$DOTFILES_DIR/$pkg" && find "./$name" -type f)
    trap - ERR
    moved=$((moved + 1))
  done
done

if [ "$moved" = 0 ]; then
  echo "No folded directories; nothing to do."
  exit 0
fi
"$SM_DIR/link.sh"
echo "Done. Check with: ls -ld ~/.local ~/.vim"
