{
  home-manager.users.avo = { pkgs, ...}: {
    home.packages = [
      libsForQt5.qtstyleplugin-kvantum # Qt theme engine
    ];

    programs.qt5ct.enable = true;
  };
}
