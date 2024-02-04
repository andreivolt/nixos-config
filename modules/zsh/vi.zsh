# vi keybindings

bindkey -v

export KEYTIMEOUT=1

autoload -U select-bracketed; zle -N select-bracketed
autoload -U select-quoted; zle -N select-quoted

autoload -U surround; zle -N delete-surround surround
zle -N change-surround surround
zle -N add-surround surround

# edit command line in $EDITOR
autoload -U edit-command-line; zle -N edit-command-line
bindkey -M vicmd '^x^e' edit-command-line
bindkey -M viins '^x^e' edit-command-line
bindkey -M vicmd v edit-command-line

bindkey -M vicmd 'H' run-help

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

# change surroundings
bindkey -a cs change-surround
bindkey -a ds delete-surround
bindkey -a ys add-surround
bindkey -M visual S add-surround

# change cursor according to mode
function zle-keymap-select zle-line-init zle-line-finish {
  case $KEYMAP in
    vicmd) print -n '\033[1 q' ;; # block
    viins|main) print -n '\033[6 q' ;; # line
  esac
}
zle -N zle-line-init; zle -N zle-line-finish; zle -N zle-keymap-select

# completion menu
zmodload zsh/complist
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'j' vi-down-line-or-history
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char
bindkey -M menuselect 'i' accept-and-menu-complete
bindkey -M menuselect 'u' undo
# jump between categories of matches
bindkey -M menuselect 'n' vi-forward-blank-word
bindkey -M menuselect 'b' vi-backward-blank-word

# prepend sudo
run-with-sudo () { LBUFFER="sudo $LBUFFER" }
zle -N run-with-sudo
bindkey -M vicmd gs run-with-sudo

# dismiss current input to run another command, then restore
bindkey '^G' push-line-or-edit
bindkey -M vicmd '^G' push-line-or-edit
bindkey -M viins '^G' push-line-or-edit
bindkey -M vicmd "q" push-line-or-edit
