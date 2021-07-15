{ config, lib, ... }:

{
  home-manager.users.avo = { pkgs, config, ... }: {
    xdg.configFile."alacritty/alacritty.yml".source =
      config.lib.file.mkOutOfStoreSymlink ./alacritty.yml;
  };
}
