{
  services.xserver = enable = true;

  services.xserver.videoDrivers = [ "intel" ];
  services.xserver.useGlamor = true;

  services.xserver.desktopManager.plasma5.enable = true;

  services.xserver.displayManager.sddm.enable = true;
  services.xserver.displayManager.sddm.settings.Wayland.SessionDir = "${pkgs.plasma5Packages.plasma-workspace}/share/wayland-sessions";
}
