{ config, inputs, lib, ... }:

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

  # Wait for tray host (ironbar) before starting
  systemd.user.services.dictate = {
    after = [ "tray.target" ];
    requires = [ "tray.target" ];
  };
}
