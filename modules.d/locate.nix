{ pkgs, ... }:

{
  services.locate = {
    enable = true;
    locate = pkgs.mlocate;
    localuser = null;
  };

  users.users.avo.extraGroups = [ "mlocate" ];
}
