{ pkgs, ... }:

{
  hardware.opengl.extraPackages = with pkgs; [ vaapiVdpau ];

  environment.variables.LIBVA_DRIVER_NAME = "vdpau";

  services.xserver.videoDrivers = [ "nvidia" ];
}
