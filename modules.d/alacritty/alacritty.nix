{ config, lib, ... }:

{
  home-manager.users.avo = { pkgs, config, ... }: {
    home.packages = with pkgs; [ alacritty ];

    xdg.configFile."alacritty/alacritty.yml".source =
      config.lib.file.mkOutOfStoreSymlink ./alacritty.yml;
  };
}
