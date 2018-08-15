prompt_precmd() {
  rehash

  local jobs
  local prompt_jobs
  unset jobs
  for a (${(k)jobstates}) {
    j=$jobstates[$a];i='${${(@s,:,)j}[2]}'
    jobs+=($a${i//[^+-]/})
  }

  prompt_jobs=""
  [[ -n $jobs ]] && prompt_jobs="%F{yellow}["${(j:,:)jobs}"]%f "

  setopt promptsubst
  PROMPT="%K{white} $prompt_jobs%F{black}%d $ %f%k "
}

prompt_opts=(cr percent sp subst)

add-zsh-hook precmd prompt_precmd
