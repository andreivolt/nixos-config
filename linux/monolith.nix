{ config, lib, pkgs, inputs, ... }:

{
  imports = [ inputs.monolith.nixosModules.default ];

  services.monolith = {
    enable = true;
    user = "andrei";
    workingDirectory = "/home/andrei/dev/monolith";
    environmentFile = config.sops.templates."monolith.env".path;
  };
}
