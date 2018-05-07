{ config, lib, ... }:

{
  home-manager.users.avo.xdg = {
    enable = true;

    configHome = "${config.users.users.avo.home}/.config";
    dataHome   = "${config.users.users.avo.home}/.local/share";
    cacheHome  = "${config.users.users.avo.home}/.cache";

    configFile = {
      "user-dirs.dirs".text = lib.generators.toKeyValue {} {
        XDG_DOWNLOAD_DIR = "$HOME/tmp";
        XDG_DESKTOP_DIR  = "$HOME/tmp";
      };
    };
  };
}
