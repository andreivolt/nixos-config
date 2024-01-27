{ pkgs, ... }:

{
  imports = [
    ./input-fonts.nix
  ];

  # nixpkgs.config.joypixels.acceptLicense = true;
  # joypixels # emoji

  # TODO
  # fonts.fontconfig.defaultFonts = {
  #   monospace = [ "Source Code Pro" ];
  #   sansSerif = [ "Source Sans Pro" ];
  # };
  fonts.packages = with pkgs; [
    # corefonts # TODO error
    # emacs-all-the-icons-fonts
    # font-awesome-ttf
    # hasklig
    # jetbrains-mono
    # material-icons
    # overpass
    # powerline-fonts
    atkinson-hyperlegible
    cascadia-code
    d2coding
    google-fonts
    hack-font
    ia-writer-duospace
    nerdfonts
    # (nerdfonts.override {
    #   fonts = [
    #     "FiraCode"
    #     "Inconsolata"
    #     "Iosevka"
    #     "JetBrainsMono"
    #     "Mononoki"
    #     "RobotoMono"
    #     "SourceCodePro"
    #   ];
    # })
    noto-fonts-emoji
    proggyfonts
    sudo-font
    twitter-color-emoji
    ubuntu_font_family
    vistafonts
    whatsapp-emoji-font
  ];

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
}
