{ config, pkgs, ... }:

let
  myFonts = {
    proportional = builtins.getEnv "PROPORTIONAL_FONT_FAMILY";
    monospace = builtins.getEnv "MONOSPACE_FONT_FAMILY";
    defaultSize = 10;
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
      font-awesome-ttf
      google-fonts
      hack-font
      hasklig
      iosevka-custom
      material-icons
      nerdfonts
      overpass
      powerline-fonts
      terminus_font
      ubuntu_font_family
      vistafonts
    ];
  };

  # home-manager.users.avo
  #   .xresources.properties = {
  #     "*.font"        = "xft:${myFonts.monospace}:size=${toString myFonts.defaultSize}";
  #   };
}
