{ config, ... }:

{
  programs.adb.enable = true;

  users.users.avo.extraGroups = [ "adbusers" ];

  home-manager.users.avo.home.sessionVariables
    .ANDROID_SDK_HOME = "${config.home-manager.users.avo.xdg.configHome}/android";
}
