
SSH_ENV="$HOME/.ssh/environment"
[[ -r "/usr/local/etc/profile.d/bash_completion.sh" ]] && . "/usr/local/etc/profile.d/bash_completion.sh"
[[ -s "$HOME/.gvm/scripts/gvm" ]] && source "$HOME/.gvm/scripts/gvm"

# Load local secrets (not committed to version control)
[[ -f "$HOME/.local-secrets" ]] && source "$HOME/.local-secrets"

# path
export PATH=$HOME/bin:/usr/local/bin:$HOME/.cargo/bin:/usr/local/sbin:$HOME/.local/bin:$PATH
export ZSH_DISABLE_COMPFIX=true
# path to oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh
# path to pnpm bin
export PATH="$HOME/Library/pnpm:$PATH"

export HUSKY_ENABLED=1 
export HUSKY_TESTS_ENABLED=1

# theme
ZSH_THEME="cloud"

# GPG stuff
# https://github.com/keybase/keybase-issues/issues/2798
export GPG_TTY=$(tty)

# source ZSH
source $ZSH/oh-my-zsh.sh

# source koviro wrapper
source ~/coveo-platform/koviro/scripts/koviro.sh

# source iterm integration (conditional load is at end of file)
# source ~/.iterm2_shell_integration.zsh

# ssh
export SSH_KEY_PATH="$HOME/.ssh/rsa_id"

# XDG base directory
export XDG_DATA_HOME="$HOME/.local/share"

# java
export CPPFLAGS="-I/usr/local/opt/openjdk@11/include"

# turbo
export TURBO_NO_UPDATE_NOTIFIER=true

# coveo token (lazy loaded - call coveo_token to set it)
coveo_token() {
  export COVEO_TOKEN=$(coveo config:get accessToken | jq -r .accessToken)
  echo "COVEO_TOKEN set"
}

# functions
function repeatspeed () {
  defaults write NSGlobalDomain KeyRepeat -int $1
  echo "hows that speed for ya."
}

function gh-checks-watch () {
  gh pr checks --watch --fail-fast
}

function killport () {
  lsof -i TCP:$1 | grep LISTEN | awk '{print $2}' | xargs kill -9
  echo "He's dead Jim."
}

function killp () {
  pgrep "$1" | xargs sudo kill -9
  pgrep "$1"
  echo "so much blood."
}

function git-temp-ignore () {
  git update-index --skip-worktree $1
  echo "ignoring $1."
}

function git-temp-unignore () {
  git update-index --no-skip-worktree $1
  echo "no longer ignoring $1."
}

function gcom() {
  main_branch_name=`git remote show origin | grep 'HEAD branch' | cut -d' ' -f5`;
  git checkout $main_branch_name
}

function openpr() {
  if ! gh --version >/dev/null 2>&1; then
    brew install gh
  fi

  if ! gh auth status >/dev/null 2>&1; then
    gh auth login
  fi

  if ! gh pr view --web >/dev/null 2>&1; then
    github_url=`git remote -v | awk '/fetch/{print $2}' | sed -Ee 's#(git@|git://)#https://#' -e 's@com:@com/@' -e 's%\.git$%%' | awk '/github/'`;
    branch_name=`git symbolic-ref HEAD | cut -d"/" -f 3,4`;
    main_branch_name=`git remote show origin | grep 'HEAD branch' | cut -d' ' -f5`;
    
    # Only add commerce template for admin-ui repo
    template_param=""
    if [[ "$github_url" == *"admin-ui"* ]]; then
      template_param="&template=commerce.md&labels=compliance-check,run-e2e"
    fi
    
    pr_url=$github_url"/compare/"$main_branch_name"..."$branch_name"?quick_pull=1"$template_param
    echo -n $branch_name | pbcopy
    open $pr_url;
    if [[ "$github_url" == *"admin-ui"* ]]; then
      echo "⚠️  Remember to add reviewer: gh pr edit <number> --add-reviewer coveo-platform/commerce-group-3"
    fi
    return
  fi
}

function ape() {
  git push -u && openpr
}

function openjira () {
  ticket=`git rev-parse --abbrev-ref HEAD`
  open https://coveord.atlassian.net/browse/$ticket
}

function grephelp() {
  echo "Before: -B: ex: grep -B 4 'keyword' /path/to/file.log"
  echo "After: -A: ex: grep -A 4 'keyword' /path/to/file.log"
}

function grepp() {
  grep -B $1 -A $1 $2 $3
}

function catp() {
  if [ $# -eq 0 ]; then
    echo 'catp usage: catp <term> [padding lines]'
    return 1
  elif [ $# -eq 2 ]; then
    grep -B $2 -A $2 $1 ./package.json
    return
  fi
  grep $1 ./package.json
}

function background() {
  eval "$@" > /tmp/background-$$.log 2>&1 &
  echo "Running in background (PID $!). Log: /tmp/background-$$.log"
}

function reload() {
  source ~/.zshrc
}

getCodeArtifactToken() {
  local registry_without_protocol="//coveo-021891587241.d.codeartifact.us-east-1.amazonaws.com/npm/development/"
  local domain owner
  domain=$(echo "$registry_without_protocol" | sed -n 's|//\([a-zA-Z0-9_]*\)-\([0-9]*\)\..*|\1|p')
  owner=$(echo "$registry_without_protocol" | sed -n 's|//\([a-zA-Z0-9_]*\)-\([0-9]*\)\..*|\2|p')
  token=$(aws codeartifact get-authorization-token --region us-east-1 --domain "$domain" --domain-owner "$owner" --query authorizationToken --output text)
  npm config set ${registryWithoutProtocol}:_authToken=${token}
}

# ===== Utility Functions =====

# Make directory and cd into it
mkcd() {
  mkdir -p "$1" && cd "$1"
}

# Quick file search by name
ff() {
  find . -name "*$1*" 2>/dev/null
}

# Universal archive extractor
extract() {
  if [[ -z "$1" ]]; then
    echo "Usage: extract <archive>"
    return 1
  fi
  if [[ ! -f "$1" ]]; then
    echo "'$1' is not a valid file"
    return 1
  fi
  case "$1" in
    *.tar.bz2) tar xjf "$1" ;;
    *.tar.gz)  tar xzf "$1" ;;
    *.tar.xz)  tar xJf "$1" ;;
    *.bz2)     bunzip2 "$1" ;;
    *.rar)     unrar x "$1" ;;
    *.gz)      gunzip "$1" ;;
    *.tar)     tar xf "$1" ;;
    *.tbz2)    tar xjf "$1" ;;
    *.tgz)     tar xzf "$1" ;;
    *.zip)     unzip "$1" ;;
    *.Z)       uncompress "$1" ;;
    *.7z)      7z x "$1" ;;
    *)         echo "'$1' cannot be extracted via extract()" ;;
  esac
}

# Git stash with a message
gss() {
  if [[ -z "$1" ]]; then
    echo "Usage: gss <stash message>"
    return 1
  fi
  git stash push -m "$1"
}

# Create directory and cd, or clone git repo and cd
take() {
  if [[ $1 =~ ^(https?|git).*\.git$ ]]; then
    git clone "$1" && cd "$(basename "$1" .git)"
  else
    mkcd "$1"
  fi
}

# Show listening ports
ports() {
  lsof -iTCP -sTCP:LISTEN -n -P
}

# Quick weather check
weather() {
  local city="${1:-}"
  curl -s "wttr.in/${city}?format=3"
}

function checknode () {
  if [[ -f ./package.json ]]; then
    nodeversion=$(ggrep -oP '"node": "[><=~]{0,2}([0-9]{2})' package.json | ggrep -oP '[0-9]{2}')
    if [[ -n "$nodeversion" ]]; then
      current_version=$(node -v 2>/dev/null | sed 's/v//' | cut -d. -f1)
      if [[ "$current_version" != "$nodeversion" ]]; then
        echo "Switching from Node v$current_version to v$nodeversion"
        nvm use $nodeversion
      fi
    fi
  fi
}

# automatically use node version
function cd() {
  builtin cd "$@"
  
  if [[ -f .nvmrc ]]; then
    nvmrc_version=$(cat .nvmrc | tr -d '\n')
    current_version=$(node -v 2>/dev/null | sed 's/v//')
    if [[ "$current_version" != "$nvmrc_version" ]]; then
      echo "Switching from Node v$current_version to v$nvmrc_version (from .nvmrc)"
      nvm use
    fi
  else
    checknode
  fi
}

function start_agent {
    echo "Initialising new SSH agent..."
    /usr/bin/ssh-agent | sed 's/^echo/#echo/' > "${SSH_ENV}"
    echo succeeded
    chmod 600 "${SSH_ENV}"
    . "${SSH_ENV}" > /dev/null
    /usr/bin/ssh-add;
}

# coveo
coveo_prepare() {
  # login to aws sso & export credentials
  aws sso login
  # cd into the admin-ui directory
  cd ~/coveo-platform/admin-ui
  # stash current changes
  BRANCH_NAME=$(git branch --show-current)
  git add .
  git stash
  # switch to master branch
  git checkout master
  # pull latest changes
  git pull
  # install dependencies & build
  pnpm install
  pnpm run build
  pnpm run type-check --force
  # switch back to original branch
  git checkout $BRANCH_NAME
  git stash pop
}

coveo_login () {
  local token_file="$HOME/.aws/token_age"
  local max_age=$((8 * 60 * 60))  # 8 hours in seconds
  local needs_login=false

  # Check if token file exists and is within 8 hours
  if [[ -f "$token_file" ]]; then
    local token_time=$(cat "$token_file")
    local current_time=$(date +%s)
    local age=$((current_time - token_time))
    if [[ $age -ge $max_age ]]; then
      echo "AWS token is older than 8 hours. Logging in..."
      needs_login=true
    else
      local remaining=$(((max_age - age) / 60))
      echo "AWS token is valid. ${remaining} minutes remaining."
    fi
  else
    echo "No token timestamp found. Logging in..."
    needs_login=true
  fi

  if [[ "$needs_login" == true ]]; then
    aws sso login
    # Record login timestamp
    date +%s > "$token_file"
  fi
}

# iterm
iterm2_print_user_vars() {
  iterm2_set_user_var profile "$(git config user.email)"
  iterm2_set_user_var gitBranch "$(git branch 2> /dev/null | grep \* | cut -c3-)"
}

# PS1 (prompt)
parse_git_branch() {
  hasmod=""
  if [[ `git ls-files -dmo --exclude-standard 2> /dev/null` ]]; then
    hasmod="*"
  fi
  git branch 2> /dev/null | sed -e '/^[^*]/d' -e "s/* \(.*\)/(\1$hasmod)/"
}

function onStartup {
  # Source SSH settings, if applicable
  if [[ -f "${SSH_ENV}" ]]; then
      . "${SSH_ENV}" > /dev/null
      #ps ${SSH_AGENT_PID} doesn't work under cywgin
      ps -ef | grep ${SSH_AGENT_PID} | grep ssh-agent$ > /dev/null || {
          start_agent;
      }
  else
      start_agent;
  fi
  # jf cvo update
  nvm use default
  getCodeArtifactToken

  # local max_age=$((24 * 60 * 60))  # 24 hours in seconds
  # local should_update=false

  #   local current_time=$(date +%s)
  #   local age=$((current_time - last_update))
  #   if [[ $age -ge $max_age ]]; then
  #     should_update=true
  #   fi
  # else
  #   should_update=true
  # fi

  # if [[ "$should_update" == true ]]; then
  # fi

  coveo_login
  getCodeArtifactToken
}

# aliases
alias zsh-aliases="grep alias ~/.zshrc"
alias zsh-functions="grep function ~/.zshrc"
alias zsh="codium ~/.zshrc"
alias zshrc="codium ~/.zshrc"
alias help="echo 'try the command zsh-aliases to show you available aliases, or zsh-functions to show you available functions\ntry entering env to see environment variables'"
alias code="codium"
alias kiro-cli-trust="kiro-cli chat --trust-all-tools"
alias pn="pnpm"
alias pnx="pnpx"
alias killchromium="pgrep Chromium | xargs kill -9"
alias clean-docker='docker system prune -a'
alias clean-coveo='~/coveo-platform/commerce-service/scripts/createcatalog.py && ~/coveo-platform/commerce-service/scripts/createsource.py  && ~/coveo-platform/commerce-service/scripts/ft-testorg.py && ~/coveo-platform/commerce-service/scripts/setup-testorg.py'

alias gco="git checkout"
alias gp="git push"
alias gpo="git push -u"
alias gcam="git commit -a -m"

# git
# Show last X commits (default 10)
glog () {
  local number_of_commits="${1:-10}"
  git log --oneline --graph --decorate -"$number_of_commits"
}

# kiro 
kiro-cli-create-worktree () {
  local new_branch=$1
  if [[ -z "$new_branch" ]]; then
    echo "❌ Usage: kiro-cli-create-worktree <worktree-branch-name>"
    return 1
  fi

  # Must be in a git repo
  repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || { echo "Not in a git repo"; return 1; }

  base_branch=$(git remote show origin 2>/dev/null | sed -n '/HEAD branch/s/.*: //p')
  base_branch=${base_branch:-master}
  wt_dir="$repo_root/.worktrees/$new_branch"

  git worktree add -b "$new_branch" "$wt_dir" "$base_branch" --quiet
  echo "Worktree: $wt_dir"
  echo "Branch:   $new_branch (based on $base_branch)"
  echo ""
  echo "When done, push and open a PR:"
  echo "  cd $wt_dir && git push -u origin $new_branch"

  cd "$wt_dir"
}

kiro-cli-create-workspace-feature() {
  local FEATURE_NAME=$1
  if [[ -z "$FEATURE_NAME" ]]; then
    echo "❌ Usage: kiro-cli-create-workspace-feature <feature-branch-name>"
    return 1
  fi

  local SRC_WORKSPACE="$HOME/coveo-platform/copilot"
  local META_DIR="$HOME/workspaces/$FEATURE_NAME"

  if [[ ! -d "$META_DIR" ]]; then
    echo "🚀 Creating meta-workspace: $META_DIR"
    mkdir -p "$META_DIR"

    for repo_path in "$SRC_WORKSPACE"/*/; do
      if [[ -d "$repo_path/.git" ]] || [[ -f "$repo_path/.git" ]]; then
        local repo_name=$(basename "$repo_path")
        local target_wt="$META_DIR/$repo_name"

        git -C "$repo_path" fetch --quiet
        local base_branch=$(git -C "$repo_path" remote show origin 2>/dev/null | sed -n '/HEAD branch/s/.*: //p')
        base_branch=${base_branch:-master}

        echo "🌿 [$repo_name] worktree on $FEATURE_NAME (from $base_branch)"
        git -C "$repo_path" worktree add -b "$FEATURE_NAME" "$target_wt" "origin/$base_branch" --quiet 2>/dev/null || \
        git -C "$repo_path" worktree add "$target_wt" "$FEATURE_NAME" --quiet 2>/dev/null

        if [[ ! -d "$target_wt" ]]; then
          echo "  ⚠️  Failed to create worktree for $repo_name"
        fi
      fi
    done
    cp -r "$SRC_WORKSPACE/.kiro" "$META_DIR/.kiro/";
  else
    echo "🔄 Meta-folder found. Resuming..."
  fi

  if ! tmux has-session -t "$FEATURE_NAME" 2>/dev/null; then
    echo "📦 Starting tmux session..."
    tmux new-session -d -s "$FEATURE_NAME" -c "$META_DIR"
    tmux send-keys -t "$FEATURE_NAME" "kiro-cli chat --trust-all-tools" C-m
  fi

  tmux attach-session -t "$FEATURE_NAME"
}

launch-kiro-feature-cleanup() {
  local FEATURE_NAME=$1
  if [[ -z "$FEATURE_NAME" ]]; then
    echo "❌ Usage: launch-kiro-feature-cleanup <feature-branch-name>"
    return 1
  fi

  local SRC_WORKSPACE="$HOME/coveo-platform/copilot"
  local META_DIR="$HOME/workspaces/$FEATURE_NAME"

  # Kill tmux session
  if tmux has-session -t "$FEATURE_NAME" 2>/dev/null; then
    tmux kill-session -t "$FEATURE_NAME"
    echo "🔪 Killed tmux session: $FEATURE_NAME"
  fi

  # Remove worktrees and optionally delete branches
  for repo_path in "$SRC_WORKSPACE"/*/; do
    if [[ -d "$repo_path/.git" ]] || [[ -f "$repo_path/.git" ]]; then
      local repo_name=$(basename "$repo_path")
      local target_wt="$META_DIR/$repo_name"

      if [[ -d "$target_wt" ]]; then
        git -C "$repo_path" worktree remove "$target_wt" --force 2>/dev/null
        echo "🧹 [$repo_name] worktree removed"
      fi
    fi
  done

  # Remove meta directory
  if [[ -d "$META_DIR" ]]; then
    rm -rf "$META_DIR"
    echo "🗑️  Removed $META_DIR"
  fi

  echo "✅ Cleanup complete for: $FEATURE_NAME"
}


alias override-screenshots-folder='echo "defaults write com.apple.screencapture location <path here>"'
alias delete-mail='echo "d *" | mail -N'
alias git-lastme="git for-each-ref --format=' %(authorname) %09 %(refname) %(committerdate)' --sort=authorname --sort=-committerdate | grep \"\$(git config user.name)\" --max-count 10 | sed -E 's/.*refs\/(tags|heads|remotes\/origin)\/([^ ]+).*/\2/' | uniq"
alias mv-npmrc='mv ~/.npmrc ~/.npmrc-temp'
alias mvb-npmrc='mv ~/.npmrc-temp ~/.npmrc'

alias nap="/opt/homebrew/bin/blueutil -p 0 && /bin/sleep 2 && /usr/bin/pmset sleepnow"
alias lock="/opt/homebrew/bin/blueutil -p 0 && /bin/sleep 2 && /usr/bin/pmset sleepnow"

# docker
alias docker-cleanup='brew cleanup && docker system prune'

# ruby
eval "$(rbenv init -)"

# go
export GOPATH="$HOME/go"

# prompt display
export PS1="%~%{%F{green}%} \$(parse_git_branch) $ %{%F{white}%}"
# %T	System time (HH:MM).
# %*	System time (HH:MM:SS).
# %D	System date (YY-MM-DD).
# %n	Current username.
# %B - %b	Begin - end bold print.
# %U - %u	Begin - end underlining.
# %d	The current working directory.
# %~	The current working directory, relative to the home directory.
# %M	The computer's hostname.
# %m	The computer's hostname (truncated before the first period).
# %l	The current tty.

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

export PATH="$GOPATH/bin:$PATH"
export PATH="$HOME/.dotnet/tools:$PATH"
export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"
# export PATH="$HOME/Library/Python/3.9/bin:$PATH"
export PATH="/opt/homebrew/opt/python@3.14/libexec/bin:$PATH"

# nvm
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
export PATH="/usr/local/opt/openjdk@11/bin:$PATH"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# pnpm
export PNPM_HOME="/Users/samuel/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME/bin:"*) ;;
  *) export PATH="$PNPM_HOME/bin:$PATH" ;;
esac
# pnpm end


# call startup function
onStartup
# The following lines have been added by Docker Desktop to enable Docker CLI completions.
fpath=(/Users/samuel/.docker/completions $fpath)
autoload -Uz compinit
compinit
# End of Docker CLI completions
export PATH="/opt/homebrew/opt/openjdk@21/bin:$PATH"

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/samuel/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/samuel/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/samuel/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/samuel/google-cloud-sdk/completion.zsh.inc'; fi

# zoxide - smarter cd command (install with: brew install zoxide)
# Use 'z' to jump to directories, e.g., 'z admin' -> ~/coveo-platform/admin-ui
eval "$(zoxide init zsh)"


. "$HOME/.local/share/../bin/env"

# bun completions
[ -s "/Users/samuel/.bun/_bun" ] && source "/Users/samuel/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

background() {
    nohup "$@" </dev/null &>/dev/null &
    disown
}
