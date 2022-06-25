{ pkgs, ... }:

{
  users.users.avo.extraGroups = [ "video" ];

  security.wrappers.fbterm = {
    source = "${pkgs.fbterm}/bin/fbterm";
    owner = "nobody";
    group = "nogroup";
    capabilities = "cap_sys_tty_config+ep";
  };
}
