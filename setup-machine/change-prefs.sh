#!/bin/bash
# Applies macOS preferences: every row of prefs.list for this MACHINE, then the
# few settings `defaults` can't express. Safe to rerun.
set -euo pipefail
# shellcheck source=lib/common.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
resolve_machine

while IFS='|' read -r domain key type value label; do
  echo "  $label"
  [ "$key" = location ] && [ "$domain" = com.apple.screencapture ] && mkdir -p "$value"
  defaults_cmd write "$domain" "$key" "-$type" "$value"
done < <(machine_prefs)

# Not expressible as defaults rows.
sudo nvram SystemAudioVolume=" "   # no boot chime
chflags nohidden ~/Library
sudo chflags nohidden /Volumes
defaults write com.google.Chrome.canary AppleEnableSwipeNavigateWithScrolls -bool false
defaults write com.google.Chrome.canary AppleEnableMouseSwipeNavigateWithScrolls -bool false
# Safari is sandboxed: these only take effect if the terminal has Full Disk Access.
defaults write com.apple.Safari UniversalSearchEnabled -bool false 2>/dev/null || true
defaults write com.apple.Safari SuppressSearchSuggestions -bool true 2>/dev/null || true
defaults write com.apple.Safari IncludeDevelopMenu -bool true 2>/dev/null || true

killall Dock Finder SystemUIServer 2>/dev/null || true
echo "Done. Log out and back in for keyboard repeat changes to take effect."
