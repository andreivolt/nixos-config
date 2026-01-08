autoload -Uz compinit
zcompdump=$XDG_CACHE_HOME/zsh/zcompdump
[[ -f $zcompdump(#qN.mh+24) ]] && compinit -d $zcompdump && zcompile $zcompdump || compinit -C -d $zcompdump

(( ${+commands[brew]} )) && fpath=(/opt/homebrew/share/zsh/site-functions $fpath)

bindkey -M menuselect '^o' accept-and-menu-complete
bindkey -M menuselect "+" accept-and-menu-complete

_comp_options+=(globdots)

zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$XDG_CACHE_HOME/zsh/zcompcache"

zstyle ':completion:*' accept-exact '*(N)'
zstyle ':completion:*' auto-description 'specify: %d'
zstyle ':completion:*' file-patterns '%p:globbed-files' '*(-/):directories'
zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'
zstyle ':completion:*:corrections' format '%F{green}-- %d (errors: %e) --%f'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' insert-unambiguous true
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*' menu select
zstyle ':completion:*' rehash true
zstyle ':completion:*' squeeze-slashes yes
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS} 'ma=30;46'
zstyle ':completion:*:default' select-prompt '%SMatch %M Line %L %P%s'
zstyle ':completion:*:matches' group 'yes'
zstyle ':completion:*:messages' format '%d'
zstyle ':completion:*:options' auto-description '%d'
zstyle ':completion:*:options' description 'yes'
zstyle ':completion:*:warnings' format "%B$fg[red]%}No matches for: $fg[white]%d%b"

zstyle -e ':completion:*' completer '
  case $_last_try in
    $HISTNO$BUFFER$CURSOR)
      reply=(_ignored _approximate _complete)
      _last_try="$HISTNO$BUFFER${CURSOR}x"
      ;;
    $HISTNO$BUFFER${CURSOR}x)
      reply=(_approximate:-extreme _complete)
      ;;
    *)
      _last_try="$HISTNO$BUFFER$CURSOR"
      reply=(_complete _expand_alias _prefix)
      ;;
  esac
'

zstyle ':completion:*:approximate:*' max-errors '(( reply=($#PREFIX+$#SUFFIX)/3 ))'
zstyle -e ':completion:*:approximate-extreme:*' max-errors '(( reply=($#PREFIX+$#SUFFIX)/1.2 ))'
zstyle ':completion:*:(correct|approximate[^:]#):*' original false
zstyle ':completion:*:(correct|approximate[^:]#):*' tag-order '! original'

zstyle ':completion::(^approximate*):*:functions' ignored-patterns '_*'
zstyle ':completion::*:(bindkey|zle):*:widgets' ignored-patterns '.*'

zstyle ':completion:*:man:*' menu yes select
zstyle ':completion:*:manuals' separate-sections true
zstyle ':completion:*:manuals.*' insert-sections true

zstyle ':completion:*:expand:*' tag-order all-expansions
zstyle ':completion:*:expand-alias:*' global true
zstyle ':completion:*:history-words' list false

zstyle ':completion:*:*:-subscript-:*' tag-order indexes parameters

zsh-defer -c '
  _carapace_cache="${XDG_CACHE_HOME:-$HOME/.cache}/carapace/init.zsh"
  if [[ ! -f $_carapace_cache || ${commands[carapace]} -nt $_carapace_cache ]]; then
    mkdir -p ${_carapace_cache:h}
    carapace _carapace zsh >$_carapace_cache
  fi
  source $_carapace_cache
'
