#!/usr/bin/env bash
# Add a work/private git profile.
# Creates ~/.gitconfig.<name> and adds an includeIf block to ~/.gitconfig
# so commits in matching directories use the profile automatically.

set -e

echo "=== Add Git Profile ==="
echo ""

read -rp "Profile name (e.g. 'work', 'client'): " PROFILE_NAME
read -rp "Your name for this profile: " GIT_NAME
read -rp "Your email for this profile: " GIT_EMAIL
read -rp "GPG signing key (leave blank to skip): " SIGNING_KEY
read -rp "Directory to activate this profile (e.g. ~/work/): " WORK_DIR

# Expand ~ in path
WORK_DIR="${WORK_DIR/#\~/$HOME}"
# Ensure trailing slash (required by gitdir includeIf)
[[ "${WORK_DIR}" != */ ]] && WORK_DIR="${WORK_DIR}/"

PROFILE_FILE="$HOME/.gitconfig.${PROFILE_NAME}"
GITCONFIG="$HOME/.gitconfig"

# Write the profile config
cat > "$PROFILE_FILE" <<EOF
[user]
	name = ${GIT_NAME}
	email = ${GIT_EMAIL}
EOF

if [[ -n "$SIGNING_KEY" ]]; then
  cat >> "$PROFILE_FILE" <<EOF
	signingkey = ${SIGNING_KEY}
[commit]
	gpgsign = true
EOF
fi

echo "Created $PROFILE_FILE"

# Add includeIf to ~/.gitconfig if not already present
INCLUDE_BLOCK="[includeIf \"gitdir:${WORK_DIR}\"]\n\tpath = ${PROFILE_FILE}"

if grep -qF "gitdir:${WORK_DIR}" "$GITCONFIG" 2>/dev/null; then
  echo "includeIf for ${WORK_DIR} already exists in $GITCONFIG — skipping."
else
  printf "\n%b\n" "$INCLUDE_BLOCK" >> "$GITCONFIG"
  echo "Added includeIf block to $GITCONFIG"
fi

echo ""
echo "Done. Commits in ${WORK_DIR} will now use ${GIT_EMAIL}."
echo "To also track this profile in your dotfiles, run:"
echo "  cp $PROFILE_FILE ~/setup-machine/dotfiles/git/.gitconfig.${PROFILE_NAME}"
echo "  cd ~/setup-machine && make dotfiles"
