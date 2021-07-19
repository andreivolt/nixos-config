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

  PROMPT="%(?.%F{green}.%F{red})%~ $ %f%K{black}%F{white}$prompt_jobs%f%k"
}
prompt_opts=(cr percent sp subst)
autoload -U add-zsh-hook
add-zsh-hook precmd prompt_precmd
