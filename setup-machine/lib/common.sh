#!/bin/bash
# Shared helpers. Must run on macOS's stock bash 3.2: bootstrap and doctor run
# before Homebrew exists.

SM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
# shellcheck disable=SC2034 # used by the scripts that source this
DOTFILES_DIR="$SM_DIR/dotfiles"
# shellcheck disable=SC2034
STOW_PACKAGES="git bin vim shell"

# MACHINE, not HOST: zsh already uses $HOST for the hostname.
resolve_machine() {
  if [ -z "${MACHINE:-}" ] && [ -f "$SM_DIR/.machine" ]; then
    MACHINE="$(tr -d '[:space:]' < "$SM_DIR/.machine")"
  fi
  case "${MACHINE:-}" in
    work|personal) export MACHINE HOMEBREW_MACHINE="$MACHINE" ;;
    *)
      echo "MACHINE must be 'work' or 'personal' (got '${MACHINE:-}')." >&2
      echo "Set it once with: make machine MACHINE=personal" >&2
      return 1
      ;;
  esac
}

# *.coveo files only belong on the work machine, *.personal on the personal one.
machine_skips() {
  local rel=$1
  case "$MACHINE:$rel" in personal:*.coveo|work:*.personal) return 0 ;; esac
  return 1
}

# Prints "domain|key|type|value|label" for every pref that applies to MACHINE.
machine_prefs() {
  local machine domain key type value label
  while IFS='|' read -r machine domain key type value label; do
    case "$machine" in ''|'#'*) continue ;; esac
    [ "$machine" = all ] || [ "$machine" = "$MACHINE" ] || continue
    value="${value/#\~/$HOME}"
    printf '%s|%s|%s|%s|%s\n' "$domain" "$key" "$type" "$value" "$label"
  done < "$SM_DIR/prefs.list"
}

# defaults wrapper that understands the "currentHost:" domain prefix.
defaults_cmd() {
  local verb=$1 domain=$2
  shift 2
  case "$domain" in
    currentHost:*) defaults -currentHost "$verb" "${domain#currentHost:}" "$@" ;;
    *) defaults "$verb" "$domain" "$@" ;;
  esac
}
