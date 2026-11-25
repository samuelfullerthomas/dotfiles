
# Added by Kiro CLI
case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) export PATH="${PATH:+$PATH:}$HOME/.local/bin" ;; esac

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

# theme
ZSH_THEME="cloud"

# GPG stuff
# https://github.com/keybase/keybase-issues/issues/2798
export GPG_TTY=$(tty)

# source ZSH
if [[ -f $ZSH/oh-my-zsh.sh ]]; then
  source $ZSH/oh-my-zsh.sh
else
  print -u2 "oh-my-zsh is missing: run ~/setup-machine/doctor.sh"
fi

# coveo-specific config (only on the coveo machine)
[[ -f "$HOME/.zshrc.coveo" ]] && source "$HOME/.zshrc.coveo"
# personal-only config (only on the personal machine)
[[ -f "$HOME/.zshrc.personal" ]] && source "$HOME/.zshrc.personal"

# source iterm integration (conditional load is at end of file)
# source ~/.iterm2_shell_integration.zsh

# ssh
export SSH_KEY_PATH="$HOME/.ssh/rsa_id"

# XDG base directory
export XDG_DATA_HOME="$HOME/.local/share"

# java
export CPPFLAGS="-I/usr/local/opt/openjdk@11/include"

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
    echo "🔗 $pr_url"
    if [[ "$github_url" == *"admin-ui"* ]]; then
      echo "⚠️  Remember to add reviewer: gh pr edit <number> --add-reviewer coveo-platform/command-agentic-operation"
    fi
    return
  else
    pr_url=`gh pr view --json url -q .url`
    echo "🔗 $pr_url"
  fi
}

function ape() {
  git push -u && openpr
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
  exec zsh
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
  (( $+functions[nvm] )) && nvm use default

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

  (( $+functions[onStartupCoveo] )) && onStartupCoveo
}

# aliases
alias zsh-aliases="grep alias ~/.zshrc ~/.zshrc.coveo 2>/dev/null"
alias zsh-functions="grep function ~/.zshrc ~/.zshrc.coveo 2>/dev/null"
alias zshrc="codium ~/.zshrc"
alias help="echo 'try the command zsh-aliases to show you available aliases, or zsh-functions to show you available functions\ntry entering env to see environment variables'"
alias code="codium"
alias kiro-cli-trust="kiro-cli chat --trust-all-tools"
alias pn="pnpm"
alias pnx="pnpx"
alias killchromium="pgrep Chromium | xargs kill -9"
alias clean-docker='docker system prune -a'

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

# Last X commits, flat (default 10)
glast() {
  local count="${1:-10}"
  git --no-pager log --oneline -n "$count"
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
(( $+commands[rbenv] )) && eval "$(rbenv init -)"

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
if [ -s "$NVM_DIR/nvm.sh" ]; then
  \. "$NVM_DIR/nvm.sh" # nvm installed with its own script
elif [ -s /opt/homebrew/opt/nvm/nvm.sh ]; then
  \. /opt/homebrew/opt/nvm/nvm.sh # nvm installed by the Brewfile
fi
export PATH="/usr/local/opt/openjdk@11/bin:$PATH"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME/bin:"*) ;;
  *) export PATH="$PNPM_HOME/bin:$PATH" ;;
esac
# pnpm end


# call startup function (doctor.sh sets SETUP_MACHINE_DOCTOR to skip its logins and agent setup)
[[ -z $SETUP_MACHINE_DOCTOR ]] && onStartup
export PATH="/opt/homebrew/opt/openjdk@21/bin:$PATH"

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/samuel/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/samuel/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/samuel/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/samuel/google-cloud-sdk/completion.zsh.inc'; fi

# zoxide - smarter cd command (install with: brew install zoxide)
# Use 'z' to jump to directories, e.g., 'z admin' -> ~/coveo-platform/admin-ui
(( $+commands[zoxide] )) && eval "$(zoxide init zsh)"

# bun completions
[ -s "/Users/samuel/.bun/_bun" ] && source "/Users/samuel/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

background() {
    nohup "$@" </dev/null &>/dev/null &
    disown
}


#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"



[[ -f "$HOME/.local/bin/env" ]] && . "$HOME/.local/bin/env"

# pyenv
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
(( $+commands[pyenv] )) && eval "$(pyenv init - zsh)"
