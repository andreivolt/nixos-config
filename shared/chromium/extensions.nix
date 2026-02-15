{ inputs, pkgs, ... }:
{
  chromium.extensions = [
    { package = inputs.ff2mpv.packages.${pkgs.system}.default; key = ./keys/ff2mpv.pem; }
    { package = inputs.dearrow.packages.${pkgs.system}.default; key = ./keys/dearrow.pem; }
    { package = inputs.bypass-paywalls.packages.${pkgs.system}.default; key = ./keys/bypass-paywalls.pem; }
    { package = inputs.sci-hub-now.packages.${pkgs.system}.default; key = ./keys/sci-hub-now.pem; }
  ];
}
