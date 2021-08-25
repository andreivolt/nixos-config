{
  home-manager.users.avo = { pkgs, ... }: {
    home.file.".zlogin".text = ''
      # if not running interactively, don't do anything
      [[ $- != *i* ]] && return

      if [[ "$(tty)" == "/dev/tty1" ]]; then
        ${pkgs.startsway}/bin/startsway;
      fi
    '';
  };
}
