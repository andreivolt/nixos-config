{
  home-manager.users.andrei = { pkgs, ... }: {
    home.packages = with pkgs; [ bat ];

    home.sessionVariables.BAT_STYLE = "plain";
  };
}
