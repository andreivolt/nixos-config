{ config, lib, ... }:

{
  programs.adb.enable = true;

  users.users.avo.extraGroups = [ "adbusers" ];

  home-manager.users.avo
    .home.sessionVariables.ANDROID_SDK_HOME = with config.home-manager.users.avo;
      "${xdg.configHome}/android";

  home-manager.users.avo
    .home.file = builtins.listToAttrs (map (name: lib.nameValuePair (".android/" + name)
                                                                    { text = builtins.readFile (./private/adb-keys + ("/" + name)); })
                                           (lib.attrNames (builtins.readDir ./private/adb-keys)));
}
