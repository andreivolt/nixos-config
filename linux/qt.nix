{pkgs, ...}:
let
  ui = import ../shared/ui.nix;
  qtFont = "${ui.fontFamily},${toString ui.fontSizePt},-1,5,50,0,0,0,0,0";
in {
  home-manager.users.andrei = {
    home.packages = with pkgs; [
      adwaita-qt
      adwaita-qt6
      qt6Packages.qt6ct
      libsForQt5.qt5ct
    ];

    # Use xdgdesktopportal for system dark mode detection (built into Qt6)
    qt = {
      enable = true;
      platformTheme.name = "xdgdesktopportal";
      style.name = "adwaita-dark";
    };

    # qt5ct configuration
    xdg.configFile."qt5ct/qt5ct.conf".text = ''
      [Appearance]
      style=Adwaita-Dark
      standard_dialogs=default

      [Fonts]
      fixed="${qtFont}"
      general="${qtFont}"
    '';

    # qt6ct configuration
    xdg.configFile."qt6ct/qt6ct.conf".text = ''
      [Appearance]
      style=Adwaita-Dark
      standard_dialogs=default

      [Fonts]
      fixed="${qtFont}"
      general="${qtFont}"
    '';

    # KDE/Qt font settings for apps like Dolphin
    xdg.configFile."kdeglobals".text = ''
      [General]
      font=${qtFont}
      TerminalApplication=kitty --single-instance
      TerminalService=kitty.desktop

      [WM]
      activeFont=${qtFont}
    '';
  };
}
