{pkgs, ...}: {
  home-manager.users.andrei.home.packages = [pkgs.libsForQt5.qtstyleplugin-kvantum];

  qt.platformTheme = "qt5ct";
}
