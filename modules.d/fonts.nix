{ pkgs, ... }:

{
  fonts.fontconfig.defaultFonts = {
    monospace = [ "Source Code Pro" ];
    sansSerif = [ "Source Sans Pro" ];
  };
  fonts.fonts = with pkgs; [
    corefonts
    google-fonts
    nerdfonts
    input-fonts
  ];
}
