SSH_ENV="$HOME/.ssh/environment"

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
export PATH=$HOME/bin:/usr/local/bin:$HOME/.cargo/bin:$PATH:$PATH/usr/local/sbin:$PATH
# path to oh-my-zsh installation.
export ZSH=/Users/$USER/.oh-my-zsh

# theme
ZSH_THEME="cloud"

# plugins
# plugins=(
#   git
# )

# resource ZSH
source $ZSH/oh-my-zsh.sh

# ssh
export SSH_KEY_PATH="~/.ssh/rsa_id"

# functions
repeatspeed () {
  defaults write NSGlobalDomain KeyRepeat -int :$1
  echo "hows that speed for ya."
}

killport () {
  lsof -i TCP:$1 | grep LISTEN | awk '{print $2}' | xargs kill -9
  echo "He's dead Jim."
}
killp () {
  pgrep $1 | xargs kill -9
  pgrep $1
  echo "so much blood."
}


#iterm
source ~/.iterm2_shell_integration.zsh
iterm2_print_user_vars() {
  iterm2_set_user_var gitBranch $((git branch 2> /dev/null) | grep \* | cut -c3-)
}

# aliases
alias killchromium="pgrep Chromium | xargs kill -9"
alias reload="source ~/.zshrc"
alias rebootexp="fusion kill && fusion boot experiences"
alias clean-docker='docker system prune -a'
alias gco="git checkout"
alias gp="git push"
alias rmssg="rm .ssg-config-*"
alias gh='gh-home'
alias steam='wine ~/.wine/drive_c/Program\ Files\ \(x86\)/Steam'
alias winef='cd ~/.wine/drive_c/Program\ Files\ \(x86\)/'

# alias gcp="git checkout $1 && git pull"
alias dubit="NODE_ENV=development /Users/$USER/qubit/qubit-cli/bin/qubit"
alias zsh="code ~/.zshrc"
alias zshrc="code ~/.zshrc"

# baton
alias bprod='baton -e production '
alias bstag='baton -e staging '

alias kprod='baton -e production kubectl '
alias kstag='baton -e staging kubectl '

alias hprod='baton -e production helm '
alias hstag='baton -e staging helm '

alias cleanup='brew cleanup &&docker system prune'
alias restore-exp-stg="fusion restore -e staging experiences -p '&IzYc6Zl5QjdX%5FfqDdmj:9WpxrX8'"
#nvm
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
