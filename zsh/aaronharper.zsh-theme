ZSH_THEME_GIT_PROMPT_PREFIX=" %{$fg_bold[cyan]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg_bold[red]%}!"
ZSH_THEME_GIT_PROMPT_CLEAN=""

function prompt_char {
	if [ $UID -eq 0 ]; then echo "%{$fg[red]%}#%{$reset_color%}"; else echo "$"; fi
}

PROMPT='%(?, ,%{$fg[red]%}FAIL%{$reset_color%}
)
'

# Time section
# PROMPT+='%{%K{240}%F{white}%}%* %{%k%f%}'
PROMPT+='%{%K{236}%}%{$fg_bold[green]%}%* %{%k%f%}'

# Current directory section
PROMPT+='%{%K{237}%}%{$fg_bold[yellow]%} %~ %{%k%f%}'

# Git section
PROMPT+='%{%K{236}%}$(git_prompt_info) %{%k%f%}'

# Prompt character (e.g. "$")
PROMPT+='
$(prompt_char) '
