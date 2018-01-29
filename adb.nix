{ programs, users, ... }:

{
  programs.adb.enable = true;

  users.users.avo.extraGroups = [ "adbusers" ];
}
