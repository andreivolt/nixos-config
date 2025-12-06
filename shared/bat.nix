{
  home-manager.sharedModules = [
    {
      programs.bat = {
        enable = true;
        config = {
          style = "header-filename,grid";
          theme = "base16";
          wrap = "character";
        };
      };
      programs.zsh.initContent = ''
        cat() {
          if [[ -t 1 ]]; then
            bat "$@"
          else
            command cat "$@"
          fi
        }
      '';
    }
  ];
}
