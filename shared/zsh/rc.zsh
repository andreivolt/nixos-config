[[ -z $__ZPROFILE_SOURCED ]] && source ~/.zprofile

export GPG_TTY="$(tty)"

HISTSIZE="999999" SAVEHIST=$HISTSIZE
HISTFILE=$XDG_STATE_HOME/zsh/history
setopt append_history
setopt extended_history
setopt hist_fcntl_lock
setopt hist_ignore_dups
setopt hist_ignore_space
setopt hist_reduce_blanks
setopt share_history

setopt auto_cd
setopt auto_pushd
setopt extended_glob
setopt interactive_comments
setopt null_glob
setopt numeric_glob_sort

READNULLCMD=$PAGER

# Set terminal title
precmd() {
  print -Pn "\e]0;%~\a"  # Show current directory
}

preexec() {
  print -Pn "\e]0;$1\a"  # Show running command
}

# Prompt configuration - two lines with "# " prefix
# Show user@host only in SSH connections
# if [[ -n "$SSH_CLIENT" ]]; then
#     PROMPT='%(?.%F{green}#%f.%F{red}#%f) %F{cyan}%n@%m%f:%F{blue}%~%f
# %(?.%F{green}#%f.%F{red}#%f) '
# else
#     PROMPT='%(?.%F{green}#%f.%F{red}#%f) %F{blue}%~%f
# %(?.%F{green}#%f.%F{red}#%f) '
# fi

alias -g C="| wc -l"
alias -g G="| rg"
alias -g H="| head"
alias -g L="| $PAGER"
alias -g N="&> /dev/null"
alias -g NE="2> /dev/null"
alias -g X="| xargs"

alias -- +x="chmod +x"
cat() {
  if [[ -t 1 ]]; then
    bat "$@"
  else
    command cat "$@"
  fi
}
alias cdt="cd $(mktemp -d)"
alias claude="claude --dangerously-skip-permissions"
alias diff="diff --color"
alias edir="edir -r"
# alias eza="eza --icons never"
alias eza="eza --icons always"
alias gc="git clone --depth 1"
alias gron="fastgron"
alias http="xh"
alias jq="gojq"
alias l="ls -1"
alias la="ls -a"
alias ll="ls -l --classify=auto --git"
alias lla="ll -a"
alias ls="eza --group-directories-first"
alias mpv='mpv --ytdl-raw-options=cookies-from-browser=chrome'
alias path='printf "%s\n" $path'
alias rg="rg --smart-case --colors match:bg:yellow --colors match:fg:black"
alias rm="rm --verbose"
alias scrcpy="scrcpy --render-driver opengl"
alias vi="nvim"
alias yt-dlp="yt-dlp --cookies-from-browser chrome"
(( $+commands[xdg-open] )) && alias open="xdg-open"

source ~/.local/share/zsh/plugins/zsh-defer/zsh-defer.plugin.zsh

[[ $OSTYPE == darwin* ]] && source ~/.config/zsh/darwin.zsh
[[ -n "$TERMUX_VERSION" ]] && source ~/.config/zsh/termux.zsh

source ~/.config/zsh/vi.zsh
zsh-defer source ~/.config/zsh/completion.zsh
source ~/.config/zsh/prompt.zsh
# [[ $TERM == xterm-kitty ]] && zsh-defer source ~/.config/zsh/kitty.zsh
[[ -n "$TMUX" ]] && zsh-defer source ~/.config/zsh/tmux.zsh
# eval "$(dircolors -b ~/.config/dircolors)"
eval "$(direnv hook zsh)"
zsh-defer source ~/.config/zsh/autopair.zsh
zsh-defer source ~/.config/zsh/autosuggestions.zsh
zsh-defer source ~/.config/zsh/fzf.zsh
zsh-defer source ~/.config/zsh/history-search.zsh
zsh-defer source ~/.local/share/zsh/plugins/nix-shell/nix-shell.plugin.zsh

zsh-defer source ~/.local/share/zsh/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh

bindkey ' ' magic-space # history expansion
