{ config, pkgs, ... }:

{
  services.ipfs.enable = true;

  users.users.avo.extraGroups = [ "ipfs" ];

  environment.variables."IPFS_PATH" = "/var/lib/ipfs/.ipfs";
}
