{ lib, pkgs, ... }:

with lib;

{
  hardware.pulseaudio = {
    enable = true;
    package = pkgs.pulseaudioFull;
    extraConfig = mkAfter "load-module module-alsa-sink device=hw:1,9"; # output audio to HDMI
  };
}
