{ pkgs, ... }:

rec {
  services.xserver = {
    layout = "fr";

    xkbOptions = "ctrl:nocaps";
  };

  home-manager.users.avo
    .home.keyboard = with services.xserver; {
      inherit layout;
      options = [ xkbOptions ];
    };
}
