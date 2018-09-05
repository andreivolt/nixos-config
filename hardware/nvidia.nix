{ config, pkgs, ... }:

{
  hardware.opengl.extraPackages = with pkgs; [ vaapiVdpau ];

  environment.variables.LIBVA_DRIVER_NAME = "vdpau";

  services.xserver.videoDrivers = [ "nvidia" ];

  environment.variables.__GL_SHADER_DISK_CACHE_PATH = "~/.cache/nv";
}
