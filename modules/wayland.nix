{
  environment.variables.QT_QPA_PLATFORM = "wayland";
  environment.variables.QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
  home-manager.users.avo = { pkgs, ... }: {
    home.packages = with pkgs; [
      wtype # typing automation
    ];
  };
}
