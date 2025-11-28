{ config, lib, pkgs, ... }:

{
  # Roon Server - music streaming server
  services.roon-server = {
    enable = true;
    openFirewall = true;
  };

  # Allow unfree package
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      "roon-server"
    ];
}
