(( ! ${+ZSH_FZF_HISTORY_SEARCH_BIND} )) &&
typeset -g ZSH_FZF_HISTORY_SEARCH_BIND='^r'

(( ! ${+ZSH_FZF_HISTORY_SEARCH_DATES_IN_SEARCH} )) &&
typeset -g ZSH_FZF_HISTORY_SEARCH_DATES_IN_SEARCH=1

(( ! ${+ZSH_HISTORY_RELATIVE_DATES} )) &&
typeset -g ZSH_HISTORY_RELATIVE_DATES=''

fzf_history_search() {
  setopt extendedglob

  local history_script="${${(%):-%x}:A:h}/history-search"

  local script_args=""

  if (( $ZSH_FZF_HISTORY_SEARCH_DATES_IN_SEARCH )); then
    if [[ -n "${ZSH_HISTORY_RELATIVE_DATES}" ]]; then
      script_args="--relative"
    fi
  fi

  local selected_command
  selected_command=$("$history_script" $script_args)
  local ret=$?

  if [[ -n "$selected_command" ]]; then
    BUFFER="$selected_command"
    zle end-of-line
  fi

  zle reset-prompt
  return $ret
}

autoload fzf_history_search
zle -N fzf_history_search

bindkey $ZSH_FZF_HISTORY_SEARCH_BIND fzf_history_search
