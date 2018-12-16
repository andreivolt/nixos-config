{
  services.xserver.enable = true;

  services.xserver.displayManager.auto = { enable = true; user = "avo"; };
  services.xserver.desktopManager.xterm.enable = false;

  services.xserver.displayManager.sessionCommands = ''
    setroot -t ~/lib/wallpaper.png
    xrdb -merge /etc/X11/Xresources
    redshift -O 4000
  '';

  services.xserver.layout = "fr";

  environment.etc."X11/Xresources".text = ''
    Xft.dpi: 192
  '';

  # window shadows
  services.compton = {
    enable = true;
    shadow = true; shadowOffsets = [ (-15) (-5) ]; shadowOpacity = "0.7";
    extraOptions = "shadow-radius = 10;";
  };

  services.unclutter.enable = true;
}
