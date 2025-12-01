{pkgs, ...}: {
  home-manager.users.andrei = {
    # Provide Qt configuration tools for user customization
    home.packages = with pkgs; [
      libsForQt5.qt5ct
      kdePackages.qt6ct
      # Dark theme packages available for user selection
      adwaita-qt
      adwaita-qt6
      libsForQt5.qtstyleplugin-kvantum
      kdePackages.qtstyleplugin-kvantum
    ];

    # Use qt5ct/qt6ct for hybrid approach (Nix provides packages, user configures via GUI)
    qt = {
      enable = true;
      platformTheme.name = "qtct";
    };
  };
}
