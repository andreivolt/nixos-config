bindkey -v

export KEYTIMEOUT=1

autoload -U edit-command-line; zle -N edit-command-line
autoload -U select-bracketed; zle -N select-bracketed
autoload -U select-quoted; zle -N select-quoted
autoload -U surround; zle -N delete-surround surround; zle -N change-surround surround; zle -N add-surround surround

bindkey -M vicmd '^x^e' edit-command-line; bindkey -M viins '^x^e' edit-command-line
bindkey -M vicmd 'H' run-help

bindkey -M vicmd v edit-command-line

bindkey ''${terminfo[kcbt]:-^\[\[Z} reverse-menu-complete

bindkey '^n' expand-or-complete
bindkey '^p' reverse-menu-complete

for m in visual viopp; do
  for c in {a,i}''${(s..)^:-'()[]{}<>bB'}; do
    bindkey -M $m $c select-bracketed
  done
done
for m in visual viopp; do
  for c in {a,i}{\',\",\`}; do
    bindkey -M $m $c select-quoted
  done
done

bindkey -a cs change-surround
bindkey -a ds delete-surround
bindkey -a ys add-surround
bindkey -M visual S add-surround

function zle-keymap-select zle-line-init zle-line-finish {
  case $KEYMAP in
    vicmd) print -n '\033[1 q' ;;
    viins|main) print -n '\033[6 q' ;;
  esac
}
zle -N zle-line-init; zle -N zle-line-finish; zle -N zle-keymap-select
