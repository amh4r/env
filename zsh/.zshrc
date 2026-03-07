# Fixes "Insecure completion-dependent directories detected"
# https://github.com/ohmyzsh/ohmyzsh/issues/6835
ZSH_DISABLE_COMPFIX=true



###############
# Oh My Zsh

# Path to your oh-my-zsh installation.
export ZSH="/Users/aharper/.oh-my-zsh"

ZSH_THEME="aaronharper"

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
	git
	zsh-autosuggestions
	zsh-syntax-highlighting
)

# If this is the first time this file is run
if [ ${IS_OH_MY_ZSH_SOURCED:-0} != 1 ]; then
	source $ZSH/oh-my-zsh.sh
fi
IS_OH_MY_ZSH_SOURCED=1



###############
# Functions

# Add a notification when a command completes or fails.
# Example: `echo hello; alertdone`
alertdone() {
	local PREV_STATUS=$?

	# If the user passes -q, don't say anything.
	local SPEAK=0
	while getopts "s" opt; do
		case $opt in
			s) SPEAK=1 ;;
		esac
	done

	if [ $PREV_STATUS -eq 0 ]
	then
		osascript -e 'display notification "✅" with title "Done"'

		if [ $SPEAK -eq 1 ]
		then
			# Need to redirect to /dev/null to hide "'Dock' is running" stderr.
			# This only happens within tmux
			say done 2>/dev/null
		fi
	else
		osascript -e 'display notification "❌" with title "Failed"'

		if [ $SPEAK -eq 1 ]
		then
			say failed 2>/dev/null
		fi
	fi
}

# List notable directories.
listdirs() {
	ls -d1 ~/inngest/* | fzf
}

# Only modify $PATH if passed path isn't already in $PATH
# Examples: `pathmunge /foo/bar`, `pathmunge /foo/bar after`
pathmunge() {
	if ! echo "$PATH" | grep -Eq "(^|:)$1($|:)" ; then
		if [ "$2" = "after" ] ; then
			PATH="$PATH:$1"
		else
			PATH="$1:$PATH"
		fi
	fi
}

# Place windows correctly.
place-apps () {
	~/personal/env/scripts/place-apps.py
}

# Place displays correctly. Requires https://github.com/jakehilborn/displayplacer
place-displays () {
	REGEX_GET_VALUE_AFTER_COLON='s/\([A-Za-z ]*\): \(.*\)/\2/'

	DATA=$(displayplacer list | grep -E 'Persistent screen id:|Resolution:|Rotation:')

	TOP_SCREEN_ID=$(echo "$DATA" | grep -B 1 -A 1 'Resolution: 3440x1440' | grep 'Persistent screen id' | sed "$REGEX_GET_VALUE_AFTER_COLON")
	BOTTOM_SCREEN_ID=$(echo "$DATA" | grep -B 1 -A 1 'Resolution: 1920x1080' | grep 'Persistent screen id' | sed "$REGEX_GET_VALUE_AFTER_COLON")
	LEFT_SCREEN_ID=$(echo "$DATA" | grep -B 1 -A 1 'Resolution: 1080x1920' | grep -B 2 'Rotation: 90' | grep 'Persistent screen id' | sed "$REGEX_GET_VALUE_AFTER_COLON")
	RIGHT_SCREEN_ID=$(echo "$DATA" | grep -B 1 -A 1 'Resolution: 1080x1920' | grep -B 2 'Rotation: 270' | grep 'Persistent screen id' | sed "$REGEX_GET_VALUE_AFTER_COLON")

	displayplacer \
		"id:$TOP_SCREEN_ID res:3440x1440 hz:50 color_depth:8 scaling:off origin:(0,0) degree:0" \
		"id:$LEFT_SCREEN_ID res:1080x1920 hz:60 color_depth:8 scaling:off origin:(-1080,550) degree:90" \
		"id:$BOTTOM_SCREEN_ID res:1920x1080 hz:60 color_depth:8 scaling:off origin:(770,1440) degree:0" \
		"id:$RIGHT_SCREEN_ID res:1080x1920 hz:60 color_depth:8 scaling:off origin:(3440,550) degree:270"
}

sync-obsidian () {
	(cd  ~/personal/notes && git add . && git commit -m "Sync" && git push)
}



##############
# Alacritty

# Disable bouncing in dock. https://github.com/alacritty/alacritty/issues/2950#issuecomment-706610878
printf "\e[?1042l"



###############
# AI

# Do not set SSH_AUTH_SOCK for Claude Code. This fixes an issue where Claude
# Code would trigger a YubiKey prompt immediately after asking the first
# question of a session.
alias claude="SSH_AUTH_SOCK= claude"



###############
# Docker

alias dk=docker
alias dkc=docker-compose



###############
# fzf

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh



###############
# Go

pathmunge /usr/local/go/bin
pathmunge $HOME/go/bin



###############
# Google Cloud

alias gcp=gcloud



###############
# Homebrew

HOMEBREW_NO_AUTO_UPDATE=1



###############
# JavaScript

export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"

# Load nvm
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Load nvm bash completion
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

export DENO_INSTALL="/Users/aharper/.deno"
export PATH="$DENO_INSTALL/bin:$PATH"

# bun completions
[ -s "/Users/aharper/.bun/_bun" ] && source "/Users/aharper/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# pnpm
export PNPM_HOME="/Users/aharper/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac



###############
# Kubernetes

alias k=kubectl

# https://krew.sigs.k8s.io/docs/user-guide/setup/install
pathmunge "${KREW_ROOT:-$HOME/.krew}/bin"



###############
# Nix

# Uncomment the following 3 lines to enable:
#. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
#direnvPath=$(which direnv)
#eval "$(${direnvPath} hook zsh)"


###############
# Python

alias psql=/opt/homebrew/opt/libpq/bin/psql

alias py=python
eval "$(pyenv init -)"



###############
# Tailscale

alias tailscale="/Applications/Tailscale.app/Contents/MacOS/Tailscale"



###############
# Terraform

alias tfm=terraform



###############
# Tmux

alias tsa="tmux ls | cut -d: -f1 | fzf | xargs tmux switch -t"



###############
# VS Code

# Allow key repeat (holding down a key).
defaults write com.microsoft.VSCode ApplePressAndHoldEnabled -bool false

alias c="cursor ."



###############
# YubiKey

export SSH_AUTH_SOCK="$(brew --prefix)/var/run/yubikey-agent.sock"



###############
# Zsh Fixes

# This speeds up pasting w/ autosuggest
# https://github.com/zsh-users/zsh-autosuggestions/issues/238
pasteinit() {
  OLD_SELF_INSERT=${${(s.:.)widgets[self-insert]}[2,3]}
  zle -N self-insert url-quote-magic # I wonder if you'd need `.url-quote-magic`?
}
pastefinish() {
  zle -N self-insert $OLD_SELF_INSERT
}
zstyle :bracketed-paste-magic paste-init pasteinit
zstyle :bracketed-paste-magic paste-finish pastefinish

# Fixes escaping when pasting URLs.
# https://github.com/robbyrussell/oh-my-zsh/issues/6654#issuecomment-418201107
zstyle ':urlglobber' url-other-schema



###############
# Misc

# Default editor
export EDITOR="vim"

# Use the real time binary instead of Mac's built-in one
alias time=/usr/bin/time

# Make watch expand aliases
alias watch='watch '


# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/aharper/Downloads/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/aharper/Downloads/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/aharper/Downloads/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/aharper/Downloads/google-cloud-sdk/completion.zsh.inc'; fi
. "/Users/aharper/.deno/env"
# Initialize zsh completions (added by deno install script)
autoload -Uz compinit
compinit
. "$HOME/.local/bin/env"


pathmunge ~/bin

# opencode
export PATH=/Users/aharper/.opencode/bin:$PATH
