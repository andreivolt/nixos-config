[[ -n $__ZPROFILE_SOURCED ]] && return
export __ZPROFILE_SOURCED=1

export XDG_CACHE_HOME=~/.cache
export XDG_CONFIG_HOME=~/.config
export XDG_DATA_HOME=~/.local
export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-$TMPDIR}
export XDG_STATE_HOME=~/.local/state

(( ${+commands[google-chrome-stable]} )) && BROWSER=google-chrome-stable
[[ -f ~/.local/ca-certificates/combined-ca-bundle.pem ]] && export CURL_CA_BUNDLE=~/.local/ca-certificates/combined-ca-bundle.pem
export DELTA_PAGER='less -R'
export DENO_NO_UPDATE_CHECK=1
export EDITOR=nvim
export TERMINAL=kitty
export LESS='--RAW-CONTROL-CHARS --LONG-PROMPT --ignore-case --no-init --quit-if-one-screen'
export MANPAGER='nvim +Man!' MANWIDTH=100
export PAGER=nvimpager
export PYTHONDONTWRITEBYTECODE=1 PYTHONWARNINGS=ignore
export UV_TOOL_BIN_DIR=~/.local/bin

typeset -U path

path+=(
  ~/go/bin(N)
  ~/.npm/bin(N)
  ~/.local/gem/ruby/*/bin(N)
  ~/.cargo/bin(N)
  ~/.cache/.bun/bin(N)
  ~/.local/bin(N)
  ~/bin(N)
)

source ~/.config/env &>/dev/null
export PKG_CONFIG_PATH="$HOME/.nix-profile/lib/pkgconfig:/run/current-system/sw/lib/pkgconfig:${PKG_CONFIG_PATH:-}"
