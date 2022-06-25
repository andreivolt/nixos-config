{
  home-manager.users.avo = { pkgs, ... }: {
    home.packages = with pkgs; [ bat ];

    home.sessionVariables.BAT_STYLE = "plain";
  };
}
