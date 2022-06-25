{
  home-manager.users.avo.home.sessionVariables
    .LESS = ''
      --RAW-CONTROL-CHARS \
      --LONG-PROMPT \
      --ignore-case \
      --no-init \
      --quit-if-one-screen\
    '';

  environment.variables.LESS = "XFRiM";
  # X: disable setting termcap
  # F: quit if output fits terminal
  # R: interpret color escapes
  # i: ignore case
  # M: prompt verbosely
}
