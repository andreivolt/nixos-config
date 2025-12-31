export FZF_DEFAULT_OPTS="--ansi --bind='ctrl-y:execute-silent(pbcopy <<< {})+abort' --cycle --highlight-line --info=inline --preview-window=wrap,border --wrap --tiebreak=index --no-scrollbar --no-separator --border=none --gutter=' ' --color=16,fg:white,bg:-1,hl:bright-yellow,fg+:bright-white,bg+:bright-black,hl+:bright-yellow,info:bright-cyan,prompt:bright-green,pointer:bright-cyan,marker:bright-magenta,spinner:bright-yellow,header:bright-blue,border:bright-black"

export FZF_DEFAULT_COMMAND="rg -uu --files -H"

export FZF_CTRL_R_OPTS="--nth=2.."

# <tab> at beginning of line opens fzf file selector
function fzf-file-widget-open() {
  if [[ -z "$BUFFER" ]]; then
    local selected=$(rg --hidden --follow --files --sort modified --follow 2>/dev/null | tac | fzf --preview '~/.config/zsh/preview {}')
    if [[ -n "$selected" ]]; then
      if ! head -c 1024 "$selected" | file - | grep -q "text"; then
        if [[ -n "$TERMUX_VERSION" ]]; then
          BUFFER="termux-open '$selected'"
        else
          BUFFER="open '$selected'"
        fi
      else
        BUFFER="nvim '$selected'"
      fi
      zle accept-line
    fi
  else
    zle expand-or-complete
  fi
}
zle -N fzf-file-widget-open
bindkey '^I' fzf-file-widget-open
bindkey -M vicmd '^I' fzf-file-widget-open
