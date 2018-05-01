rec {
  services.xserver = {
    layout = "fr";

    xkbOptions = "ctrl:nocaps";

    libinput = {
      enable = true;
      naturalScrolling = true;
      accelSpeed = "0.4";
    };

    multitouch = {
      enable = true;
      invertScroll = true;
    }
  };

  home-manager.users.avo.home = {
    keyboard = {
      layout = services.xserver.layout;
      options = [ services.xserver.xkbOptions ];
    };
  };
}
