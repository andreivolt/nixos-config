export SHELL_SESSIONS_DISABLE=1

export HOMEBREW_CELLAR=/opt/homebrew/Cellar
export HOMEBREW_PREFIX=/opt/homebrew
export HOMEBREW_REPOSITORY=/opt/homebrew
export INFOPATH=/opt/homebrew/share/info${INFOPATH:+:$INFOPATH}
export MANPATH=/opt/homebrew/share/man${MANPATH:+:$MANPATH}:
export LIBRARY_PATH=/opt/homebrew/opt/libiconv/lib${LIBRARY_PATH:+:$LIBRARY_PATH}
path=(/opt/homebrew/bin /opt/homebrew/sbin $path)

zsh-defer source ~/.orbstack/shell/init.zsh 2>/dev/null

path=(
  /run/current-system/sw/bin(N)
  ~/.nix-profile/bin(N)
  /nix/var/nix/profiles/default/bin(N)
  ${path:#/run/current-system/sw/bin}
)
