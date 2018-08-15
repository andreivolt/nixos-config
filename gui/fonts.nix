{ config, pkgs, ... }:

let
  myFonts = {
    proportional = builtins.getEnv "PROPORTIONAL_FONT_FAMILY";
    monospace = builtins.getEnv "MONOSPACE_FONT_FAMILY";
    fontSize = builtins.getEnv "MONOSPACE_FONT_SIZE";
    fontSizePixels = builtins.getEnv "MONOSPACE_FONT_SIZE_PIXELS";
  };

in {
  fonts = {
    fontconfig = {
      ultimate.enable = false;
      defaultFonts = with myFonts; {
        monospace = [ monospace ];
        sansSerif = [ proportional ];
      };
    };
    enableCoreFonts = true;
    fonts = with pkgs; [
      emacs-all-the-icons-fonts
      google-fonts
      hack-font
      iosevka-custom
      ubuntu_font_family
      vistafonts
    ];
  };
}
