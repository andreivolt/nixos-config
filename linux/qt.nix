{pkgs, ...}: {
  home-manager.users.andrei = {
    home.packages = with pkgs; [
      adwaita-qt
      adwaita-qt6
    ];

    # Use gnome platform theme - Qt apps follow gsettings color-scheme automatically
    qt = {
      enable = true;
      platformTheme.name = "gnome";
      style.name = "adwaita";
    };
  };
}
