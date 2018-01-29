{ config, pkgs, ... }:

{
  imports =
    [
      ../profiles/graphical.nix
      ../profiles/workstation.nix
    ];

  networking.localCommands = ''
    /run/current-system/sw/bin/iwconfig wlp3s0 essid wifisubmarine
  '';

  powerManagement.resumeCommands = ''
    /run/current-system/sw/bin/iwconfig wlp3s0 essid wifisubmarine
  '';

  sound.mediaKeys.enable = true;
}
