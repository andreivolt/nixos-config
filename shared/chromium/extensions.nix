{ inputs, pkgs, ... }:
{
  chromium.extensions = [
    inputs.ff2mpv.packages.${pkgs.system}.default
    inputs.dearrow.packages.${pkgs.system}.default
  ];
}
