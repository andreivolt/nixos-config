{ pkgs, ... }:

{
  fonts = {
    fontconfig.ultimate = { enable = true; preset = "windowsxp"; };
    fontconfig.defaultFonts = {
      monospace = [ "Roboto Mono" ];
      sansSerif = [ "Proxima Nova" ];
    };
    enableCoreFonts= true;
    fonts = with pkgs; [
      google-fonts
      hack-font
      vistafonts
    ];
  };
}
