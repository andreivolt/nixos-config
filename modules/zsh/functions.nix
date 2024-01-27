{
  home-manager.users.andrei.programs.zsh.initExtra = ''
    fpath=( ${./zfunc} "''${fpath[@]}" )
    autoload -U ${./zfunc}/*(.:t)
  '';
}
