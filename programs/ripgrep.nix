{ config, pkgs, ... }:

let
  ripgrep-config = pkgs.writeText "ripgreprc" ''
    --smart-case
    --colors=match:bg:yellow
    --colors=match:fg:black
  '';

in {
  environment.systemPackages = with pkgs; [ ripgrep ];

  environment.variables.RIPGREP_CONFIG_PATH = "${ripgrep-config}";
}
