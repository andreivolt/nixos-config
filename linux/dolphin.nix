{
  pkgs,
  lib,
  ...
}: let
  # Remove unwanted context menu plugins from kio-extras
  kio-extras-clean = pkgs.kdePackages.kio-extras.overrideAttrs (old: {
    postInstall = (old.postInstall or "") + ''
      rm -f $out/lib/qt-6/plugins/kf6/kfileitemaction/kactivitymanagerd_fileitem_linking_plugin.so
      rm -f $out/lib/qt-6/plugins/kf6/kfileitemaction/forgetfileitemaction.so
    '';
  });

  # Remove "Set Folder Icon" from dolphin
  dolphin-clean = pkgs.kdePackages.dolphin.overrideAttrs (old: {
    postInstall = (old.postInstall or "") + ''
      rm -f $out/lib/qt-6/plugins/kf6/kfileitemaction/setfoldericonitemaction.so
    '';
  });
in {
  environment.etc."xdg/menus/applications.menu".source =
    "${pkgs.kdePackages.plasma-workspace}/etc/xdg/menus/plasma-applications.menu";

  environment.systemPackages = with pkgs;
    [
      dolphin-clean
      kdePackages.kservice
      kdePackages.ffmpegthumbs
      kio-extras-clean
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
