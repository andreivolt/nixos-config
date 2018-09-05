{ pkgs, ... }:

rec {
  services.xserver = {
    layout = "fr";

    xkbOptions = "ctrl:nocaps";
  };

  i18n.consoleUseXkbConfig = true;
}
