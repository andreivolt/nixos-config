{ pkgs, ... }:

{
  imports = [
    ./input-fonts.nix
  ];

  # TODO
  # fonts.fontconfig.defaultFonts = {
  #   monospace = [ "Source Code Pro" ];
  #   sansSerif = [ "Source Sans Pro" ];
  # };
  fonts.fonts = with pkgs; [
    cascadia-code
    # corefonts # TODO error

    # joypixels # emoji
    # nixpkgs.config.joypixels.acceptLicense = true;

    d2coding
    google-fonts
    hack-font
    ia-writer-duospace
    # jetbrains-mono
    # material-icons
    nerdfonts
    # overpass
    # powerline-fonts
    proggyfonts
    ubuntu_font_family
    vistafonts
    sudo-font

    atkinson-hyperlegible

    # hasklig
    # emacs-all-the-icons-fonts

    # font-awesome-ttf

    # (iosevka.override {
    #   set = "custom";
    #   privateBuildPlan = {
    #     family = "Iosevka Custom";
    #     spacing = "normal";
    #     serifs = "sans";
    #     variants = {
    #       design.capital-j = "serifless";
    #       italic.i = "tailed";
    #     };
    #   };
    #   # design = [
    #   #   "termlig"
    #   #   "v-asterisk-low"
    #   #   "v-at-short"
    #   #   "v-i-zshaped"
    #   #   "v-tilde-low"
    #   #   "v-underscore-low"
    #   #   "v-zero-dotted"
    #   #   "v-zshaped-l"
    #   # ];
    # })
  ];
}
