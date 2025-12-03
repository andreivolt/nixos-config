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
}
