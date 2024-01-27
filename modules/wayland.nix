{
  home-manager.users.andrei = { pkgs, ... }: {
    home.packages = with pkgs; [
      wtype # typing automation
    ];

    home.sessionVariables.NIXOS_OZONE_WL = 1;
  };
}
