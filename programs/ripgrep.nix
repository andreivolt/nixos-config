{ config, pkgs, ... }:

let
  ripgrep-config = pkgs.writeText "ripgreprc" ''
    --smart-case
    --colors=match:fg:yellow
    --colors=match:style:underline
  '';

in {
  environment.systemPackages = with pkgs; [ ripgrep ];

  environment.variables.RIPGREP_CONFIG_PATH = "${ripgrep-config}";
}
