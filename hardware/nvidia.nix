{ config, pkgs, ... }:

if builtins.getEnv "HOST" == "watts" then {
  hardware.opengl.extraPackages = with pkgs; [ vaapiVdpau ];

  environment.variables.LIBVA_DRIVER_NAME = "vdpau";

  services.xserver.videoDrivers = [ "nvidia" ];

  environment.variables.__GL_SHADER_DISK_CACHE_PATH = with config.home-manager.users.avo;
    "${xdg.cacheHome}/nv";
} else {}
