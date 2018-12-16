{ lib, pkgs, ... }:

with lib;

let
  hardware-video-acceleration = {
    hardware.opengl.extraPackages = [ pkgs.vaapiVdpau ];
    environment.variables.LIBVA_DRIVER_NAME = "vdpau";
  };

in
hardware-video-acceleration // {
  services.xserver.videoDrivers = [ "nvidia" ];

  services.xserver.screenSection = mkAfter ''
    Option "metamodes" "DP-0: nvidia-auto-select +0+0 { ForceCompositionPipeline=On }, DP-2: nvidia-auto-select +0+0 { ForceCompositionPipeline=On, SameAs=DP-0 }"
    Option "AllowIndirectGLXProtocol" "off"
    Option "TripleBuffer" "on"
  '';
}
