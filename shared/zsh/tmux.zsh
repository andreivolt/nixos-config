preexec() {
  local cmd=${1%% *}
  printf "\033k$cmd\033\\"
}

precmd() {
  printf "\033kzsh\033\\"
}

preexec_functions+=(preexec)
precmd_functions+=(precmd)
