{ inputs, pkgs, ... }:
{
  chromium.extensions = [
    inputs.ff2mpv.packages.${pkgs.stdenv.hostPlatform.system}.default
    inputs.dearrow.packages.${pkgs.stdenv.hostPlatform.system}.default
    inputs.bypass-paywalls.packages.${pkgs.stdenv.hostPlatform.system}.default
    inputs.sci-hub-now.packages.${pkgs.stdenv.hostPlatform.system}.default
    inputs.redirect-domains.packages.${pkgs.stdenv.hostPlatform.system}.default
    inputs.refined-hacker-news.packages.${pkgs.stdenv.hostPlatform.system}.default
    inputs.userscripts.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
