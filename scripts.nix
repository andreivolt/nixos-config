{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [ avo-scripts ];

  fileSystems."scripts" = {
    device = "/etc/nixos/scripts";
    fsType = "none"; options = [ "bind" ];
    mountPoint = "/home/avo/.local/bin";
  };
}
