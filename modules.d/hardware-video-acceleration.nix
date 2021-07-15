{ pkgs, ... }:

{
  hardware.opengl.extraPackages = [ pkgs.vaapiVdpau ];

  environment.variables.LIBVA_DRIVER_NAME = "vdpau";
}
