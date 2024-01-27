{ config, lib, ... }:

{
  home-manager.users.andrei = { pkgs, config, ... }: {
    home.file.".inputrc".source =
      config.lib.file.mkOutOfStoreSymlink ./inputrc-vi;
  };
}
