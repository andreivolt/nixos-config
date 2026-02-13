{ inputs, pkgs, ... }:
{
  chromium.extensions = [
    inputs.ff2mpv.packages.${pkgs.system}.default
    inputs.dearrow.packages.${pkgs.system}.default
    inputs.bypass-paywalls.packages.${pkgs.system}.default
    inputs.sci-hub-now.packages.${pkgs.system}.default
  ];
}
