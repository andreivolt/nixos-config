{
  home-manager.users.avo = { pkgs, ...}: {
    home.packages = with pkgs; [
      libsForQt5.qtstyleplugin-kvantum # Qt theme engine
    ];

  };

  qt5.platformTheme = "qt5ct";
}
