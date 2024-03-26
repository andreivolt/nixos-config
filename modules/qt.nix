{
  home-manager.users.andrei = { pkgs, ... }: {
    home.packages = with pkgs; [
      libsForQt5.qtstyleplugin-kvantum # Qt theme engine
    ];

  };

  qt.platformTheme = "qt5ct";
}
