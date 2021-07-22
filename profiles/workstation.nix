{
  hardware = {
    bluetooth.enable = true;
    opengl.enable = true;
  };

  networking = {
    hostName = builtins.getEnv "HOSTNAME";
    enableIPv6 = false;
    networkmanager.enable = true;
  };

  security.sudo.wheelNeedsPassword = false;

  services.devmon.enable = true; # automount removable devices

  environment.etc."mailcap".text = "*/*; xdg-open '%s'";
}
