{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [ (zathura.override { useMupdf = true; }) ];

  home-manager.users.avo
    .xdg.configFile."zathura/zathurarc".text = ''
      set incremental-search true
      set window-title-basename true
    '';
}
