zsh-defer source ~/.orbstack/shell/init.zsh 2>/dev/null

path=(
  /run/current-system/sw/bin(N)
  ~/.nix-profile/bin(N)
  /nix/var/nix/profiles/default/bin(N)
  ${path:#/run/current-system/sw/bin}
)
