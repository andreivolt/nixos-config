{ pkgs, config, ... }:

{
  home-manager.users.andrei = { pkgs, config, ... }: {
    home.packages = with pkgs; [ boot ];
    home.file.".boot/profile.boot".source = config.lib.file.mkOutOfStoreSymlink ./profile.boot;
  };
}
