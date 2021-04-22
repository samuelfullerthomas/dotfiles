SSH_ENV="$HOME/.ssh/environment"
[[ -r "/usr/local/etc/profile.d/bash_completion.sh" ]] && . "/usr/local/etc/profile.d/bash_completion.sh"

function start_agent {
    echo "Initialising new SSH agent..."
    /usr/bin/ssh-agent | sed 's/^echo/#echo/' > "${SSH_ENV}"
    echo succeeded
    chmod 600 "${SSH_ENV}"
    . "${SSH_ENV}" > /dev/null
    /usr/bin/ssh-add;
}

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
export GITHUB_TOKEN="319f4b79fecb87a2bdfeed98d9467d009f260116"
export OCTO_LINKER_TOKEN="78a2df7236777db2559ffdf9036a0e5774125469"

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

function gitconfig () {
  if [ $# -eq 0 ] || [ $1 = "--help" ]; then
    echo "usage:"
    echo "gitconfig <profile> ------ switch to that profile"
    echo "gitconfig --help    ------ print this help text"
    echo "gitconfig --profiles  ------ show available profiles"
  elif [ $1 = "--profiles" ]; then
    echo "Available profiles:"
    find $HOME/.gitconfig.* | awk -F "." '{print $3}'
  elif [ -f "$HOME/.gitconfig.$1" ]; then
    rm $HOME/.gitconfig
    cp $HOME/.gitconfig.$1 $HOME/.gitconfig
    echo "Now using $1 config as .gitconfig"
  else
    echo "$HOME/.gitconfig.$1 not found"
    echo "Available profiles:"
    find $HOME/.gitconfig.* | awk -F "." '{print $3}'
  fi
}


# iterm
source ~/.iterm2_shell_integration.zsh
iterm2_print_user_vars() {
  iterm2_set_user_var gitBranch $((git branch 2> /dev/null) | grep \* | cut -c3-)
}

# aliases
alias zsh-aliases="grep alias ~/.zshrc"
alias zsh-functions="grep function ~/.zshrc"
alias help="echo 'try the command zsh-aliases to show you available aliases, or zsh-functions to show you available functions\ntry entering env to see environment variables'"

alias killchromium="pgrep Chromium | xargs kill -9"
alias reload="source ~/.zshrc"
alias clean-docker='docker system prune -a'
alias gco="git checkout"
alias gp="git push"
alias steam='wine ~/.wine/drive_c/Program\ Files\ \(x86\)/Steam'
alias winef='cd ~/.wine/drive_c/Program\ Files\ \(x86\)/'
alias screenschots-folder='echo "defaults write com.apple.screencapture location <path here>"'
alias lb="ssh root@209.97.141.227"
alias server-ssh='ssh root@68.183.44.201'
alias server-ip='echo 68.183.44.201'
alias delete-mail='echo "d *" | mail -N'
alias git-lastme="git for-each-ref --format=' %(authorname) %09 %(refname) %(committerdate)' --sort=authorname --sort=-committerdate | grep 'Sam Thomas'"
alias mv-npmrc='mv ~/.npmrc ~/.npmrc-temp'
alias mvb-npmrc='mv ~/.npmrc-temp ~/.npmrc'
alias zsh="code ~/.zshrc"
alias zshrc="code ~/.zshrc"

# docker
alias cleanup='brew cleanup && docker system prune'

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

eval "$(rbenv init -)"

# PS1 (prompt)
parse_git_branch() {
	hasmod=""
	if [[ `git ls-files -dmo --exclude-standard 2> /dev/null` ]]; then
		hasmod="*"
	fi
	git branch 2> /dev/null | sed -e '/^[^*]/d' -e "s/* \(.*\)/(\1$hasmod)/"
}

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

[[ -s "$HOME/.avn/bin/avn.sh" ]] && source "$HOME/.avn/bin/avn.sh" # load avn

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/samthomas/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/samthomas/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/samthomas/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/samthomas/google-cloud-sdk/completion.zsh.inc'; fi

export PATH="$HOME/.dotnet/tools:$PATH"
export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"
