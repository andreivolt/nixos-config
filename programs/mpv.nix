{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [ mpv ];

  home-manager.users.avo
    .xdg.configFile."mpv/mpv.conf".text = lib.generators.toKeyValue {} {
      ao = "pulse";
      hwdec = "vdpau";
      profile = "opengl-hq";
      audio-display = "no";
    };
}
