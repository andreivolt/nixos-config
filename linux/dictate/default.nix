{ config, inputs, ... }:

{
  imports = [
    inputs.dictate.nixosModules.default
    ./sops.nix
  ];

  services.dictate = {
    enable = true;
    user = "andrei";
    environmentFile = config.sops.templates."dictate.env".path;
  };
}
