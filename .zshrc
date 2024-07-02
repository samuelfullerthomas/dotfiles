SSH_ENV="$HOME/.ssh/environment"
[[ -r "/usr/local/etc/profile.d/bash_completion.sh" ]] && . "/usr/local/etc/profile.d/bash_completion.sh"
[[ -s "$HOME/.gvm/scripts/gvm" ]] && source "$HOME/.gvm/scripts/gvm"

# path
export PATH=$HOME/bin:/usr/local/bin:$HOME/.cargo/bin:$HOME/.zshrc:$PATH:$PATH/usr/local/sbin:$PATH
export ZSH_DISABLE_COMPFIX=true
# path to oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh

# theme
ZSH_THEME="cloud"

# GPG stuff
# https://github.com/keybase/keybase-issues/issues/2798
export GPG_TTY=$(tty)

# resource ZSH
source $ZSH/oh-my-zsh.sh

# ssh
export MEETUP_KEY=515927b636e132036c50656358641b
export authId=MANDCWOWIXNTG2YZQXNT
export authToken=MDBhNGQyNjA4NTU2ODIzZjQxMzc2M2FhY2Q2OGE1
export SSH_KEY_PATH="~/.ssh/rsa_id"

# github
export XDG_DATA_HOM="$HOME/.local/share"

# java
export CPPFLAGS="-I/usr/local/opt/openjdk@11/include"

# functions
function repeatspeed () {
  defaults write NSGlobalDomain KeyRepeat -int :$1
  echo "hows that speed for ya."
}

function killport () {
  lsof -i TCP:$1 | grep LISTEN | awk '{print $2}' | xargs kill -9
  echo "He's dead Jim."
}

function killp () {
  sudo pgrep $1 | sudo xargs kill -9
  pgrep $1
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

function gcm () {
  git commit -a -m "$1"
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
    pr_url=$github_url"/compare/master..."$branch_name"?quick_pull=1&template=commerce.md"
    echo -n $branch_name | pbcopy
    open $pr_url;
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
    echo 'catp usage: catp <term> <padding lines>'
  elif [ $# -eq 2 ]; then
    grep -B $2 -A $2 $1 ./package.json
  fi
  grep $1 ./package.json
}

function reload() {
  source ~/.zshrc
}

function checknode () {
  if [[ -f ./package.json ]]; then
    nodeversion=$(ggrep -oP '"node": "[><=~]{0,2}([0-9]{2})' package.json | ggrep -oP '[0-9]{2}')
    if [[ -n "$nodeversion" ]]; then
      nvm use $nodeversion
    fi
  fi
}


# automatically use node version
function cd() {
  builtin cd "$@"
  if [[ -f .nvmrc ]]; then
    nvm use
  fi
  checknode
}

function start_agent {
    echo "Initialising new SSH agent..."
    /usr/bin/ssh-agent | sed 's/^echo/#echo/' > "${SSH_ENV}"
    echo succeeded
    chmod 600 "${SSH_ENV}"
    . "${SSH_ENV}" > /dev/null
    /usr/bin/ssh-add;
}

function onStartup {
  # Source SSH settings, if applicable
  if [ -f "${SSH_ENV}" ]; then
      . "${SSH_ENV}" > /dev/null
      #ps ${SSH_AGENT_PID} doesn't work under cywgin
      ps -ef | grep ${SSH_AGENT_PID} | grep ssh-agent$ > /dev/null || {
          start_agent;
      }
  else
      start_agent;
  fi
  # checkoutProfile
}

# iterm
source ~/.iterm2_shell_integration.zsh

iterm2_print_user_vars() {
  iterm2_set_user_var profile $(git config user.email)
  iterm2_set_user_var gitBranch $((git branch 2> /dev/null) | grep \* | cut -c3-)
}

# aliases
alias zsh-aliases="grep alias ~/.zshrc"
alias zsh-functions="grep function ~/.zshrc"
alias zsh="code ~/.zshrc"
alias zshrc="code ~/.zshrc"
alias help="echo 'try the command zsh-aliases to show you available aliases, or zsh-functions to show you available functions\ntry entering env to see environment variables'"

alias killchromium="pgrep Chromium | xargs kill -9"
alias clean-docker='docker system prune -a'

alias gco="git checkout"
alias gp="git push"
alias gpo="git push -u"
alias gcam="git commit -a -m"

alias override-screenschots-folder='echo "defaults write com.apple.screencapture location <path here>"'
alias delete-mail='echo "d *" | mail -N'
alias git-lastme="git for-each-ref --format=' %(authorname) %09 %(refname) %(committerdate)' --sort=authorname --sort=-committerdate | grep 'Sam Thomas' --max-count 10"
alias mv-npmrc='mv ~/.npmrc ~/.npmrc-temp'
alias mvb-npmrc='mv ~/.npmrc-temp ~/.npmrc'

alias nap="pmset sleepnow"

# docker
alias cleanup='brew cleanup && docker system prune'

eval "$(rbenv init -)"

# PS1 (prompt)
parse_git_branch() {
	hasmod=""
	if [[ `git ls-files -dmo --exclude-standard 2> /dev/null` ]]; then
		hasmod="*"
	fi
	git branch 2> /dev/null | sed -e '/^[^*]/d' -e "s/* \(.*\)/(\1$hasmod)/"
}

export GOPATH="$HOME/go"

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
export PATH="$HOME/Library/Python/3.9/bin:$PATH"

# nvm
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
export PATH="/usr/local/opt/openjdk@11/bin:$PATH"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/samuel/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/samuel/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/samuel/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/samuel/google-cloud-sdk/completion.zsh.inc'; fi

# pnpm
export PNPM_HOME="/Users/samuel/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end


# call startup function
onStartup
