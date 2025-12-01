{pkgs, ...}: {
  home-manager.users.andrei = {
    home.packages = with pkgs; [
      adwaita-qt
      adwaita-qt6
    ];

    # Use adwaita platform theme - Qt apps follow gsettings color-scheme automatically
    # Don't set style.name - let the platform theme handle dark/light switching
    qt = {
      enable = true;
      platformTheme.name = "adwaita";
    };
  };
}
