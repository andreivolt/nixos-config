
{
  services.xserver.enable = true;

  services.xserver.displayManager.auto = { enable = true; user = "avo"; };

  services.xserver.displayManager.sessionCommands = "xrdb -merge /etc/X11/Xresources; redshift -O 4000";

  services.xserver.desktopManager.xterm.enable = false;

  # services.xserver.videoDrivers = [ "nvidia" ];

  services.xserver.layout = "fr"; # keyboard layout
}
