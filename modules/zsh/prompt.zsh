prompt_precmd() {
  rehash
  setopt promptsubst

  local jobs; unset jobs
  local prompt_jobs
  for a (${(k)jobstates}) {
    j=$jobstates[$a];i="${${(@s,:,)j}[2]}"
    jobs+=($a''${i//[^+-]/})
  }
  prompt_jobs=""
  [[ -n $jobs ]] && prompt_jobs="%F{242}["${(j:,:)jobs}"] "

  [[ -n $IN_NIX_SHELL ]] && nix_shell_indicator='%K{3}%F{0} nix-shell %f%k '

  PROMPT="%(?.%F{green}.%F{red})%~ $ %f%K{black}%F{white}$prompt_jobs%f%k$nix_shell_indicator"
}
prompt_opts=(cr percent sp subst)
autoload -U add-zsh-hook
add-zsh-hook precmd prompt_precmd
