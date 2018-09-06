{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [ (zathura.override { useMupdf = true; }) ];

  environment.etc."zathurarc".text = ''
    set incremental-search true
    set window-title-basename true
  '';
}
