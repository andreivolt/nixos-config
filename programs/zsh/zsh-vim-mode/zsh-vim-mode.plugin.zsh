# Zsh's history-beginning-search-backward is very close to Vim's C-x C-l
history-beginning-search-backward-then-append() {
  zle history-beginning-search-backward
  zle vi-add-eol
}
zle -N history-beginning-search-backward-then-append

bindkey -v
export KEYTIMEOUT=1

# Edit command line
autoload -U edit-command-line
zle -N edit-command-line
bindkey -M viins '^x^e'  edit-command-line

bindkey -M viins '^a'    beginning-of-line
bindkey -M viins '^e'    end-of-line
bindkey -M viins '^b'    backward-char
bindkey -M viins '^d'    delete-char-or-list
bindkey -M viins '^f'    forward-char
bindkey -M viins '^k'    kill-line
bindkey -M viins '^r'    history-incremental-pattern-search-backward
bindkey -M viins '^s'    history-incremental-pattern-search-forward
bindkey -M viins '^o'    history-beginning-search-backward
bindkey -M viins '^p'    up-line-or-history
bindkey -M viins '^n'    down-line-or-history
bindkey -M viins '^y'    yank
bindkey -M viins '^w'    backward-kill-word
bindkey -M viins '^u'    backward-kill-line
bindkey -M viins '^h'    backward-delete-char
bindkey -M viins '^?'    backward-delete-char
bindkey -M viins '^_'    undo
bindkey -M viins '^x^l'  history-beginning-search-backward-then-append
bindkey -M viins '^x^r'  redisplay
bindkey -M viins '\eb'   backward-word
bindkey -M viins '\ed'   kill-word
bindkey -M viins '\ef'   forward-word
bindkey -M viins '\eh'   run-help
bindkey -M viins '\e.'   insert-last-word
# Alt + arrows
bindkey -M viins '[D'    backward-word
bindkey -M viins '[C'    forward-word
bindkey -M viins '\e[1;3D' backward-word
bindkey -M viins '\e[1;3C' forward-word
# Ctrl + arrows
bindkey -M viins '\eOD'  backward-word
bindkey -M viins '\eOC'  forward-word
bindkey -M viins '\e[1;5D' backward-word
bindkey -M viins '\e[1;5C' forward-word
# Home / End
bindkey -M viins '\eOH'  beginning-of-line
bindkey -M viins '\eOF'  end-of-line
bindkey -M viins '\e[1~' beginning-of-line
bindkey -M viins '\e[4~' end-of-line
# Insert / Delete
bindkey -M viins '\e[2~' overwrite-mode
bindkey -M viins '\e[3~' delete-char
# Page up / Page down
bindkey -M viins '\e[5~' history-beginning-search-backward
bindkey -M viins '\e[6~' history-beginning-search-forward
# Shift + Tab
bindkey -M viins '\e[Z'  reverse-menu-complete

bindkey -M vicmd 'ga'    what-cursor-position
bindkey -M vicmd 'gg'    beginning-of-history
bindkey -M vicmd 'G '    end-of-history
bindkey -M vicmd '^a'    beginning-of-line
bindkey -M vicmd '^b'    backward-char
bindkey -M vicmd '^e'    end-of-line
bindkey -M vicmd '^f'    forward-char
bindkey -M vicmd '^i'    history-substring-search-down
bindkey -M vicmd '^k'    kill-line
bindkey -M vicmd '^r'    history-incremental-pattern-search-backward
bindkey -M vicmd '^s'    history-incremental-pattern-search-forward
bindkey -M vicmd '^o'    history-beginning-search-backward
bindkey -M vicmd '^p'    up-line-or-history
bindkey -M vicmd '^n'    down-line-or-history
bindkey -M vicmd '^y'    yank
bindkey -M vicmd '^w'    backward-kill-word
bindkey -M vicmd '^u'    backward-kill-line
bindkey -M vicmd '^_'    undo
bindkey -M vicmd '/'     vi-history-search-forward
bindkey -M vicmd '?'     vi-history-search-backward
bindkey -M vicmd ':'     execute-named-cmd
bindkey -M vicmd '\eb'   backward-word
bindkey -M vicmd '\ed'   kill-word
bindkey -M vicmd '\ef'   forward-word
bindkey -M vicmd '\e.'   insert-last-word
# Page up / Page down
bindkey -M vicmd '\e[5~' history-beginning-search-backward
bindkey -M vicmd '\e[6~' history-beginning-search-forward
bindkey -M vicmd 'H'     run-help
bindkey -M vicmd 'u'     undo
bindkey -M vicmd 'U'     redo
bindkey -M vicmd 'Y'     vi-yank-eol
bindkey -M vicmd '\-'    vi-repeat-find
bindkey -M vicmd '_'     vi-rev-repeat-find

if [[ -n $HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND ]]; then
    bindkey -M viins '^o' history-substring-search-up
    bindkey -M viins '\e[5~' history-substring-search-up
    bindkey -M viins '\e[6~' history-substring-search-down

    bindkey -M vicmd '^o' history-substring-search-up
    bindkey -M vicmd '^i' history-substring-search-down
    bindkey -M vicmd '\e[5~' history-substring-search-up
    bindkey -M vicmd '\e[6~' history-substring-search-down
fi

# If mode indicator wasn't setup by theme, define default
if [[ -z $N_MODE ]]; then
  N_MODE="%{$fg[red]%}[N]%{$reset_color%}"
fi

if [[ -z $I_MODE ]]; then
  I_MODE="%{$fg[white]%}[I]%{$reset_color%}"
fi

function vim-mode-update-prompt {
  case $ZSH_CUR_KEYMAP in
    vicmd) CUR_MODE=$N_MODE ;;
    main|viins) CUR_MODE=$I_MODE ;;
  esac
  PS1=${PS1//($N_MODE|$I_MODE)/$CUR_MODE}
  RPS1=${${RPS1-$RPROMPT}//($N_MODE|$I_MODE)/$CUR_MODE}
  zle reset-prompt
}

if type -f hooks-add-hook 1>/dev/null 2>&1; then
  hooks-add-hook zle_keymap_select_hook vim-mode-update-prompt
  hooks-add-hook zle_line_init_hook vim-mode-update-prompt
else
  echo "zsh-hooks not loaded! Please load willghatch/zsh-hooks before zsh-vim-mode!"
fi

# enable parens, quotes and surround text-objects
autoload -U select-bracketed
zle -N select-bracketed
for m in visual viopp; do
    for c in {a,i}${(s..)^:-'()[]{}<>bB'}; do
        bindkey -M $m $c select-bracketed
    done
done

autoload -U select-quoted
zle -N select-quoted
for m in visual viopp; do
  for c in {a,i}{\',\",\`}; do
    bindkey -M $m $c select-quoted
  done
done

autoload -Uz surround
zle -N delete-surround surround
zle -N change-surround surround
zle -N add-surround surround
bindkey -a cs change-surround
bindkey -a ds delete-surround
bindkey -a ys add-surround
bindkey -M visual S add-surround

# change cursor shape with mode
autoload -U colors; colors

# Remove mode switching delay.
KEYTIMEOUT=5

# Change cursor shape for different vi modes.
function zle-keymap-select {
  if [[ ${KEYMAP} == vicmd ]] ||
      [[ $1 = 'block' ]]; then
    echo -ne '\e[1 q'

  elif [[ ${KEYMAP} == main ]] ||
        [[ ${KEYMAP} == viins ]] ||
        [[ ${KEYMAP} = '' ]] ||
        [[ $1 = 'beam' ]]; then
    echo -ne '\e[5 q'
  fi
}
zle -N zle-keymap-select

# Use beam shape cursor on startup.
echo -ne '\e[5 q'

# Use beam shape cursor for each new prompt.
preexec() {
    echo -ne '\e[5 q'
}

