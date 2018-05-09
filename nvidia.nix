{ config, pkgs, ... }:

{
  hardware.opengl.extraPackages = with pkgs; [ vaapiVdpau ];

  environment.variables.LIBVA_DRIVER_NAME = "vdpau";

  services.xserver.videoDrivers = [ "nvidia" ];

  home-manager.users.avo
    .home.sessionVariables.__GL_SHADER_DISK_CACHE_PATH = with config.home-manager.users.avo;
      "${xdg.cacheHome}/nv";
}
