{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [ mpv ];

  environment.etc."mpv/mpv.conf".text = lib.generators.toKeyValue {} {
    hwdec = "vdpau";
    profile = "opengl-hq";
    audio-display = "no";
  };
}
