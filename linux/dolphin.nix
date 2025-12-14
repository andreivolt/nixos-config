{
  pkgs,
  lib,
  ...
}: {
  environment.etc."xdg/menus/applications.menu".source =
    "${pkgs.kdePackages.plasma-workspace}/etc/xdg/menus/plasma-applications.menu";

  environment.systemPackages = with pkgs;
    [
      kdePackages.dolphin
      kdePackages.kservice
      kdePackages.ffmpegthumbs
      kdePackages.kio-extras
      gnome-epub-thumbnailer
      libheif
    ]
    ++ lib.optionals (pkgs.stdenv.hostPlatform.isx86_64) [
      kdePackages.kdegraphics-thumbnailers
    ];

  home-manager.users.andrei = {
    # Dolphin configuration
    xdg.configFile."dolphinrc".text = ''
      [CompactMode]
      PreviewSize=22

      [KFileDialog Settings]
      Places Icons Auto-resize=false
      Places Icons Static Size=22

      [MainWindow]
      MenuBar=Disabled
    '';

    # Disable folder color context menu
    xdg.dataFile."kio/servicemenus/folderscolor.desktop".text = ''
      [Desktop Entry]
      Hidden=true
    '';
  };
}
