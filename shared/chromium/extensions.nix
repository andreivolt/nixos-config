{ inputs, pkgs, ... }:
{
  chromium.extensions = [
    { package = inputs.ff2mpv.packages.${pkgs.stdenv.hostPlatform.system}.default; key = ./keys/ff2mpv.pem; }
    { package = inputs.dearrow.packages.${pkgs.stdenv.hostPlatform.system}.default; key = ./keys/dearrow.pem; }
    { package = inputs.bypass-paywalls.packages.${pkgs.stdenv.hostPlatform.system}.default; key = ./keys/bypass-paywalls.pem; }
    { package = inputs.sci-hub-now.packages.${pkgs.stdenv.hostPlatform.system}.default; key = ./keys/sci-hub-now.pem; }
    { package = inputs.redirect-domains.packages.${pkgs.stdenv.hostPlatform.system}.default; key = ./keys/redirect-domains.pem; }
    { package = inputs.refined-hacker-news.packages.${pkgs.stdenv.hostPlatform.system}.default; key = ./keys/refined-hacker-news.pem; }
  ];
}
