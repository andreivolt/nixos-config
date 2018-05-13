{ pkgs, ... }:

{
  hardware.pulseaudio = { enable = true; package = pkgs.pulseaudioFull; };

  environment.systemPackages = with pkgs; [
    alsaPlugins
    alsaUtils
    pamixer
    ponymix
  ];
}
