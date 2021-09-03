{
  home-manager.users.avo.programs.zsh.initExtra = ''
    fpath=( ${./zfunc} "''${fpath[@]}" )
    autoload -U ${./zfunc}/*(.:t)
  '';
}
