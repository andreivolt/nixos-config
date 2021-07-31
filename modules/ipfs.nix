{ pkgs, ... }:

{
  services.ipfs = {
    enable = true;
    # enableGC = true;
    # emptyRepo = true;
    # startWhenNeeded = true;
  };

  users.users.avo.extraGroups = [ "ipfs" ];

  # home-manager.users.avo
  #   .home.sessionVariables.IPFS_PATH = "/var/lib/ipfs/.ipfs";
}
