{ pkgs, ... }:

rec {
  services.xserver = {
    layout = "fr";

    xkbOptions = "ctrl:nocaps";

    libinput = {
      enable = true;
      naturalScrolling = true;
      accelSpeed = "0.4";
    };
  };

  environment.systemPackages = with pkgs; [ libinput-gestures ];

  home-manager.users.avo
    .home.keyboard = with services.xserver; {
      inherit layout;
      options = [ xkbOptions ];
    };
}
