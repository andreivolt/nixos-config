{ config, lib, ... }:

{
  home-manager.users.avo = { pkgs, config, ... }: {
    home.file.".inputrc".source =
      config.lib.file.mkOutOfStoreSymlink ./inputrc-vi;
  };
}
