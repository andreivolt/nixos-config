{
  pkgs,
  lib,
  ...
}: lib.mkIf pkgs.stdenv.isLinux {
  services.tor.enable = true;
}
