{ config, lib, ... }:

{
  home-manager.users.avo.xdg = with config.users; {
    enable = true;

    configHome = "${users.avo.home}/.config";
    dataHome   = "${users.avo.home}/.local/share";
    cacheHome  = "${users.avo.home}/.cache";

    configFile = {
      "user-dirs.dirs".text = lib.generators.toKeyValue {} {
        XDG_DOWNLOAD_DIR = "$HOME/tmp";
        XDG_DESKTOP_DIR  = "$HOME/tmp";
      };
    };
  };
}
