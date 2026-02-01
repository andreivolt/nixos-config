{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    inputs.monolith.nixosModules.default
    ./sops.nix
  ];

  services.monolith = {
    enable = true;
    user = "andrei";
    workingDirectory = "/home/andrei/dev/monolith";
    environmentFile = config.sops.templates."monolith.env".path;
  };

  chromium.unpackedExtensions = [
    "/home/andrei/dev/monolith/apps/chrome-extension/.output/chrome-mv3"
  ];
}
